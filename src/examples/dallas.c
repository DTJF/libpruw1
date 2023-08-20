/*! \file dallas.c
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

\since 0.2
*/

#include <stdio.h>
#include <unistd.h>
#include "libpruio/pruio.h"
#include "libpruio/pruio_pins.h" // libruio pin numbering
#include "../c_include/pruw1.h" // library header (local)
//#include "libpruw1/pruw1.h" //     library header when installed

//! The main function.
int main(int argc, char **argv)
{
  int i, n;
  UInt8 crc, typ, *res;
  float val;
  char *txt;
  UInt64 id;
  // Create new libpruio instance.
  pruIo *io = pruio_new(PRUIO_DEF_ACTIVE, 4, 0x98, 0);

  do {
    if (io->Errr) {
                printf("libpruio CTOR failed (%s)\n", io->Errr); break;}
    // uncomment the following lines in order to use function PruW1::getIn()
    //if (io->config()) {
              //printf("libpruio config failed (%s)\n", io->Errr); break;}

    // Create new libpruw1 instance.
    pruw1 *w1 = pruw1_new(io, P9_15, PRUW1_PARPOW + PRUW1_PULLUP); // 2 wire (VDD=GND))
    //pruw1 *w1 = pruw1_new(io, P9_15, PRUW1_PULLUP); // external VDD and pullup
    if (w1->Errr) {
                printf("libpruw1 CTOR failed (%s)\n", w1->Errr); break;}
    // Scan the bus for parasite powered devices
    printf("%s parasite powered device.",
           (pruw1_checkPara(w1) ? "At least one" : "No"));
    // Scan the bus for device IDs
    printf("\ntrying to scan devices ...");
    if (pruw1_scanBus(w1)) {
                      printf("scanBus failed (%s)\n", w1->Errr); break;}
    for (i = 0; i <= pruw1_getSlotMax(w1); i++)
    {
      printf("\nfound device %d, ID: %llX", i, pruw1_getId(w1, i));
    }
    res = (UInt8 *) w1->DRam + 16; //!< pointer to measurement result
    printf("\n");
    // Perform some measurements
    for (n = 0; n <= 10; n++)
    {
      // Start measurement, send the presense pulse (0 = OK).
      if (pruw1_resetBus(w1)) {            printf("no devices"); break;}
      pruw1_sendByte(w1, 0xCC); // SKIP_ROM command -> broadcast message
      pruw1_sendByte(w1, 0x44); //convert T command -> all sensors triggered
      usleep(750000);

      // Fetch the data from sensor scratch pads
      for (i = 0; i <= pruw1_getSlotMax(w1); i++) {
        id = pruw1_getId(w1, i);

        typ = id & 0xFF;
        if (typ != 0x10 && typ != 0x20 && typ != 0x22 && typ != 0x28 && typ != 0x3B && typ != 0x42) continue;
        //printf("\nTyp: %X", crc);

        // Start reading, send the presense pulse (0 = OK).
        if (pruw1_resetBus(w1)) { printf("no devices"); break;} //!< check presense pulse (0 = OK).
        pruw1_sendByte(w1, 0x55);      // ROM_MATCH command -> adress single sensor
        pruw1_sendRom(w1, id);                   // send sensor ID -> select sensor
        pruw1_sendByte(w1, 0xBE); //READ_SCRATCH command -> sensor sends scratchpad
        pruw1_recvBlock(w1, 9); // read data block (64 bit scratchpad and CRC byte)

        // Output result
        crc = pruw1_calcCrc(w1, 9); //!< The checksum (0 = OK).
        if (crc) {
          txt = "error";
          val = -99;
        } else {
          txt = "OK:";
          val = (float)(typ == 0x10 ? T_FAM10(res) : T_FAM20(res)) / 256;
        }
        printf("\nsensor %llX --> %s %3.4f °C", id, txt, val);
      }
      printf("\n");
    }
    pruw1_destroy(w1);
  } while (0);

/* we're done */

  pruio_destroy(io);        /* destroy driver structure */
	return 0;
}
