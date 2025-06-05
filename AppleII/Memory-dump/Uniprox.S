*
*    Unidisk 3.5 ROM Memory Dump <beta>
*
*    The target of this project is to dump all the Unidisk 3.5 memory
*
*    Copyright (C) 2014  Riccardo Greco <rigreco.grc@gmail.com>.
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
* Protocol Converter Call
			XC 			; Enable 65C02 INSTRUCTION
          	TYP $06		; Binary File Type ignored in Merlin32 (Merlin 16+ RETRO compatibility)
          	*AUX $8000  ; Auxiliary Type			  

ZPTempL  	equ $0006 ;Temporary zero page storage
ZPTempH  	equ $0007
*** Pointers ***
LowMain  	equ $000A ; Pointer to low byte of main memory address
HiMain  	equ $000B ; Pointer to high byte of main memory address
*** Monitor routines ***
COut  		equ $FDED ;Console output ASCII
COUT1		equ $FDF0 ;Output to screen
CROut  		equ $FD8E ;Carriage return
PRbyte  	equ $FDDA ;Print byte in hex
PRBL2		equ $F94A ;Print many spaces
KEYIN		equ $FD1B ;Waits for keypress
** Command Code **
StatusCmd  	equ 0
** Status Code **
StatusDIB  	equ 3
StatusUNI  	equ 5
*
ControlCmd 	equ 4
** Control Codes **
Eject  		equ 4 ;Control code for ejecting disk
Run  		equ 5 ;Control code for running program on Unidisk
SetDWLoad  	equ 6 ;Control code for setting download address on Unidisk
DWLoad  	equ 7 ;Control code for downloading data to Unidisk
*
  			org $8000
*****************************************************
* Presentation message loop to display message on screen using COut routine **************
*
  		ldx #0
LOOP  		equ *
  		lda DATA,x
  		beq START
  		jsr COut
  		inx
  		bne LOOP
*
DATA	asc 'UNIDISK 3.5 UTILITY BY R. GRECO'
		dfb $8D,0 ; Inverse mode on
*****************************************************
*
* Find a Protocol Converter in one of the slots.
START  	jsr FindPC
  		bcs Error
  		
		jsr CROut
		jsr CROut
*
* Now make the DIB call to the first guy
*
		jsr Dispatch
		dfb StatusCmd
		dw DParmsDIB
		bcs Error
*
* Got the DIB; now print the name string
*
        		ldx #0
morechars  	equ *
 		lda DIBName,x
		ora #$80 ;COut wants high Bit set
 		jsr COut ; ASCII
 		inx
 		cpx DIBNameLen
 		bne morechars
************************************* 		
 		ldx #02 ; Set 2 space
  		jsr PRBL2
** Print Type ***********************		
 		lda DIBType
 		jsr PRbyte ; HEX form
*************************************		
		ldx #02 ; Set 2 space
  		jsr PRBL2
** Print Firmware version ***********
 		ldx #0
morechars2  	equ *
 		lda DIBVersion,x
		jsr PRbyte ; HEX form
 		inx
 		cpx #$02 ; 2 Byte
 		bne morechars2
 		jsr COut
************************************** 		
		jsr CROut
		jsr CROut
** Wait keypress to continue **
*
		jsr KEYIN
*		
*** Eject ***
 		jsr Dispatch
 		dfb ControlCmd
 		dw E_JECT 		
*** Set start HiMain Memory Pointers ***
  		lda #$20 ; Hi Byte start (//c ram)
  		sta HiMain ; HiMain=$20 set
*** Set Address ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw SET_ADD
*** Download ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw DOWNLOAD
*  		
  		jsr RESET ; Jump the Error routine
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
Message  	asc 'NO PC OR NO DEVICE'
  		dfb $8D,0
*********************************************   		
  		
*** Set and Reset LoMain Memory Counter ***
RESET  		ldx #$FF ;Lo Byte start One more before $00 (//c ram)
  		clc
  		ldy Y_reg ; 1 time $DF --> Y
  		iny	  ; Y+ --> $FF	
  		sty Y_reg ; Y --> Y_reg Uni=$FF
*** Execute ***
EXEC  		inx
  		stx LowMain ; 1 time set LowMain=$00 
  		stx X_reg
  		jsr Dispatch
  		dfb ControlCmd
  		dw EXE
*** Read ***  		
READ  		jsr Dispatch
  		dfb StatusCmd
  		dw DParms
  		bcs Error
*
**** Screen Output ****
*		
*** Accumulator ***
   		lda UNIAcc_reg
  		jsr COut  ; Out the ASCII value
  		ldx #03 ; Set 3 space
  		jsr PRBL2
*** Y Register ***
  		lda UNIY_reg
  		jsr PRbyte
*** X Register ***
		lda UNIX_reg
  		jsr PRbyte
  		ldx #01 ; Set one space
  		jsr PRBL2
*** Process Status ***
  		lda UNIP_val
  		jsr PRbyte
  		ldx #05 ; Set five space
  		jsr PRBL2
** //c Memory store adress **
  		lda HiMain
  		jsr PRbyte
  		lda LowMain
  		jsr PRbyte
  		jsr CROut
**** Store in //c Main Memory ****
  		ldx X_reg
  		lda UNIAcc_reg ;#$FB Test
  		ldy #0
  		sta (LowMain),y
  		cpx UNIL_End
  		bne EXEC
UNIL_End  	dfb $FF ; Lo Byte stop (Unidisk) - $C0 for zero page
*** Increment HiMain ***
  		inc HiMain
  		ldy Y_reg
  		cpy UNIH_End
  		bne RESET
UNIH_End  	dfb $FF ; Hi Byte stop (Unidisk) - $00 for zero page
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
*** Status Parameter Set for DIB ***
DParmsDIB  	equ *
DPParmsCt2  	dfb 3 ;Status calls have three parameters
DPUnit2  	dfb 1
DPBuffer2  	dw DIB
DPStatCode2  	dfb StatusDIB
*
*
*** Status List DIB ***
DIB  		equ *
DIBStatByte1  	dfb 0
DIBDevSize  	dfb 0,0,0
DIBNameLen  	dfb 0
DIBName  	ds 16,0
DIBType  	dfb 0
DIBSubType  	dfb 0
DIBVersion  	dw 0
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
AccValue  	dfb $00
X_reg  		dfb $00 ;($80E3) Lo Byte start $00 (Unidisk)
Y_reg  		dfb $DF ;($80E4) Hi Byte One more before start $E0 - $FF-->$00 for zero page (Unidisk)
ProStatus  	dfb $00
LowPC_reg  	dfb $05
HighPC_reg  	dfb $05
*
*** Set Address ***
CNTL_LIST3  	equ *
CountL_byte  	dfb $02
CountH_byte  	dfb $00
LByte_Addr  	dfb $05
HByte_Addr  	dfb $05
*
*** Download ***
CNTL_LIST4  	equ *
LenghtL_byte  	dfb $0B ;<----- Lenght of Unidisk program Lo Byte
LenghtH_byte  	dfb $00 ;<----- Lenght of Unidisk program Hi Byte
*
*** Start UNIDISK Program ***
** Temporaney save in UNIDISK "Free zero page space" the address point stored in UNIDISK X, Y registers**  
  		stx $00C0
  		sty $00C1
** Store in UNIDISK Accumulator the value of the UniDISK location that is store in $00C0 plus $00C1  		
  		ldy #0
  		lda ($00C0),y
** Restore the value of Y Unidisk register 
  		ldy $00C1
  		rts