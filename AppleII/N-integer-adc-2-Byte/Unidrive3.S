*
*    Unidisk 3.5 Unidirve3.s <beta>
*
*	 "TWO BYTE SUM OF FIRST N INTEGER NUMBER 1+2+3+...+(N-1)+N"
*    SUM1N.bas
*	 UNIFUN3.bas
*	
*	 The target of this project is to use the Unidisk 3.5 drive to perform
*    specific numerical routines: "2 Byte Add of the first N integer numbers calculation";
*    in order to use it as a Apple II co-processor unit.
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
* Protocol Converter Call
			XC 			; Enable 65C02 INSTRUCTION
          	TYP $06		; Binary File Type ignored in Merlin32 (Merlin 16+ RETRO compatibility)
          	*AUX $8000  ; Auxiliary Type

ZPTempL  	equ $0006 ;Temporary zero page storage
ZPTempH  	equ $0007
** Zero page storage **
N1			equ $19 ;25
* N2		equ $1B ;27 Previus set from program "2 Byte Add integer numbers calculation" (Unidrive2.s)
RSLT		equ $1D ;29
*** Monitor routines ***
COut  		equ $FDED ;Console output ASCII
CROut  		equ $FD8E ;Carriage return
** Command Code **
StatusCmd  	equ 0
** Status Code **
* StatusDIB equ 3
StatusUNI  	equ 5
*
ControlCmd 	equ 4
** Control Codes **
Eject  		equ 4
Run  		equ 5
SetDWLoad  	equ 6
DWLoad  	equ 7
*
  		org $8000
*****************************************************
*
* Find a Protocol Converter in one of the slots.
START  	jsr FindPC
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
* There's either no PC around, or there was no give message
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
Message asc 'NO PC OR NO DEVICE'
		dfb $8D,0
*********************************************   		
*
** Set the Input Value first **
EXEC  	lda N1
		sta $8111 ; Absolute addressing
		lda N1+1
		sta $8112	
	*** Download ***
		jsr Dispatch
		dfb ControlCmd
		dw DOWNLOAD		
	** Execute **
		jsr Dispatch
		dfb ControlCmd
		dw EXE
READ  	jsr Dispatch
		dfb StatusCmd
		dw DParms
		bcs Error
*
**** Store Output results in //c ****
*		
		lda UNIX_reg
		sta RSLT ; Store the result
		lda UNIY_reg
		sta RSLT+1 
*
		rts
*
******************************************************
* Find Protocol Converter sub
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
DPStatCode  dfb StatusUNI
*
*
*
*** Status List UNI ***
UNI  		equ *
			dfb 0
UNIError  	dfb 0
UNIRetries  dfb 0
UNIAcc_reg  dfb 0
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
*** Eject ***
CNTL_LIST1  	equ *
			dw $0000
*
*** Execute ***
CNTL_LIST2  	equ *
Clow_byte  	dfb $06
Chigh_byte  dfb $00
AccValue  	dfb $00 ; Input Value
X_reg  		dfb $00 ; Input Value (N1)
Y_reg  		dfb $00 ; Input Value (N2)
ProStatus  	dfb $00 ; Input Value
LowPC_reg  	dfb $05 ; Like ORG: set the initial value of Unidisk Program Counter register
HighPC_reg  dfb $05 ; to start entry point of downoladed program
*
*** Set Address ***
CNTL_LIST3  	equ *
CountL_byte dfb $02
CountH_byte dfb $00
LByte_Addr  dfb $05 ; Like ORG
HByte_Addr  dfb $05
*
*** Download ***
CNTL_LIST4  	equ *
LenghtL_byte 	dfb $4A ;<----- Lenght of Unidisk program Lo Byte
LenghtH_byte 	dfb $00 ;<----- Lenght of Unidisk program Hi Byte
*
*** Start UNIDISK Program ***
** Two byte adc **
		org $0505
RSLTU		equ $C0
NDEC		equ $C2
N			equ $C4

** Save the N number **
		lda N1U
		sta N
		lda N1U+1
		sta N+1
** Set RSLTU=N **		
		lda N
		sta RSLTU ; N Lo
		lda N+1
		sta RSLTU+1 ; N Hi
		
LOOP	lda N
		
		beq HI ; If NLo =0 dec NHi

** Set NDEC=N-1 Lo **		
		dec A
		sta NDEC ; N-1 Lo
** Set NDEC=N Hi **				
		lda N+1
		sta NDEC+1 ; NHi = NDEC Hi
		
		jmp ENTRY
		
** Set NDEC=N-1 Hi **		
HI		lda N+1

		beq DONE ; If also NHi =0 done

		dec A
		sta NDEC+1 ; N-1 Hi		
		
		lda #$FF
		sta NDEC ; N-1 Lo = FF Set NDEC to FF

ENTRY  		clc

		lda RSLTU ; Lo Byte
		adc NDEC  ; N+(N-1)
		sta RSLTU

		lda RSLTU+1 ; Hi Byte
		adc NDEC+1  ; N+(N-1)
  		sta RSLTU+1

** Update N=NDEC **  		
		lda NDEC
		sta N
		lda NDEC+1
		sta N+1

		jmp LOOP

** Output Data **					 		
DONE	ldx RSLTU
		ldy RSLTU+1
		
		rts
  	
** Input Dynamic Data append in the end of Unidisk routine **  		
N1U		dfb $00
		dfb $00