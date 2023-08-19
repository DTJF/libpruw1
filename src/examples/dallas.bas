/'* \file dallas.bas
\brief Example fetching temperature from all Dallas sensors on the bus.

This example demonstrates how to

- initialize the \Proj library,
- define a GPIO header pin as one wire bus,
- handle error codes on initialization,
- scan the bus for all dallas sensor devices,
- perform 11 temperature convert broardcasts,
- read the measurement results from the sensor scratchpads, and
- print them on the screen.

Check the output for enabled monitoring feature as well, see section
\ref ChaMonitor for details.

\since 0.0
'/

#INCLUDE ONCE "BBB/pruio.bi" ' header for mandatroy libpruio
#INCLUDE ONCE "BBB/pruio_pins.bi" ' libruio pin numbering
'#INCLUDE ONCE "BBB/pruw1.bi" ' library header (after `make install`)
#INCLUDE ONCE "../bas/pruw1.bi" ' library header

VAR io = NEW PruIo() '*< Pointer to libpruio instance.
DO
  IF io->Errr THEN       ?"io CTOR failed (" & *io->Errr & ")" : EXIT DO

  ' uncomment the following lines in order to use function PruW1::getIn()
  'IF io->config() THEN _
               'PRINT "libpruio config failed (" & *.Errr & ")" : exit do

  '* Create new libpruw1 instance.
  VAR w1 = NEW PruW1(io, P9_15, PRUW1_PARPOW + PRUW1_PULLUP) ' 2 wire (VDD=GND)
  'VAR w1 = NEW PruW1(io, P9_15) ' external VDD and pullup

  DO : WITH *w1
    IF .Errr THEN _
             ?"w1 CTOR failed (" & *.Errr & "/" & *.Errr & ")" : EXIT DO
    ' Scan the bus for parasite powered devices
    ?*iif(.checkPara(), @"At least one", @"No") _
                        & " parasite powered device."
    ' Scan the bus for device IDs
    ?"trying to scan bus ..."
    IF .scanBus() THEN  PRINT"scanBus failed (" & *.Errr & ")" : EXIT DO
    ? ' print them out
    FOR i AS INTEGER = 0 TO UBOUND(.Slots) ' output slot# and sensor IDs
      ?"found device " & i & ", ID: " & HEX(.Slots(i), 16)
    NEXT

    VAR res = CAST(UBYTE PTR, @.DRam[4]) '*< pointer to measurement data
    ' Perform some measurements
    FOR i AS INTEGER = 0 TO 10 '                output 11 blocks of data
      ' Start measurement, send the presense pulse (0 = OK).
      IF .resetBus() THEN                        ?"no devices" : EXIT DO
      .sendByte(&hCC)            ' SKIP_ROM command -> broadcast message
      .sendByte(&h44)       ' convert T command -> all sensors triggered
      SLEEP 750 : ?                              ' wait for conversation
      ' Fetch the data from sensor scratch pads
      FOR s AS INTEGER = 0 TO UBOUND(.Slots)
        SELECT CASE AS CONST PEEK(UBYTE, @.Slots(s)) '        check type
        CASE &h10, &h20, &h22, &h28, &h3B, &h42 '   a Dallas sensor type
        CASE ELSE          /' no dallas sensor -> skip '/ : CONTINUE FOR
        END SELECT

        ' Start reading, send the presense pulse (0 = OK).
        IF .resetBus() THEN                     ?"no devices" : EXIT FOR '*< check presense pulse (0 = OK).
        .sendByte(&h55)      ' ROM_MATCH command -> adress single sensor
        .sendRom(.Slots(s))            ' send sensor ID -> select sensor
        .sendByte(&hBE) 'READ_SCRATCH command -> sensor sends scratchpad
        .recvBlock(9) ' read data block (64 bit scratchpad and CRC byte)

        ' output result
        VAR crc = .calcCrc(9) '*< The checksum (0 = OK).
        ?"sensor " & HEX(.Slots(s), 16) & " --> CRC ";
        IF crc THEN ?"error!" _
               ELSE ?"OK: " _
                    & IIF(PEEK(UBYTE, @.Slots(s)) = &h10 _
                      , T_fam10(res) _ ' old format
                      , T_fam20(res) _ ' new format
                        ) / 256 _
                    & " °C"
      NEXT
    NEXT
  END WITH : LOOP UNTIL 1
  DELETE w1                         '   destroy w1 UDT
LOOP UNTIL 1
DELETE io                         '   destroy libpruio UDT
