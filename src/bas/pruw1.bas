/'* \file pruw1.bas
\brief The function bodies for the PruW1 class, tools for decoding.

This file contains the function bodies for the PruW1 class and some
functions to decode the temperature from the received data.

\since 0.0
'/

#INCLUDE ONCE "w1_prucode.bi" ' PRU firmware
#INCLUDE ONCE "w1_prucode.hp" ' PRU syncronization
#INCLUDE ONCE "pruw1.bi" ' FB declarations

#IFNDEF __PRUW1_DEBUG__
 #MACRO PRUCALL(_C_,_V_,_T_)
  WHILE DRam[0] : SLEEP 1 : WEND
  _V_
  DRam[0] = _C_
  WHILE DRam[0] : SLEEP 1 : WEND
 #ENDMACRO
#ELSE
 #MACRO PRUCALL(_C_,_V_,_T_)
  WHILE DRam[0] : SLEEP 1 : ?"."; : WEND
  _V_
  DRam[0] = _C_
  ?!"\n";_T_; " command=&h"; HEX(DRam[0], 4); " ";
  WHILE DRam[0] : SLEEP 1 : ?"."; : WEND
  prot()
 #ENDMACRO
#ENDIF

/'* \brief The constructor configuring the pin, loading and starting the PRU code.
\param P A pointer to the libpruio instance (for pinmuxing).
\param B The header pin to use as W1 bus data line.

The constructor is designed to

- allocate and initialize memory for the class variables,
- check the header pin configuration (and, if not matching, try to adapt it - root privileges),
- evaluate the free PRU (not used by libpruio)
- load the firmware and start it

In case of success the variable PruW1::Errr is 0 (zero) and you can
start to communicate on the bus. Otherwise the variable contains an
error message. In that case call the destructor (and do not start any
communication).

\since 0.0
'/
CONSTRUCTOR PruW1(BYVAL P AS PruIo PTR, BYVAL B AS Uint8)
  WITH *P
    IF .Gpio->config(B, PRUIO_GPIO_IN) THEN _
             Errr = @"pin configuration not matching" : EXIT CONSTRUCTOR

    VAR r = .BallGpio(B) _ ' resulting GPIO (index and bit number)
      , i = r SHR 5 _      ' index of GPIO
      , n = r AND 31       ' number of bit
    Mask = 1 SHL n
    Raw = @.Gpio->Raw(i)->Mix
    IF .PruNo then
      PruNo = 0
      PruIRam = PRUSS0_PRU0_IRAM
      PruDRam = PRUSS0_PRU0_DATARAM
    ELSE
      PruNo = 1
      PruIRam = PRUSS0_PRU1_IRAM
      PruDRam = PRUSS0_PRU1_DATARAM
    END IF

    prussdrv_map_prumem(PruDRam, CAST(ANY PTR, @DRam))

    prussdrv_pru_disable(PruNo) '        disable PRU (if running before)
    DRam[0] = 0
    DRam[1] = .Gpio->Conf(i)->DeAd + &h100 ' device adress
    DRam[2] = Mask                         ' the mask to related bit

    VAR l = (UBOUND(Pru_W1) + 1) * SIZEOF(Pru_W1(0))
    IF 0 >= prussdrv_pru_write_memory(PRUSS0_PRU0_IRAM, 0, @Pru_W1(0), l) THEN _
                Errr = @"failed loading PRU firmware" : EXIT CONSTRUCTOR
    prussdrv_pruintc_init(@PRUSS_INTC_INITDATA) ' interrupts initialization
    prussdrv_pru_enable(PruNo)
  END WITH
END CONSTRUCTOR


/'* \brief The destructor stopping PRU, freeing memory.

The destructor stops the PRU by disabling it. Then it frees the memory.

\since 0.0
'/
DESTRUCTOR PruW1()
  prussdrv_pru_disable(PruNo) ' disable PRU
END DESTRUCTOR


/'* \brief Function to scan the bus for all devices.
\param SearchType The search type (defaults to &hF0).
\returns An error message or `0` (zero) on success.

