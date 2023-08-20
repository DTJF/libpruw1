/** \file pruw1.h
\brief The main header code of the C wrapper for libpruw1.

This file provides the declarations of macros, types and classes in C
syntax. Include this file in your code to make use of libpruw1. This
file contains a translation of the context of all FreeBASIC headers
(pruw1.bi) in one file.

Feel free to translate this file in order to create language bindings
for non-C languages in order to use libpruio in polyglot applications.

Licence: LGPLv2 (http://www.gnu.org/licenses/lgpl-2.0.html)

Copyright 2015-\Year by \Email

*/

#ifdef __cplusplus
 extern "C" {
#endif /* __cplusplus */

#include "pruw1.hp"
#include "libpruio/pruio.h"

typedef unsigned char UInt8;      //!< 8 bit unsigned integer data type.
typedef short Int16;              //!< 16 bit signed integer data type.
typedef int Int32;                //!< 32 bit signed integer data type.
typedef unsigned int UInt32;      //!< 32 bit unsigned integer data type.
typedef unsigned long long int UInt64; //!< 64 bit unsigned integer data type.

//! forward declaration
typedef struct pruw1 pruw1;


/** \brief Compute the temperature for a series 10 sensor (old format).
\param Rom The pointer where to find the data received from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

This function decodes the temperature value from a DS18S20 sensor (such
sensors have `&h10` in the lowest byte of their ID). The returned value
contains the temperature in grad Celsius in the high byte and the
decimal places in the low byte. Divide the value by 256 to get a real
number containing the temperatur in grad Celsius.

Parameter `Rom` is usually the adress of PruW1::DRam[4].

\since 0.0
*/
Int16 T_FAM10(UInt8* Rom);


/** \brief Compute the temperature for a series 20 sensor (new format).
\param Rom The pointer where to find the data received from the device.
\returns The temperature (high byte = decimal value, low byte = digits).

This function decodes the temperature value from a DS18B20 sensor (such
sensors have `&h20` in the lowest byte of their ID). The returned value
contains the temperature in grad Celsius in the high byte and the
decimal places in the low byte. Divide the value by 256 to get a real
number containing the temperatur in grad Celsius.

Parameter `Rom` is usually the adress of PruW1::DRam[4].

\since 0.0
*/
Int16 T_FAM20(UInt8* Rom);

/*! \brief Masks for line idle configuration

This enumerators are for use in CTOR PruW1::PruW1() to configure the
line idle modus, regarding parasite power support and the use of the
internal pull up resistor.

\since 0.4
*/
enum LineModus{
  PRUW1_PARPOW = 0x1 //!< Set line output high during idle
 ,PRUW1_PULLUP = 0x2 //!< Activate the internal pull up resistor
};


/*! \brief The PruW1 C wrapper structure.

The class providing the one wire features.

\since 0.0
*/
typedef struct pruw1{
  char *Errr;  //!< The variable to report error messages.
  UInt32
    Mask,    //!< The mask to select the pin in use.
    PruNo,   //!< The number of the PRU to use
    PruIRam, //!< The PRU instruction ram to use.
    PruLMod, //!< The line modus to use (parasite power).
    *DRam,   //!< A pointer to the libpruw1 DRam.
    *Raw;    //!< A pointer to the libpruio raw GPIO data

  //! A pre-computed table for fast CRC checksum computation.
  UInt8 crc8_table[255 + 1];
  //UInt64 *Slots; //!< The FB array to store the device IDs.
}pruw1;

/** \brief Wrapper function for the constructor PruW1::PruW1().
\param P A pointer to the libpruio instance (for pinmuxing).
\param B The header pin to use as W1 bus data line.
\param M The operating modus (Parasite power, internal pull-up).
\returns A pointer to the new instance, call pruw1_destroy() when done.

The constructor is designed to

- allocate and initialize memory for the class variables,
- evaluate the free PRU (not used by libpruio)
- check the header pin configuration (and, if not matching, try to adapt it - root privileges),
- load the firmware and start it

In case of success the variable PruW1::Errr is 0 (zero) and you can
start to communicate on the bus. Otherwise the variable contains an
error message. The string is owned by \Proj and should not be freed. In
that case call the destructor (and do not start any communication).

The operating modus M is introduced in version 0.4 in order to
influence power consumption (ie. for batterie powered systems):

- Bit-0 controlls the idle state of the line. By default the line is in
input state and the external pull-up resistor pulls the line high
during idle. Set the bit to configure the line for parasite power (=
output/high during idle) by the costs of more energy consumption (max.
current = 6 mA).

- Bit-1 controlls the resistor configuration. By default an external
resistor is used at the line (usually 4k7 Ohm). Set the bit to
configure the internal pull up resistor (10k).

\since 0.0
*/
pruw1* pruw1_new(pruIo *P, UInt8 B, UInt8 M);

/** \brief Wrapper function for the destructor PruW1::~PruW1().
\param W1 The driver instance.

\since 0.0
*/
void pruw1_destroy(pruw1* W1);

/** \brief Function to scan the bus for all devices.
\param W1 The driver instance.
\param SearchType The search type (defaults to &hF0).
\returns An error message or `0` (zero) on success.

This function scans the bus and collects the IDs of the found devices
(if any) in the array Slots. By default it uses the default search ROM
command (`&hF0`).

Find the number of devices by evaluating the upper bound of array
Slots, using function getSlotsSize().

\note Usually the bus gets scanned once in the init process of an
      application. When you intend to use dynamic sensor connections
      (plug them in and out), then you have to periodically re-scan the
      bus. In that case clear the Slots array before each scan, in
      order to avoid double entries by function eraseSlots().

\since 0.0
*/
char *pruw1_scanBus(pruw1* W1, UInt8 SearchType);
#define pruw1_scanBus(W1) pruw1_scanBus(W1, 0xF0)


/** \brief Send a byte (eight bits) to the bus.
\param W1 The driver instance.
\param V The value to send.

This procedure sends a byte to the bus. It's usually used to issue a
ROM command.

\since 0.0
*/
void pruw1_sendByte(pruw1* W1, UInt8 V);


/** \brief Send a ROM ID to the bus (to select a device).
\param W1 The driver instance.
\param V The ROM ID (8 btes) to send.

This procedure sends a ROM ID to the bus. It's usually used to adress a
single device, ie. to read its scratchpad.

\since 0.0
*/
void pruw1_sendRom(pruw1* W1, UInt64 V);


/** \brief Receive a block of data (usually 9 bytes).
\param W1 The driver instance.
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
*/
UInt8 pruw1_recvBlock(pruw1* W1, UInt8 N);


/** \brief Receive a single byte (8 bit).
\param W1 The driver instance.
\returns The byte read from the bus.

This function triggers the bus to receive a single byte. The return
value is the byte received.

\since 0.0
*/
UInt8 pruw1_recvByte(pruw1* W1);


/** \brief Get the state of the data line.
\param W1 The driver instance.
\returns The state (1 = high, 0 = low)

This function returns the current state of the GPIO line used for the
bus. The function uses libpruio to fetch the state, so only use it
after the PruIo::config() call.

\since 0.0
*/
UInt8 pruw1_getIn(pruw1* W1);


/** \brief Send the reset signal to the bus.
\param W1 The driver instance.
\returns The presence pulse from the bus.

This function sends the reset signal to the bus. It uses special
timing. After the reset signal all devices answer by a presence pulse,
so that the master knows that slave devices are on the bus. In that
case the return value is 0  (zero). Otherwise, in case of no devices
are responding, the return value is 1.

\since 0.0
*/
UInt8 pruw1_resetBus(pruw1* W1);


/** \brief Check line for parasite powered device.
\returns TRUE (1) if at least one device uses parasite power, FALSE (0) otherwise.

This function triggers a broadscast READ POWER command. The returned
value is the byte received. If the function returns FALSE (0) there's
no parasite powered device on the bus (all VDD=3V3). In contrast, TRUE
(1) means at least one device has no external power line (VDD=GND) and
needs the strong pullup in idle mode.

\since 0.4
*/
UInt8 pruw1_checkPara(pruw1* W1);

/** \brief Compute the CRC checksum for data package.
\param W1 The driver instance.
\param N The length of the package in bytes.
\returns The CRC checksum for a data package (0 = success).

A data package (usually the 64-bit scratchpad context) is in the PRU
DRam after a PruW1::readBlock() operation. This function computes
the CRC checksum for a package with a given length. The length
parameter specifies where to find the CRC byte, so in case of an 8 byte
package length has to be 9 (= the same value as in the
PruW1::readBlock() call).

\since 0.0
*/
UInt8 pruw1_calcCrc(pruw1* W1, UInt8 N);


/** \brief Property to get size of array PruW1::Slots from C.
\param W1 The driver instance.
\returns The number of elements array PruW1::Slots.

Auxiliary function to work aroung a missing feature in C syntax.

\since 0.0
*/
Int32 pruw1_getSlotMax (pruw1 *W1);


/** \brief Function to empty the array PruW1::Slots from C.
\param W1 The driver instance.

Auxiliary function to work aroung a missing feature in C syntax.

\since 0.0
*/
void pruw1_eraseSlots(pruw1 *W1);


/** \brief Function to get ID from array PruW1::Slots from C.
\param W1 The driver instance.
\param N The number of the slot entry.

Auxiliary function to work aroung a missing feature in C syntax.

\since 0.2
*/
UInt64 pruw1_getId(pruw1 *W1, UInt32 N);


#ifdef __cplusplus
 }
#endif /* __cplusplus */
