
//  compile for .bi output
//    pasm -V3 -y -CPru_W1 w1_prucode.p

#include "w1_prucode.hp"

#define DRam C24
#define DIN 0x38
#define CDO 0x90
#define SDO 0x94

#define DeAd r1
#define Msk1 r2
#define Msk0 r3

#define DAT  r4
#define DATC r4.b2
#define DATD r4.b0
#define uSEC r5
#define CMD  r6
#define XX   r8
#define MonC r9

#define OE r10
#define UR r11
#define U2 r12

// memory usage DRam:
// 00 CMD   Command to execute
// 04 DeAd  Device adress of GPIO subsystem
// 08 Msk1  Mask to separate the GPIO bit
// 0C MonC  Monitoring counter
// 10 Data  Data to exchange between PRU and ARM
// 100 Log data  Data for monitoring feature

.macro SWITCH_INP
  LBBO OE,  DeAd, 0x34, 4  // load OE
  OR   OE,  OE, Msk1       // set bit -> input
  SBBO OE,  DeAd, 0x34, 4  // write OE
.endm

.macro SWITCH_OUT
  LBBO OE,  DeAd, 0x34, 4  // load OE
  AND  OE,  OE, Msk0       // clr bit -> output
  SBBO OE,  DeAd, 0x34, 4  // write OE
.endm

.origin 0
LDI  XX, LOG_BASE*4
LDI  MonC, 0x0

ZERO &r0, 4             // clear register R0
MOV  DeAd, 0x22020      // load address
SBBO r0, DeAd, 0, 4     // make C24 point to 0x0 (this PRU DRAM) and C25 point to 0x2000 (the other PRU DRAM)

LBCO DeAd, DRam, 0x04, 4*2 // load device adress and Msk1
MOV  Msk0, 0xFFFFFFFF
XOR  Msk0, Msk0, Msk1

SWITCH_INP

main_loop:
  SBCO MonC,  DRam, 0x0C, 4  // save bit counter
  LDI  MonC,  0              // reset counter
  LDI  CMD, 0
  SBCO CMD, DRam, 0x00, 4    // clear command

  getCMD:
  LBCO CMD, DRam, 0x00, 4    // load command
  QBEQ getCMD, CMD, 0        // wait for command

  QBEQ sendcmd, CMD.b0, CMD_SEND
  QBEQ recvcmd, CMD.b0, CMD_RECV
  QBEQ triplet, CMD.b0, CMD_TRIP

resetcmd:
  SWITCH_OUT
  SBBO Msk1, DeAd, CDO, 4    // write clear data out -> LOW

  LDI  uSEC, 480
  CALL Delay

  SWITCH_INP

  LDI  uSEC, 100
  CALL Delay

  LBBO DAT, DeAd, DIN, 4     // read DATAIN
  AND  DAT, DAT, Msk1        // mask our bit
  QBEQ resetZero, DAT, 0     // check result
  LDI  DAT, 1

  resetZero:
  SBCO DAT, DRam, 0x10, 4    // write result to data array

  LDI  uSEC, 380
  CALL Delay

JMP main_loop


recvcmd:
  LDI  CMD.w2, 0x10          // initialize write position
  LOOP recvLoop, CMD.b1
    LDI  DAT, 0                // reset result

    recv8loop:
      SWITCH_OUT
      SBBO Msk1, DeAd, CDO, 4  // write clear data out --> LOW
      LDI  uSEC,  6
      CALL Delay

      SWITCH_INP
      LDI  uSEC,  9
      CALL Delay

      LBBO UR, DeAd, DIN, 4    // read DATAIN
      AND  UR, UR, Msk1        // mask our bit
      QBEQ recvCont, UR, 0     // skip if zero
      SET  DATD, DATC          // set bit in output

      recvCont:
      LDI  uSEC, 55
      CALL Delay

      ADD  DATC, DATC, 1       // increase counter
    QBGT recv8loop, DATC, 8    // next bit

    SBCO DATD, DRam, CMD.w2, 1 // write result to data array
    ADD  CMD.w2, CMD.w2, 1     // increase pointer
  recvLoop:

JMP main_loop


