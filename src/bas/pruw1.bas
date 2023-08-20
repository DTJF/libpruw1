/'* \file pruw1.bas
\brief The function bodies for the PruW1 class, tools for decoding.

This file contains the function bodies for the PruW1 class and some
functions to decode the temperature from the received data.

\since 0.0
'/

#INCLUDE ONCE "w1_prucode.bi" ' PRU firmware
#INCLUDE ONCE "pruw1.hp" ' PRU syncronization
#INCLUDE ONCE "BBB/pruio_prussdrv.bi"
#INCLUDE ONCE "BBB/pruio_intc.bi"
#INCLUDE ONCE "pruw1.bi" ' FB declarations

#IFNDEF __PRUW1_MONITOR__
 '* Macro to call a function on the PRU, monitoring features disabled.
 #MACRO PRUCALL(_C_,_V_,_T_)
  WHILE DRam[0] : SLEEP 1 : WEND
  _V_
  DRam[0] = _C_ + PruLMod
  WHILE DRam[0] : SLEEP 1 : WEND
 #ENDMACRO
#ELSE
 '* Macro to call a function on the PRU, monitoring features enabled.
 #MACRO PRUCALL(_C_,_V_,_T_)
  WHILE DRam[0] : SLEEP 1 : ?"."; : WEND
  _V_
  DRam[0] = _C_ + PruLMod
  ?!"\n";_T_; " command=&h"; HEX(DRam[0], 4); " ";
  WHILE DRam[0] : SLEEP 1 : ?"."; : WEND
  prot()
 #ENDMACRO
#ENDIF

/'* \brief The constructor is configuring the bus pin, loading and starting the PRU code.
\param P A pointer to the libpruio instance (for pinmuxing).
\param B The header pin to use as W1 bus data line.
\param M The operating modus (Parasite power, internal pull-up).

The constructor is designed to

- allocate and initialize memory for the class variables,
- evaluate the free PRU (not used by libpruio)
- check the header pin configuration (and, if not matching, try to adapt it - pinmuxing),
- load the firmware and start it

In case of success the variable PruW1::Errr is 0 (zero), ready for
starting the communication on the bus. Otherwise the variable contains
an error message. The string is owned by \Proj and should not be freed.
In that case call the destructor (and do not start any communication).

The operating modus M is introduced in version 0.4 in order to
influence power consumption (ie. for batterie powered systems):

- Bit-0 controlls the idle state of the line during sensor operation.
  By default the line is in input state (only the pull-up resistor
  pulls the line high). Set this bit in order to bring the line in high
  output state during sensor operation for parasite powering.

\note For parasite powering the sensor VDD line must get grounded. The
      sensors current is up to 1.5 mA, so you must not run more than 4
      sensors in parasite powering on a BBB-GPIO.

- Bit-1 controlls the resistor configuration. By default By default the
  internal pull-up resistor pulls the line high, so that a sensor can
  operate without any further wiring. For long cables use an external
  resistor (usually 4k7 Ohm). Clear the bit in oder to save some energy
  consumption.

\since 0.0
'/
CONSTRUCTOR PruW1(BYVAL P AS PruIo PTR, BYVAL B AS Uint8, BYVAL M AS Uint8 = PRUW1_PULLUP)
  IF 0 = P ORELSE P->Errr THEN Errr = @"libpruio issue" : EXIT CONSTRUCTOR
  WITH *P
    IF B > UBOUND(.BallGpio) THEN _
                         Errr = @"invalid pin number" : EXIT CONSTRUCTOR
    IF .Gpio->config(B, IIF(M AND PRUW1_PULLUP, PRUIO_GPIO_IN_1, PRUIO_GPIO_IN)) THEN _
             Errr = @"pin configuration not matching" : EXIT CONSTRUCTOR
    VAR r = .BallGpio(B) _ ' resulting GPIO (index and bit number)
      , i = r SHR 5 _      ' index of GPIO
      , n = r AND 31 _     ' number of bit
      , ram = PRUSS0_SRAM
    Mask = 1 SHL n
    Raw = @.Gpio->Raw(i)->Mix
    PruLMod = M AND PRUW1_PARPOW
    IF .PruNo THEN
      PruNo = 0
      PruIRam = PRUSS0_PRU0_IRAM
#IFNDEF __SRAM_BASE__
      ram = PRUSS0_PRU0_DRAM
    ELSE
      ram = PRUSS0_PRU1_DRAM
#ELSE
    ELSE
