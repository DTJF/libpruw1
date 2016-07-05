/'* \file onlyDS18S20.bas
\brief Example fetching temperature from all DS18S20 sensors on the bus.

This example demonstrates how to

- initialize the \Proj library,
- define a GPIO header pin as one wire bus,
- handle error codes on initialization,
- scan the bus for family 10 devices only,
- perform 11 temperature convert broardcasts,
- read the measurement results from the sensor scratchpads, and
- print them on the screen.

Check the output for enabled monitoring feature as well, see section
\ref ChaMonitor for details.

\since 0.0
'/

'#INCLUDE ONCE "BBB/pruw1.bi" ' library header (after `make install`)
#INCLUDE ONCE "../bas/pruw1.bi" ' library header
#INCLUDE ONCE "BBB/pruio_pins.bi" ' libruio pin numbering

VAR io = NEW PruIo() '*< Pointer to libpruio instance.
DO
  IF io->Errr THEN       ?"io CTOR failed (" & *io->Errr & ")" : EXIT DO

  ' uncomment the following lines in order to use function PruW1::getIn()
  'IF io->config() THEN _
               'PRINT "libpruio config failed (" & *.Errr & ")" : exit do

  VAR w1 = NEW PruW1(io, P9_15) '*< Pointer to libpruw1 instance.
  DO : WITH *w1
    IF .Errr THEN _
          ?"w1 CTOR failed (" & *.Errr & "/" & *io->Errr & ")" : EXIT DO
    IF .scanBus() THEN _
                        PRINT"scanBus failed (" & *.Errr & ")" : EXIT DO
    ?
    FOR i AS INTEGER = 0 TO UBOUND(.Slots) ' output slot# and sensor IDs
      ?"found device " & i & ", ID: " & HEX(.Slots(i), 16)
    NEXT

    FOR i AS INTEGER = 0 TO 10 '                output 11 blocks of data
      IF .resetBus() THEN                        ?"no devices" : EXIT DO '*< check presense pulse (0 = OK).

      .sendByte(&hCC)            ' SKIP_ROM command -> broadcast message
      .sendByte(&h44)       ' convert T command -> all sensors triggered
      SLEEP 750 : ?                              ' wait for conversation

      FOR s AS INTEGER = 0 TO UBOUND(.Slots)
        IF PEEK(UBYTE, @.Slots(s)) <> &h10 THEN CONTINUE FOR ' series 10 only

        IF .resetBus() THEN                     ?"no devices" : EXIT FOR '*< The presense pulse (0 = OK).

        .sendByte(&h55)      ' ROM_MATCH command -> adress single sensor
        .sendRom(.Slots(s))            ' send sensor ID -> select sensor

        .sendByte(&hBE) 'READ_SCRATCH command -> sensor sends scratchpad
        .recvBlock(9) ' read data block (64 bit scratchpad and CRC byte)

        VAR crc = .calcCrc(9) '*< The checksum (0 = OK).
        ?"sensor " & HEX(.Slots(s), 16) & " --> " & *IIF(crc, @"error: ", @"OK: ");
        ?T_fam10(CAST(UBYTE PTR, @.DRam[4])) / 256
      NEXT
    NEXT
  END WITH : LOOP UNTIL 1
  DELETE w1                         '   destroy w1 UDT
LOOP UNTIL 1
DELETE io                         '   destroy libpruio UDT
