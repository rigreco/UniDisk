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
		XC
** CHKSUM Pointer *
PTR		equ $08
** Protocol Converter Call
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
StatusUNI  	equ 5
*
ControlCmd 	equ 4
** Control Codes **
Run  		equ 5
SetDWLoad  	equ 6
DWLoad  	equ 7
*
  		org $6000
*****************************************************
************** CHKSUM MAIN Routine ******************
*
;STARTCHK	lda	#<STARTCHK
;		sta	PTR
;		lda	#>STARTCHK
;		sta	PTR+1
;		ldy	#$00
;		lda	#$00
;		pha
;LOOP		pla
;		eor	(PTR),y
;		pha
;		inc	PTR
;		bne	CHK
;		inc	PTR+1
;CHK		lda	PTR+1
;		cmp	#>PROGEND
;		bcc	LOOP
;		lda	PTR
;		cmp	#<PROGEND
;		bcc	LOOP
;		beq	LOOP
;CHKCS		pla
;		cmp	CHKSUM
;		bne	ERRCHK
***********************************************
* Find a Protocol Converter in one of the slots.
START  		jsr FindPC
  		bcs Error
*** Set Address ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw SET_ADD
*  		
  		jsr EXEC ; Jump the Error routine
		rts
**************** CHKSUM ERROR Routine ***************
*
;ERRCHK		sta CHKCALC
;		lda #"E"
;		jsr COut
;		rts
;CHKCALC	dfb	$00
**************** PROTOCOL CONVERTER ERROR Routine ***
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
*******************************************************   		
*

** Set the Input Value first in Dynamic data **
		** 4 Byte N1 to FP1 **
EXEC  		lda N1	  	;X1
		sta FP1 	; Absolute addressing
		lda N1+1	;M1 (1)
		sta FP1+1
		lda N1+2	;M1 (2)
		sta FP1+2
		lda N1+3	;M1 (3)
		sta FP1+3
				
		** 4 Byte N2 to FP2 **
		lda N2		;X2
		sta FP2
		lda N2+1	;M2 (1)
		sta FP2+1
		lda N2+2	;M2 (2)
		sta FP2+2
		lda N2+3	;M2 (3)
		sta FP2+3
			
*** Download ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw DOWNLOAD
** Set Unidisk Registers **
		;First time execution
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
*		lda #$3C      ; Target the secont time entry point
*		sta LowPC_reg ; Second time set new value of PC
** Execute **			
*		jsr Dispatch
*  		dfb ControlCmd
*  		dw EXE
** Read **  		
* 		jsr Dispatch
*  		dfb StatusCmd
*  		dw DParms
*  		bcs Error
  				 		
* 		Second time execute only to read the latest Byte of FP1*
*		lda UNIAcc_reg
*		sta RSLT+3		 
*
PROGEND		rts
CHKSUM		chk
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
*
******** CONTROL LISTS ********
*
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
LByte_Addr  	dfb $30 ; ORG of Unidisk program, set begin data address $062E
HByte_Addr  	dfb $06
*
*** Download ***
CNTL_LIST4  	equ *
LenghtL_byte  	dfb $08 ;<----- Lenght of Unidisk program Lo  - Byte 312 byte
LenghtH_byte  	dfb $00 ;<----- Lenght of Unidisk program Hi Byte
*
**************** Start UNIDISK Program ****************
*

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
**************** End UNIDISK Program ****************        	          	