triplet:
  LDI  DAT, 0
  LOOP tripLoop, 2
    SWITCH_OUT
    SBBO Msk1, DeAd, CDO, 4    // write clear data out --> LOW

    LDI  uSEC,  6
    CALL Delay
    SWITCH_INP
    LDI  uSEC,  9
    CALL Delay

    LBBO UR, DeAd, DIN, 4      // read DATAIN
    AND  UR, UR, Msk1          // mask our bit
    QBEQ tripCont, UR, 0       // skip if zero
    SET  DATD, DATC            // set bit in output

    tripCont:
    ADD  DATC, DATC, 1

    LDI  uSEC,  55
    CALL Delay
  tripLoop:
  QBNE tripValid, DATD, 3   // is valid?
  SBCO DAT, DRam, 0x10, 4   // error, store result
  JMP main_loop

  tripValid:
  QBNE tripSingle, DATD, 0  // is one direction?
  QBEQ tripWrite, CMD.b1, 0
  LDI  DATD, 4
  JMP tripWrite

  tripSingle:
  AND  CMD.b1, DATD, 1
  LDI  DATD, 2
  QBEQ tripWrite, CMD.b1, 0
  LDI  DATD, 5

  tripWrite:
  SBCO DAT, DRam, 0x10, 4   // save return value

  SWITCH_OUT
  SBBO Msk1, DeAd, CDO, 4   // write clear data out --> LOW
  QBNE trip1, CMD.b1, 0     // high or low

  LDI  uSEC, 60
  CALL Delay
  LDI  uSEC, 10
  JMP tripEnd

  trip1:
  LDI  uSEC,  6
  CALL Delay
  LDI  uSEC, 64

  tripEnd:
  SBBO Msk1, DeAd, SDO, 4   // write set data out --> HIGH
  CALL Delay
  SWITCH_INP
JMP main_loop


sendcmd:
  LDI  CMD.w2, 0x10           // initialize load position
  SWITCH_OUT

  LOOP sendLoop, CMD.b1
    LDI  DATC, 0                // reset counter
    LBCO DATD, DRam, CMD.w2, 1  // load byte from array

    send8:
      SBBO Msk1, DeAd, CDO, 4   // write clear data out --> LOW
      QBBS send1, DATD, DATC    // high or low?

      LDI  uSEC, 60
      CALL Delay
      LDI  uSEC, 10
      JMP sendCont

      send1:
      LDI  uSEC,  6
      CALL Delay
      LDI  uSEC, 64

      sendCont:
      SBBO Msk1, DeAd, SDO, 4   // write set data out --> HIGH
      CALL Delay
      ADD  DATC, DATC, 1        // increase counter
    QBGT send8, DATC, 8       // next bit

    ADD  CMD.w2, CMD.w2, 1    // increase pointer for next byte
  sendLoop:
  SWITCH_INP

JMP main_loop

Delay:

#ifndef __PRUW1_MONITOR__

  LDI  UR, 98           // 100 cycles = 1 usec
  delayCnt:
  SUB  UR, UR, 1        // decrease counter
  QBLT delayCnt, UR, 1  // check end

  SUB  uSEC, uSEC, 1    // decrease usec counter
  QBLT Delay, uSEC, 0   // check usec counter
  RET

#else

  LDI  UR, 91           // 100 cycles = 1 usec
  delayCnt:
  SUB  UR, UR, 1        // decrease counter
  QBLT delayCnt, UR, 1  // check end

  LBBO UR, DeAd, DIN, 4*2  // read DATAIN + DATAOUT
  OR   UR, UR, U2          // or both together
  AND  UR, UR, Msk1        // mask our bit
  QBEQ noBit, UR, 0        // skip if zero
  SET  XX.b3, XX.b2        // .b3 data, .b2 bit counter
  noBit:
  ADD  XX.b2, XX.b2, 1        // increase bit counter
  QBGT NoOpps, XX.b2, 8       // if no overflow, continue
  SBCO XX.b3, DRam, XX.w0, 1  // .w0 memory pointer
  LDI  XX.w2, 0               // reset data and bit counter
  ADD  XX.w0, XX.w0, 1        // increase memory pointer
  QBBC delayCont, XX.w0, 13   // check upper bound
  LDI  XX, LOG_BASE*4         // reset memory pointer
  JMP  delayCont

  NoOpps:
  OR   UR, UR, UR
  OR   UR, UR, UR
  OR   UR, UR, UR
  OR   UR, UR, UR
  OR   UR, UR, UR
  OR   UR, UR, UR

  delayCont:
  ADD  MonC, MonC, 1    // increase bit counter
  SUB  uSEC, uSEC, 1    // decrease usec counter
  QBLT Delay, uSEC, 0   // check usec counter
  RET

#endif
