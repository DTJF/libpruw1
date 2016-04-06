/'* \file w1_driver.bas
\brief The function bodies for the w1Driver class.

FIXME

\since 0.0
'/

#INCLUDE ONCE "w1_prucode.bi" '   include header
#INCLUDE ONCE "w1_driver.bi" '   include header


/'* \brief The constructor configuring the pin, loading and staring the PRU code
\param P A pointer to the libpruio instance (for pinmuxing).
\param B The header pin to use as W1 bus data line.

FIXME

\since .
'/
CONSTRUCTOR w1Driver(BYVAL P AS PruIo PTR, BYVAL B AS Uint8)
  WITH *P
    IF .Gpio->config(B, PRUIO_GPIO_IN) THEN  EXIT CONSTRUCTOR

    VAR r = .BallGpio(B) _ ' resulting GPIO (index and bit number)
      , i = r SHR 5 _      ' index of GPIO
      , n = r AND 31       ' number of bit
    Mask = 1 SHL n
    Raw = @.Gpio->Raw(i)->Mix

    prussdrv_map_prumem(PruDRam, CAST(ANY PTR, @DRam))

    prussdrv_pru_disable(PruNo) '      disable PRU-0 (if running before)
    DRam[0] = 0
    DRam[1] = .Gpio->Conf(i)->DeAd + &h100 ' device adress
    DRam[2] = Mask                         ' the mask to related bit

    VAR l = (UBOUND(Pru_W1) + 1) * SIZEOF(Pru_W1(0))
    IF 0 >= prussdrv_pru_write_memory(PRUSS0_PRU0_IRAM, 0, @Pru_W1(0), l) THEN _
              ?"failed loading Pru_Init instructions" : EXIT CONSTRUCTOR
    prussdrv_pruintc_init(@PRUSS_INTC_INITDATA) ' interrupts initialization
    prussdrv_pru_enable(PruNo)
  END WITH
END CONSTRUCTOR


/'* \brief The destructor stopping and disabling the PRU

FIXME

\since 0.0
'/
DESTRUCTOR w1Driver()
  prussdrv_pru_disable(PruNo) '      disable PRU-0
END DESTRUCTOR


/'* \brief Function to scan the bus for all devices.
\param SearchType The search type (defaults to &hF0).

FIXME

\since 0.0
'/
SUB w1Driver.scanBus(BYVAL SearchType AS UInt8 = &hF0)
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
    IF resetBus() THEN ?"no devices" : EXIT WHILE
    send8(SearchType)
    FOR i AS INTEGER = 0 TO 63
      SELECT CASE i
      CASE      desc_bit : search_bit = 1 '/* took the 0 path last_device time, so take the 1 path */
      CASE IS > desc_bit : search_bit = 0	'/* take the 0 path on the next branch */
      CASE ELSE          : search_bit = (last_rn SHR i) AND &b1
      END SELECT

       waitDRam0(.)
       DRam[0] = 1 + search_bit SHL 8
       waitDRam0(>)
       ret = DRam[4] AND &b111

       SELECT CASE AS CONST ret
       CASE 0 : last_zero = i
       CASE 3 : ?"error" : CONTINUE WHILE
       END SELECT
       rn OR= CULNGINT(ret) SHR 2 SHL i
    NEXT
    IF desc_bit = last_zero ORELSE last_zero < 0 THEN last_device = 1
    desc_bit = last_zero
    addSensor(rn)
    cnt += 1
  WEND
END SUB


/'* \brief Function to add a device to the w1Driver::Slots array.
\param N The device ID to add.
\returns The current maximum index of the dynamic w1Driver::Slots array.

FIXME

\since 0.0
'/
FUNCTION w1Driver.addSensor(BYVAL N AS ULONGINT) AS INTEGER
  VAR u = UBOUND(Slots) + 1
  REDIM PRESERVE Slots(u)
  Slots(u) = N
  RETURN u
END FUNCTION


/'* \brief Send eight bits (a byte) to the bus.
\param V The value to send.

FIXME

\since 0.0
'/
SUB w1Driver.send8(BYVAL V AS UInt8)
  waitDRam0(.)
