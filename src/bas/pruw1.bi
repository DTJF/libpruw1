/'* \file pruw1.bi
\brief The declarations for the PruW1 class.

This file contains the declarations for the PruW1 class. Include it to
compile against the library (#`INCLUDE ONCE "BBB/pruw1.bi"`).

\since 0.0
'/

#INCLUDE ONCE "BBB/pruio.bi"
#INCLIB "pruw1"

TYPE AS    SHORT Int16
TYPE AS ULONGINT UInt64

' forward declarations of helper functions
DECLARE FUNCTION T_fam10 (BYVAL AS UInt8 PTR) AS Int16
DECLARE FUNCTION T_fam20 (BYVAL AS UInt8 PTR) AS Int16


/'* \brief The W1 driver class.

The class providing the one wire features.

\since 0.0
'/
TYPE PruW1
  AS ZSTRING PTR Errr    '*< The variable to report error messages.
  AS UInt32 _
      Mask _     '*< The mask to select the pin in use.
    , PruNo _    '*< The number of the PRU to use
    , PruIRam _  '*< The PRU instruction ram to use.
    , PruDRam    '*< The PRU data ram to use.
  AS UInt32 PTR _
      DRam _     '*< A pointer to the libpruw1 DRam.
    , Raw        '*< A pointer to the libpruio raw GPIO data
  '* A pre-computed table for fast CRC checksum computation.
  AS Uint8 Crc8_Table(255) = { _
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65 _
  , 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220 _
  , 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98 _
  , 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255 _
  , 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7 _
  , 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154 _
  , 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36 _
  , 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185 _
  , 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205 _
  , 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80 _
  , 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238 _
  , 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115 _
  , 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139 _
  , 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22 _
  , 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168 _
  , 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 _
  }
  AS UInt64 Slots(ANY) '*< The array to store the device IDs.

  DECLARE CONSTRUCTOR(BYVAL AS PruIo PTR, BYVAL AS Uint8)
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION scanBus(BYVAL AS UInt8 = &hF0)AS ZSTRING PTR
  DECLARE SUB sendByte(BYVAL AS UInt8)
  DECLARE SUB sendRom(BYVAL AS UInt64)
  DECLARE FUNCTION recvBlock(BYVAL AS UInt8) AS UInt8
  DECLARE FUNCTION recvByte()AS UInt8
  DECLARE FUNCTION getIn() AS UInt8
  DECLARE FUNCTION resetBus() AS UInt8
  DECLARE FUNCTION calcCrc(BYVAL AS UInt8) AS UInt8
  DECLARE SUB prot()
END TYPE