#ENDIF
      PruIRam = PRUSS0_PRU1_IRAM
      PruNo = 1
    END IF
    prussdrv_map_prumem(ram, CAST(ANY PTR, @DRam))

    prussdrv_pru_disable(PruNo) '        disable PRU (if running before)
    DRam[0] = PruLMod
    DRam[1] = .Gpio->Conf(i)->DeAd + &h100 ' device adress
    DRam[2] = Mask                         ' the mask to related bit

    VAR l = (UBOUND(Pru_W1) + 1) * SIZEOF(Pru_W1(0))
    IF 0 >= prussdrv_pru_write_memory(PruIRam, 0, @Pru_W1(0), l) THEN _
                Errr = @"failed loading PRU firmware" : EXIT CONSTRUCTOR
    prussdrv_pru_enable(PruNo)
    IF PruLMod THEN SLEEP 1 ' load capacitors
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

This function scans the bus and collects the IDs of the found devices
(if any) in the array Slots. By default it uses the default search ROM
command (`&hF0`).

Find the number of devices by evaluating the upper bound of array Slots.

\note Usually the bus gets scanned once in the init process of an
      application. When you intend to use dynamic sensor connections
      (plug them in and out), then you have to periodically re-scan the
      bus. In that case clear the Slots array before each scan, in
      order to avoid double entries.

\since 0.0
'/
FUNCTION PruW1.scanBus(BYVAL SearchType AS UInt8 = &hF0) AS ZSTRING PTR
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
    IF resetBus() THEN                Errr = @"no devices" : RETURN Errr
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
  WEND :                                                     RETURN 0
END FUNCTION


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
\param N The number of bytes to read.
\returns The number of bytes read.

This function triggers the bus to receive a block of bytes. Parameter
`N` specifies the number of bytes to read. The return value is the
number of bytes read, or 0 (zero) in case of an error (message text in
PruW1::Errr). The received data bytes are in the PruW1::DRam, starting
at byte offset `&h10` (= DRam[4]).

\note When compiled with monitor feature, the maximum block size is 112
      bytes, due to limited size of logging memory (PruW1::DRam)

\since 0.0
'/
FUNCTION PruW1.recvBlock(BYVAL N AS UInt8) AS UInt8
#IFDEF __PRUW1_MONITOR__
  IF N > 112 THEN Errr = @"block too big (< 112 bytes in monitoring)" : RETURN 0
#ENDIF
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
    crc = Crc8_Table(crc XOR *p)
  NEXT : RETURN crc
END FUNCTION


/'* \brief Print the monitoring log data to STDOUT.

This function outputs the state of the bus data line for the monitoring
log feature. When monitoring is enabled at compile time, this function
gets called after each operation and prints lines of 70 characters for
each transfered bit. See section \ref ChaMonitor for details.

\since 0.0
'/
SUB PruW1.prot()
  STATIC AS UInt32 p = LOG_BASE, b = 0
  ?
  FOR i AS INTEGER = 1 TO DRam[3]
    IF BIT(DRam[p], b) THEN ?"-"; ELSE ?"_";
    IF 0 = i MOD 70 THEN ?
    IF b < 31 THEN b += 1 ELSE b = 0 : IF p < 2047 THEN p += 1 ELSE p = LOG_BASE
  NEXT : ?
END SUB


/'*  \brief Check line for parasite powered device.
\param Id Sensor Id, or 0 (zero) for broadcast.
\returns TRUE (1) if at least one device uses parasite power, FALSE (0) otherwise.

This function triggers a broadscast READ POWER command. The returned
value is the (inverted) bit received. If the function returns FALSE (0)
there's no parasite powered device on the bus (all VDD=3V3). In
contrast, TRUE (1) means that at least one device has no external power
line (VDD=GND) and needs the strong pullup in idle mode.

\since 0.4
'/
FUNCTION PruW1.checkPara()AS UInt8
  IF resetBus() THEN                Errr = @"no devices" : RETURN 0
  sendByte(&hCC)  ' SKIP_ROM command -> broadcast message
  sendByte(&hB4)  ' READ_POWER command
  RETURN IIF(BIT(recvByte(), 0), 0, 1)
END FUNCTION


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
FUNCTION T_fam10(BYVAL Rom AS UBYTE PTR) AS SHORT EXPORT
  RETURN PEEK(SHORT, Rom) SHR 1 SHL 8 + (Rom[7] - Rom[6] - 4) SHL 4
END FUNCTION


/'* \brief Compute the temperature for a series 20 sensor (new format).
\param Rom The pointer where to find the data received from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

This function decodes the temperature value from a newer Dallas sensor
(the lowest byte in the ID of such sensors is either `&h20`, `&h22`,
`&h28`, `&h3B` or `&h42`). The returned value contains the temperature
in grad Celsius in the high byte and the decimal places in the low
byte. Divide the value by 256 to get a real number containing the
temperatur in grad Celsius.

Parameter `Rom` is usually the adress of PruW1::DRam[4].

\since 0.0
'/
FUNCTION T_fam20(BYVAL Rom AS UBYTE PTR) AS SHORT EXPORT
  RETURN PEEK(SHORT, Rom) SHL 4
END FUNCTION