Debug(!"\nsend8: " & HEX(V, 2) & " " & BIN(V, 8) & " ")
  DRam[4] = V
  DRam[0] = 30 + 1 SHL 8
  waitDRam0(>)
END SUB


/'* \brief Send a ROM id to the bus (to select a device).
\param V The ROM id (8 btes) to send.

FIXME

\since 0.0
'/
SUB w1Driver.sendRom(BYVAL V AS ULONGINT)
  waitDRam0(.)
  *CAST(ULONGINT PTR, @DRam[4]) = V
Debug(!"\nsendRom: " & HEX(PEEK(ULONGINT, @DRam[4]), 16) & " ")
  DRam[0] = 30 + 8 SHL 8
  waitDRam0(>)
END SUB


/'* \brief Receive a block of data (usually 9 bytes).
\param N The number of bytes to read (receive).
\returns The number of bytes read.

FIXME

\since 0.0
'/
FUNCTION w1Driver.recvBlock(BYVAL N AS UInt8) AS UInt8
  waitDRam0(.)
Debug(!"\nrecvBlock: " & N & " CMD ...")
  DRam[0] = 20 + N SHL 8
Debug(" start " & DRam[0])
  waitDRam0(.)
Debug(" done")
  RETURN N
END FUNCTION


/'* \brief Receive a single byte (8 bit).
\returns The byte read from the bus.

FIXME

\since 0.0
'/
FUNCTION w1Driver.recv8()AS UInt8
  waitDRam0(.)
Debug(!"\nrecv8:")
Debug("  CMD ...")
  DRam[0] = 20 + 1 SHL 8
Debug(" start " & DRam[0])
  waitDRam0(.)
Debug(" done")
  RETURN DRam[4] AND &hFF
END FUNCTION


/'* \brief Get the state of the data line.
\returns The state (1 = high, 0 = low)

FIXME

\since 0.0
'/
FUNCTION w1Driver.getIn() AS UInt8
  RETURN IIF(*Raw AND Mask, 1, 0)
END FUNCTION


/'* \brief Send the reset signal to the bus.
\returns FIXME

FIXME

\since 0.0
'/
FUNCTION w1Driver.resetBus() AS UInt8
  waitDRam0(.)
Debug(!"\nresetBus:")
  DRam[0] = 10
  waitDRam0(.)
  RETURN DRam[4] AND &b1
END FUNCTION


/'* \brief Compute the CRC checksum for data package.
\param N The length of the package.
\returns FIXME

FIXME

\since 0.0
'/
FUNCTION w1Driver.calcCrc(BYVAL N AS UInt8) AS UInt8
	VAR crc = 0, p = CAST(UBYTE PTR, @DRam[4])
	FOR p = p TO p + N - 1
    crc = crc8_table(crc XOR *p)
  NEXT : RETURN crc
END FUNCTION


/'* \brief Print the log data to to STDOUT.
\param N The number of states to output.

FIXME

\since 0.0
'/
SUB w1Driver.prot(BYVAL N AS UInt16)
  STATIC AS UInt32 p = 64, b = 0
  FOR i AS INTEGER = 1 TO N
    IF i MOD 70 THEN
      IF BIT(DRam[p], b) THEN ?"-"; ELSE ?"_";
    ELSE
      IF BIT(DRam[p], b) THEN ?"-" ELSE ?"_"
    END IF
    IF b < 31 THEN b += 1 ELSE b = 0 : IF p < 2047 THEN p += 1 ELSE p = 64
  NEXT : ?
END SUB


/'* \brief Compute the temperature for a series 10 sensor (old format).
\param Rom The data read from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

FIXME

\since 0.0
'/
FUNCTION T_fam10(BYVAL Rom AS UBYTE PTR) AS SHORT
  RETURN IIF(Rom[1], Rom[0] - 256, Rom[0]) SHL 7 + (Rom[7] - Rom[6] - 4) SHL 4
END FUNCTION


/'* \brief Compute the temperature for a series 20 sensor (new format).
\param Rom The data read from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

FIXME

\since 0.0
'/
FUNCTION T_fam20(BYVAL Rom AS UBYTE PTR) AS SHORT
  RETURN PEEK(SHORT, Rom)
END FUNCTION
