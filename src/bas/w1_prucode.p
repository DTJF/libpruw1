
//  compile for .bi output
//    pasm -V3 -y -CPru_W1 w1_prucode.p

#define CMD_TRIP  1
#define CMD_RESET 10
#define CMD_RECV  20
#define CMD_SEND  30

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
#define CMD r6

#define OE r10
#define UR r11
#define U2 r12

// DRam:
// 00 CMD
// 04 DeAd
// 08 Msk1
// 0C FE
// 10 Data
// 100 Debug (pin P9_14)

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

#define XX r8
.origin 0
LDI  XX, 0x100

ZERO &r0, 4             // clear register R0
MOV  DeAd, 0x22020      // load address
SBBO r0, DeAd, 0, 4     // make C24 point to 0x0 (this PRU DRAM) and C25 point to 0x2000 (the other PRU DRAM)

LBCO DeAd, DRam, 0x04, 4*2 // load device adress and Msk1
MOV  Msk0, 0xFFFFFFFF
XOR  Msk0, Msk0, Msk1

SWITCH_INP

main_loop:
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
  //LBCO DAT, DRam, 0x10, 4  // load 4 byte from array
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
  LDI  UR, 100          // 100 cycles = 1 usec
  delayCnt:
  SUB  UR, UR, 1        // decrease counter
  QBLT delayCnt, UR, 1  // check end

  LBBO UR, DeAd, DIN, 4 // read DATAIN
  QBBC noBit, UR, 18
  SET  XX.b3, XX.b2     // .b3 data, .b2 bit counter
  noBit:
  ADD  XX.b2, XX.b2, 1
  QBGT delayCont, XX.b2, 8
  SBCO XX.b3, DRam, XX.w0, 1  // .w0 memory pointer
  LDI  XX.w2, 0               // reset data and bit counter
  ADD  XX.w0, XX.w0, 1
  QBBC delayCont, XX.w0, 13
  LDI  XX, 0x100

  delayCont:

  SUB  uSEC, uSEC, 1    // decrease usec counter
  QBLT Delay, uSEC, 0   // check usec counter
  RET
