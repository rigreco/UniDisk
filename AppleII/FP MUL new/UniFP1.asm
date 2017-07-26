*
*    Unidisk 3.5 Driver <alfa>
*
*    The target of this project is to use the Unidisk 3.5 drive to perform
*    specific numerical routines (integers and floating point numbers)
*    calculation in order to use it as a Apple II co-processor unit.
*
*    Copyright (C) 2015  Riccardo Greco <rigreco.grc@gmail.com>.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*
* @com.wudsn.ide.asm.hardware=APPLE2
*
* Protocol Converter Call
		XC
ZPTempL  	equ $0006 ;Temporary zero page storage
ZPTempH  	equ $0007
** Zero page storage **
N1		equ $FA ;25  4 Byte FP FA--FD (FP1)
N2		equ $EC ;27  4 Byte FP EC--EF (FP2)
RSLT		equ $1D ; $7000 ;29
*** Monitor routines ***
COut  		equ $FDED ;Console output ASCII
CROut  		equ $FD8E ;Carriage return
** Command Code **
StatusCmd  	equ 0
** Status Code **
* StatusDIB  	equ 3
StatusUNI  	equ 5
*
ControlCmd 	equ 4
** Control Codes **
Eject  		equ 4
Run  		equ 5
SetDWLoad  	equ 6
DWLoad  	equ 7
*
  		org $6000
*****************************************************

*
* Find a Protocol Converter in one of the slots.
START  		jsr FindPC
  		bcs Error
*** Eject ***
 		jsr Dispatch
 		dfb ControlCmd
 		dw E_JECT 		
*** Set Address ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw SET_ADD
*  		
  		jsr EXEC ; Jump the Error routine
		rts
*********************************************
Error  		equ *
*
* There is either no PC around, or there was no give message
*
  		ldx #0
err1  		equ *
  		lda Message,x
  		beq errout
  		jsr COut
  		inx
  		bne err1
*
errout  	equ *
  		rts
*
Message  	asc 'NO PC OR NO DEVICE'
  		dfb $8D,0
*********************************************   		
*

** Set the Input Value first in Dynamic data **
		** 4 Byte N1 to FP1 **
EXEC  		lda N1	  	;X1
		sta $6232	; Absolute addressing
		lda N1+1	;M1 (1)
		sta $6233
		lda N1+2	;M1 (2)
		sta $6234
		lda N1+3	;M1 (3)
		sta $6235
				
		** 4 Byte N2 to FP2 **
		lda N2		;X2
		sta $6236
		lda N2+1	;M2 (1)
		sta $6237
		lda N2+2	;M2 (2)
		sta $6238
		lda N2+3	;M2 (3)
		sta $6239
			
*** Download ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw DOWNLOAD
** Set Unidisk Registers **
*		;First time execution
		lda #$00      ; Target the first time entry point
		sta LowPC_reg ; First time set init value of PC, just for the next execution
* The program begin to PC preset to $0500 *
* 				
** Execute **			
		jsr Dispatch
  		dfb ControlCmd
  		dw EXE
** Read **  		
READ  		jsr Dispatch
  		dfb StatusCmd
  		dw DParms
  		bcs Error
*
**** Store Output results in //c ****

*		First time execute *
   		* lda UNIAcc_reg
   		* sta RSLT
   		lda UNIX_reg
   		sta RSLT ; Store the result
  		lda UNIY_reg
  		sta RSLT+1
  		
** Second time execute **		
		lda #$3C      ; Target the secont time entry point
		sta LowPC_reg ; Second time set new value of PC
** Execute **			
		jsr Dispatch
  		dfb ControlCmd
  		dw EXE
** Read **  		
 		jsr Dispatch
  		dfb StatusCmd
  		dw DParms
*  		bcs Error
  				 		
* 		Second time execute only to read the latest Byte of FP1*
		lda UNIAcc_reg
		sta RSLT+3		 
*
  		rts

******************************************************
FindPC  	equ *
*
* Search slot 7 to slot 1 looking for signature bytes
*
  		ldx #7 ;Do for seven slots
  		lda #$C7
  		sta ZPTempH
  		lda #$00
  		sta ZPTempL
*
newslot  	equ *
  		ldy #7
*
again  		equ *
  		lda (ZPTempL),y
  		cmp sigtab,y ;One for byte signature
  		beq maybe ;Found one signature byte
  		dec ZPTempH
  		dex
  		bne newslot
*
* if we get here, no PC find
  		sec
  		rts
*
* if we get here, no byte find on PC
maybe  		equ *
  		dey
  		dey ;if N=1 then all sig bytes OK
  		bpl again
* Found PC interface. Set up call address.
* we already have high byte ($CN), we need low byte
*
foundPC  	equ *
  		lda #$FF
  		sta ZPTempL
  		ldy #0 ;For indirect load
  		lda (ZPTempL),y ;Get the byte