This function scans the bus and list the IDs of the found devices (if
any) in the array Slots. By default it uses the default search ROM
command (`&hF0`).

Find the number of devices by evaluating the upper bound of array Slots.

\note Usually the bus gets scanned once in the init process of an
      application. When you intend to use dynamic sensor connections
      (plug them in and off), then you have to periodically re-scan the
      bus. In that case clear the Slots array before each scan, in
      order to avoid double entries.

\since 0.0
'/
function PruW1.scanBus(BYVAL SearchType AS UInt8 = &hF0) as zstring ptr
  VAR max_slave = 64 _
          , cnt = 1 _
     , desc_bit = 64 _
   , search_bit = 0 _
  , last_device = 0 _
    , last_zero = -1 _
          , ret = 0 _
           , rn = 0uLL _
      , last_rn = rn
  WHILE 0 = last_device ANDALSO cnt < max_slave
    last_rn = rn
    rn = 0
    IF resetBus() THEN                Errr = @"no devices" : return Errr
    sendByte(SearchType)
    FOR i AS INTEGER = 0 TO 63
      SELECT CASE i
      CASE      desc_bit : search_bit = 1 ' took the 0 path last_device time, so take the 1 path
      CASE IS > desc_bit : search_bit = 0 ' take the 0 path on the next branch
      CASE ELSE          : search_bit = (last_rn SHR i) AND &b1
      END SELECT

       PRUCALL(CMD_TRIP + search_bit SHL 8,,"tripple:")
       ret = DRam[4] AND &b111

       SELECT CASE AS CONST ret
       CASE 0 : last_zero = i
       CASE 3 : CONTINUE WHILE ' should never happen (error -> next device)
       END SELECT
       rn OR= CULNGINT(ret) SHR 2 SHL i
    NEXT
    IF desc_bit = last_zero ORELSE last_zero < 0 THEN last_device = 1
    desc_bit = last_zero
    VAR u = UBOUND(Slots) + 1
    REDIM PRESERVE Slots(u)
    Slots(u) = rn
    cnt += 1
  WEND :                                                     return 0
END function


/'* \brief Send a byte (eight bits) to the bus.
\param V The value to send.

This procedure sends a byte to the bus. It's usually used to issue a
ROM command.

\since 0.0
'/
SUB PruW1.sendByte(BYVAL V AS UInt8)
  PRUCALL(CMD_SEND + 1 SHL 8,DRam[4] = V,"sendByte: " & HEX(V, 2) & " (&b" & BIN(V, 8) & ")")
END SUB


/'* \brief Send a ROM id to the bus (to select a device).
\param V The ROM id (8 btes) to send.

This procedure sends a ROM ID to the bus. It's usually used to adress a
single device, ie. to read its scratchpad.

\since 0.0
'/
SUB PruW1.sendRom(BYVAL V AS ULONGINT)
  PRUCALL(CMD_SEND + 8 SHL 8,*CAST(ULONGINT PTR, @DRam[4]) = V,"sendRom: " & HEX(PEEK(ULONGINT, @DRam[4]), 16))
END SUB


/'* \brief Receive a block of data (usually 9 bytes).
\param N The number of bytes to read (maximum 240).
\returns The number of bytes read.

This function triggers the bus to receive a block of bytes. Parameter
`N` specifies the number of bytes to read. The return value is the
number of bytes read. The data bytes are in the PRU DRAM, starting at
offset `&h10`.

\since 0.0
'/
FUNCTION PruW1.recvBlock(BYVAL N AS UInt8) AS UInt8
  IF N > 240 THEN                     Errr = @"block too big" : RETURN 0
  PRUCALL(CMD_RECV + N SHL 8,,"recvBlock: " & N)
  RETURN N
END FUNCTION


/'* \brief Receive a single byte (8 bit).
\returns The byte read from the bus.

This function triggers the bus to receive a single byte. The return
value is the byte received.

\since 0.0
'/
FUNCTION PruW1.recvByte()AS UInt8
  PRUCALL(CMD_RECV + 1 SHL 8,,"recvByte: ")
  RETURN DRam[4] AND &hFF
