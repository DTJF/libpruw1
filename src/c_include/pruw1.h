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

//typedef signed char int8;      //!< 8 bit signed integer data type.
typedef unsigned char UInt8;      //!< 8 bit unsigned integer data type.
//typedef short int16;           //!< 16 bit signed integer data type.
//typedef int int32;             //!< 32 bit signed integer data type.
//typedef unsigned char uint8;   //!< 8 bit unsigned integer data type.
//typedef unsigned short uint16; //!< 16 bit unsigned integer data type.
typedef unsigned int UInt32;   //!< 32 bit unsigned integer data type.
typedef unsigned long int UInt64;   //!< 32 bit unsigned integer data type.
//typedef float float_t;         //!< float data type.

//! Tell pruss_intc_mapping.bi that we use ARM33xx.
#define AM33XX

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
short T_fam10 (unsigned char* Rom);


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
short T_fam20 (unsigned char* Rom);

/*! \brief The W1 driver class.

The class providing the one wire features.

\since 0.0
*/
typedef struct pruw1{
  char *Errr;  //!< The variable to report error messages.
  unsigned long int *Slots;//!< The array to store the device IDs.
  UInt32
    *Raw,  //!< A pointer to the libpruio raw GPIO data
    *DRam; //!< A pointer to the libpruio DRam.

//private:
  UInt32
    Mask,    //!< The mask to select the pin in use.
    PruNo,   //!< The number of the PRU to use
    PruIRam, //!< The PRU instruction ram to use.
    PruDRam; //!< The PRU data ram to use.

  //! A pre-computed table for fast CRC checksum computation.
  Uint8 crc8_table[255 + 1] = {
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65
  , 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220
  , 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98
  , 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255
  , 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7
  , 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154
  , 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36
  , 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185
  , 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205
  , 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80
  , 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238
  , 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115
  , 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139
  , 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22
  , 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168
  , 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
  };
};

/** \brief Wrapper function for the constructor PruW1::PruW1().
\param P A pointer to the libpruio instance (for pinmuxing).
\param B The header pin to use as W1 bus data line.
\returns A pointer to the new instance, call pruw1_destroy() when done.

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
*/
pruw1* pruw1_new(pruio *P, UInt8 B);

/** \brief Wrapper function for the destructor PruW1::~PruW1.
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
int pruw1_getSlotsSize (pruw1 *W1);


/** \brief Function to empty the array PruW1::Slots from C.
\param W1 The driver instance.

Auxiliary function to work aroung a missing feature in C syntax.

\since 0.0
*/
void pruw1_eraseSlots(pruw1 *W1);


#ifdef __cplusplus
 }
#endif /* __cplusplus */