*
* Now the Acc has the low oreder ProDOS entry point.
* The PC entry is three locations past this ...
*
  		clc
  		adc #3
  		sta ZPTempL
*
* Now ZPTempL has PC entry point.
* Return with carry clear.
*
  		clc
 		rts
***********************************************************
*
* There are the PC signature bytes in their relative order.
* The $FF bytes are filler bytes and are not compared.
*
sigtab  	dfb $FF,$20,$FF,$00
  		dfb $FF,$03,$FF,$00
*
Dispatch  	equ *
  		jmp (ZPTempL) ;Simulate an indirect JSR to PC
*
*** Status Parameter Set for UNI ***
DParms  	equ *
DPParmsCt  	dfb 3 ;Status calls have three parameters
DPUnit  	dfb 1
DPBuffer  	dw UNI
DPStatCode  	dfb StatusUNI
*
*
*
*** Status List UNI ***
UNI  		equ *
  		dfb 0
UNIError  	dfb 0
UNIRetries  	dfb 0
UNIAcc_reg  	dfb 0
UNIX_reg  	dfb 0
UNIY_reg  	dfb 0
UNIP_val  	dfb 0
HHH    		dfb 0
*
*** Set Address ***
SET_ADD  	equ *
  		dfb 3
  		dfb 1
  		dw CNTL_LIST3
  		dfb SetDWLoad
*
*** Download ***
DOWNLOAD  	equ *
  		dfb 3
  		dfb 1
  		dw CNTL_LIST4
  		dfb DWLoad
*
*** Execute ***
EXE  		equ *
  		dfb 3
 		dfb 1
  		dw CNTL_LIST2
  		dfb Run
*** Eject ***
E_JECT  	equ *
  		dfb 3
  		dfb 1
  		dw CNTL_LIST1
  		dfb Eject
*
******** CONTROL LISTS ********
*
*
*** Eject ***
CNTL_LIST1  	equ *
  		dw $0000
*
*** Execute ***
CNTL_LIST2  	equ *
Clow_byte  	dfb $06
Chigh_byte  	dfb $00
AccValue  	dfb $00 ; Init Value Unidisk Accumulator Register
X_reg  		dfb $00 ; Init Value Unidisk X Register
Y_reg  		dfb $00 ; Init Value Unidisk Y Register
ProStatus  	dfb $00 ; Init Value Unidisk Status Register
LowPC_reg  	dfb $00 ; Init Value Unidisk Program Counter $0500 at eny dowload
HighPC_reg  	dfb $05 ; $05 first execution, $3C second execution
*
*** Set Address ***
CNTL_LIST3  	equ *
CountL_byte  	dfb $02
CountH_byte  	dfb $00
LByte_Addr  	dfb $00 ; ORG of Unidisk program, set begin program address $0500
HByte_Addr  	dfb $05
*
*** Download ***
CNTL_LIST4  	equ *
LenghtL_byte  	dfb $37 ;<----- Lenght of Unidisk program Lo  - Byte 312 byte
LenghtH_byte  	dfb $01 ;<----- Lenght of Unidisk program Hi Byte
*
**************** Start UNIDISK Program ****************
*
		org $0500 ; Start Unidisk program address
		
SIGN      	EQU  $C0	;$EB  ;  $F3

	  	** FP2 4 Bytes ** 
X2       	EQU  $C1	;$EC  ;  $F4
M2        	EQU  $C2	;$ED  ;  $F5 - $F7

	  	** FP1 4 Bytes + E extension **
X1        	EQU  $C5	;$FA  ;  $F8
M1        	EQU  $C6	;$FB  ;  $F9 - $FB
E         	EQU  $C9	;$FE  ;  $FC

OVLOC     	EQU  $C10	;$3F5	;Overflow routine is not implemented at now)

*
** Main program **
*
** Input data to Zero Page **
		
		** FP1 **
		lda FP1
		sta X1
		
		lda FP1+1
		sta M1
		lda FP1+2
		sta M1+1
		lda FP1+3
		sta M1+2
		
		** FP2 **
		lda FP2
		sta X2
		
		lda FP2+1
		sta M2
		lda FP2+2
		sta M2+1
		lda FP2+3
		sta M2+2

************************** Target Function ***********************
*				Y=N*N	   			 *
******************************************************************
*
** Simple MUL y=x*x **
		jsr FMUL	;FMUL ; Call FP routine
		
		jsr FIX		;FIX Call FP to INT routine M1=HI-Byte M1+1=Low-Byte
		
		
*** Output Data result FP1 to Unidisk registers First Time first 3 Byte out ***
		lda X1
		ldx M1
		ldy M1+1
		
		rts