END FUNCTION


/'* \brief Get the state of the data line.
\returns The state (1 = high, 0 = low)

This function returns the current state of the GPIO line used for the
bus. The function uses libpruio to fetch the state, so only use it
after the PruIo::config() call.

\since 0.0
'/
FUNCTION PruW1.getIn() AS UInt8
  RETURN IIF(*Raw AND Mask, 1, 0)
END FUNCTION


/'* \brief Send the reset signal to the bus.
\returns The presence pulse from the bus.

This function sends the reset signal to the bus. It uses special
timing. After the reset signal all devices answer by a presence pulse,
so that the master knows that slave devices are on the bus. In that
case the return value is 0  (zero). Otherwise, in case of no devices
are responding, the return value is 1.

\since 0.0
'/
FUNCTION PruW1.resetBus() AS UInt8
  PRUCALL(CMD_RESET,,"resetBus:")
  RETURN DRam[4] AND &b1
END FUNCTION


/'* \brief Compute the CRC checksum for data package.
\param N The length of the package in bytes.
\returns The CRC checksum for a data package (0 = success).

A data package (usually the 64-bit scratchpad context) is in the PRU
DRam after a PruW1::readBlock() operation. This function computes
the CRC checksum for a package with a given length. The length
parameter specifies where to find the CRC byte, so in case of an 8 byte
package length has to be 9 (= the same value as in the
PruW1::readBlock() call).

\since 0.0
'/
FUNCTION PruW1.calcCrc(BYVAL N AS UInt8) AS UInt8
  VAR crc = 0, p = CAST(UBYTE PTR, @DRam[4])
  FOR p = p TO p + N - 1
    crc = crc8_table(crc XOR *p)
  NEXT : RETURN crc
END FUNCTION


/'* \brief Print the debugging log data to STDOUT.
\param N The number of states to output.

This function outputs the state of the bus data line for the debug
logging feature. When debugging is enabled the function gets called
after each operation and prints lines of 70 characters for each
transfered bit. See section \ref ChaDebug for details.

\since 0.0
'/
SUB PruW1.prot()
  STATIC AS UInt32 p = 64, b = 0
  ?
  FOR i AS INTEGER = 1 TO DRam[3]
    IF BIT(DRam[p], b) THEN ?"-"; ELSE ?"_";
    IF 0 = i MOD 70 THEN ?
    IF b < 31 THEN b += 1 ELSE b = 0 : IF p < 2047 THEN p += 1 ELSE p = 64
  NEXT : ?
END SUB


/'* \brief Compute the temperature for a series 10 sensor (old format).
\param Rom The pointer where to find the data received from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

This function decodes the temperature value from a DS18S20 sensor (such
sensors have `&h10` in the lowest byte of their ID). The returned value
contains the temperature in grad Celsius in the high byte and the
decimal places in the low byte. Divide the value by 256 to get a real
number containing the temperatur in grad Celsius.

Parameter `Rom` is usually the adress of PruW1::DRam[4].

\since 0.0
'/
FUNCTION T_fam10(BYVAL Rom AS UBYTE PTR) AS SHORT
  RETURN IIF(Rom[1], Rom[0] - 256, Rom[0]) SHL 7 + (Rom[7] - Rom[6] - 4) SHL 4
END FUNCTION


/'* \brief Compute the temperature for a series 20 sensor (new format).
\param Rom The pointer where to find the data received from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

This function decodes the temperature value from a DS18B20 sensor (such
sensors have `&h20` in the lowest byte of their ID). The returned value
contains the temperature in grad Celsius in the high byte and the
decimal places in the low byte. Divide the value by 256 to get a real
number containing the temperatur in grad Celsius.

Parameter `Rom` is usually the adress of PruW1::DRam[4].

\since 0.0
'/
FUNCTION T_fam20(BYVAL Rom AS UBYTE PTR) AS SHORT
  RETURN PEEK(SHORT, Rom)
END FUNCTION