*** Output Data result FP1 to Unidisk registers Second Time latest 1 Byte out ***		
SECOND		lda M1+2 ; Entry point by Program Counter set

		rts		
***************************************************
*
***************** FP Routine *****************
*
      ***********************
      *                     *
      *  APPLE-II FLOATING  *
      *   POINT ROUTINES    *
      *                     *
      *  COPYRIGHT 1977 BY  *
      * APPLE COMPUTER INC. *
      *                     *
      * ALL RIGHTS RESERVED *
      *                     *
      *     S. WOZNIAK      *
      *                     *
      ***********************
*     TITLE "FLOATING POINT ROUTINES for Unidisk memory"
*
          
ADD	  CLC      	;CLEAR CARRY
	  LDX  #$2      ;INDEX FOR 3-BYTE ADD.
ADD1      LDA  M1,X
	  ADC  M2,X     ;ADD A BYTE OF MANT2 TO MANT1
	  STA  M1,X
      	  DEX           ;INDEX TO NEXT MORE SIGNIF. BYTE.
          BPL  ADD1     ;LOOP UNTIL DONE.
          RTS           ;RETURN
MD1       ASL  SIGN     ;CLEAR LSB OF SIGN.
          JSR  ABSWAP   ;ABS VAL OF M1, THEN SWAP WITH M2
ABSWAP    BIT  M1       ;MANT1 NEGATIVE?
          BPL  ABSWAP1  ;NO, SWAP WITH MANT2 AND RETURN.
          JSR  FCOMPL   ;YES, COMPLEMENT IT.
          INC  SIGN     ;INCR SIGN, COMPLEMENTING LSB.
ABSWAP1   SEC           ;SET CARRY FOR RETURN TO MUL/DIV.
SWAP      LDX  #$4      ;INDEX FOR 4 BYTE SWAP.
SWAP1     STY  E-1,X
          LDA  X1-1,X   ;SWAP A BYTE OF EXP/MANT1 WITH
          LDY  X2-1,X   ;EXP/MANT2 AND LEAVE A COPY OF
          STY  X1-1,X   ;MANT1 IN E (3 BYTES).  E+3 USED
          STA  X2-1,X
          DEX           ;ADVANCE INDEX TO NEXT BYTE
          BNE  SWAP1    ;LOOP UNTIL DONE.
          RTS           ;RETURN
FLOAT     LDA  #$8E     ;INIT EXP1 TO 14, <--------------- int to fp
          STA  X1       ;THEN NORMALIZE TO FLOAT.
NORM1     LDA  M1       ;HIGH-ORDER MANT1 BYTE.
          CMP  #$C0     ;UPPER TWO BITS UNEQUAL?
          BMI  RTS1     ;YES, RETURN WITH MANT1 NORMALIZED
          DEC  X1       ;DECREMENT EXP1.
          ASL  M1+2
          ROL  M1+1     ;SHIFT MANT1 (3 BYTES) LEFT.
          ROL  M1
NORM      LDA  X1       ;EXP1 ZERO?
          BNE  NORM1    ;NO, CONTINUE NORMALIZING.
RTS1      RTS           ;RETURN.
FSUB      JSR  FCOMPL   ;CMPL MANT1,CLEARS CARRY UNLESS 0 <---- sub
SWPALGN   JSR  ALGNSWP  ;RIGHT SHIFT MANT1 OR SWAP WITH
FADD      LDA  X2	;<------------------------------------- add
          CMP  X1       ;COMPARE EXP1 WITH EXP2.
          BNE  SWPALGN  ;IF #,SWAP ADDENDS OR ALIGN MANTS.
          JSR  ADD      ;ADD ALIGNED MANTISSAS.
ADDEND    BVC  NORM     ;NO OVERFLOW, NORMALIZE RESULT.
          BVS  RTLOG    ;OV: SHIFT M1 RIGHT, CARRY INTO SIGN
ALGNSWP   BCC  SWAP     ;SWAP IF CARRY CLEAR,
          *       ELSE SHIFT RIGHT ARITH.
RTAR      LDA  M1       ;SIGN OF MANT1 INTO CARRY FOR
          ASL           ;RIGHT ARITH SHIFT.
RTLOG     INC  X1       ;INCR X1 TO ADJUST FOR RIGHT SHIFT
          BEQ  OVFL     ;EXP1 OUT OF RANGE.
RTLOG1    LDX  #$FA     ;INDEX FOR 6:BYTE RIGHT SHIFT.
ROR1      ROR  E+3,X
          INX           ;NEXT BYTE OF SHIFT.
          BNE  ROR1     ;LOOP UNTIL DONE.
          RTS           ;RETURN.
FMUL      JSR  MD1      ;ABS VAL OF MANT1, MANT2 <-------------- mul
          ADC  X1       ;ADD EXP1 TO EXP2 FOR PRODUCT EXP
          JSR  MD2      ;CHECK PROD. EXP AND PREP. FOR MUL
          CLC           ;CLEAR CARRY FOR FIRST BIT.
MUL1      JSR  RTLOG1   ;M1 AND E RIGHT (PROD AND MPLIER)
          BCC  MUL2     ;IF CARRY CLEAR, SKIP PARTIAL PROD
          JSR  ADD      ;ADD MULTIPLICAND TO PRODUCT.
MUL2      DEY           ;NEXT MUL ITERATION.
          BPL  MUL1     ;LOOP UNTIL DONE.
MDEND     LSR  SIGN     ;TEST SIGN LSB.
NORMX     BCC  NORM     ;IF EVEN,NORMALIZE PROD,ELSE COMP
FCOMPL    SEC           ;SET CARRY FOR SUBTRACT. <--------------- not
          LDX  #$3      ;INDEX FOR 3 BYTE SUBTRACT.
COMPL1    LDA  #$0      ;CLEAR A.
          SBC  X1,X     ;SUBTRACT BYTE OF EXP1.
          STA  X1,X     ;RESTORE IT.
          DEX           ;NEXT MORE SIGNIFICANT BYTE.
          BNE  COMPL1   ;LOOP UNTIL DONE.
          BEQ  ADDEND   ;NORMALIZE (OR SHIFT RT IF OVFL).
FDIV      JSR  MD1      ;TAKE ABS VAL OF MANT1, MANT2. <--------- div
          SBC  X1       ;SUBTRACT EXP1 FROM EXP2.
          JSR  MD2      ;SAVE AS QUOTIENT EXP.
DIV1      SEC           ;SET CARRY FOR SUBTRACT.
          LDX  #$2      ;INDEX FOR 3-BYTE SUBTRACTION.
DIV2      LDA  M2,X
          SBC  E,X      ;SUBTRACT A BYTE OF E FROM MANT2.
          PHA           ;SAVE ON STACK.
          DEX           ;NEXT MORE SIGNIFICANT BYTE.
          BPL  DIV2     ;LOOP UNTIL DONE.
          LDX  #$FD     ;INDEX FOR 3-BYTE CONDITIONAL MOVE
DIV3      PLA           ;PULL BYTE OF DIFFERENCE OFF STACK
          BCC  DIV4     ;IF M2<E THEN DON'T RESTORE M2.
          STA  M2+3,X
DIV4      INX           ;NEXT LESS SIGNIFICANT BYTE.
          BNE  DIV3     ;LOOP UNTIL DONE.
          ROL  M1+2
          ROL  M1+1     ;ROLL QUOTIENT LEFT, CARRY INTO LSB
          ROL  M1
          ASL  M2+2
          ROL  M2+1     ;SHIFT DIVIDEND LEFT
          ROL  M2
          BCS  OVFL     ;OVFL IS DUE TO UNNORMED DIVISOR
          DEY           ;NEXT DIVIDE ITERATION.
          BNE  DIV1     ;LOOP UNTIL DONE 23 ITERATIONS.
          BEQ  MDEND    ;NORM. QUOTIENT AND CORRECT SIGN.
MD2       STX  M1+2
          STX  M1+1     ;CLEAR MANT1 (3 BYTES) FOR MUL/DIV.
          STX  M1
          BCS  OVCHK    ;IF CALC. SET CARRY,CHECK FOR OVFL
          BMI  MD3      ;IF NEG THEN NO UNDERFLOW.
          PLA           ;POP ONE RETURN LEVEL.
          PLA
          BCC  NORMX    ;CLEAR X1 AND RETURN.
MD3       EOR  #$80     ;COMPLEMENT SIGN BIT OF EXPONENT.
          STA  X1       ;STORE IT.
          LDY  #$17     ;COUNT 24 MUL/23 DIV ITERATIONS.
          RTS           ;RETURN.
OVCHK     BPL  MD3      ;IF POSITIVE EXP THEN NO OVFL.
OVFL      JMP  OVLOC
*	  ORG  $F63D
FIX1      JSR  RTAR
FIX       LDA  X1 	; <------------------------------ fp to int
          BPL  UNDFL
          CMP  #$8E
          BNE  FIX1
          BIT  M1
          BPL  FIXRTS
          LDA  M1+2
          BEQ  FIXRTS
          INC  M1+1
          BNE  FIXRTS
          INC  M1
FIXRTS    RTS
UNDFL     LDA  #$0
          STA  M1
          STA  M1+1
          RTS
** Input Dynamic Data append in the end of Unidisk routine **  		
FP1		dfb $00
		dfb $00
		dfb $00
		dfb $00
*		
FP2		dfb $00
          	dfb $00
          	dfb $00
          	dfb $00          	