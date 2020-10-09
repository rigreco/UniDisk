*
*    Unidisk 3.5 RAM Zero Page Memory Dump <beta>
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
LowMain  	equ $000A
HiMain  	equ $000B
*** Monitor routines ***
COut  		equ $FDED ;Console output ASCII
CROut  		equ $FD8E ;Carriage return
PRbyte  	equ $FDDA ;Print byte in hex
** Command Code **
StatusCmd  	equ 0
** Status Code **
StatusDIB  	equ 3
StatusUNI  	equ 5
*
ControlCmd  equ 4
** Control Codes **
Run  		equ 5
SetDWLoad  	equ 6
DWLoad  	equ 7
*
  			org $8000
*
* Find a Protocol Converter in one of the slots.
*
  		jsr FindPC
  		bcs Error
*
*** Set HiMain Memory Pointers ***
  		lda #$20
  		sta HiMain
*** Set Address ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw SET_ADD
*** Download ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw DOWNLOAD
*** Set and Reset LoMain Memory Counter ***
RESET  		ldx #$FF ;One more before start
  		clc
  		ldy Y_reg
  		iny
  		sty Y_reg
*** Execute ***
EXEC  		inx
  		stx LowMain
 		stx X_reg
  		jsr Dispatch
  		dfb ControlCmd
  		dw EXE
READ  		jsr Dispatch
  		dfb StatusCmd
  		dw DParms
 		bcs Error
*
*** Accumulator ***
   		lda UNIAcc_reg
  		jsr PRbyte
*** X Register ***
  		lda UNIX_reg
  		jsr PRbyte
*** Y Register ***
  		lda UNIY_reg
  		jsr PRbyte
*** Process Status ***
  		lda UNIP_val
  		jsr PRbyte
  		jsr CROut
**** Store in //c Main Memory ****
  		ldx X_reg
  		lda UNIAcc_reg ;#$FB Test
  		ldy #0
  		sta (LowMain),y
  		cpx UNIL_End
  		bne EXEC
UNIL_End  	dfb $C0 ;$FF
*** Increment HiMain ***
  		inc HiMain
  		ldy Y_reg
  		cpy UNIH_End
  		bne RESET
UNIH_End  	dfb $00 ;$FF
*
  		rts
*
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
*
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
*
* There are the PC signature bytes in their relative order.
* The $FF bytes are filler bytes and are not compared.
*
sigtab  	dfb $FF,$20,$FF,$00
  		dfb $FF,$03,$FF,$00
*
Dispatch  	equ *
  		jmp (ZPTempL) ;Simulate an indirect JSR to PC
*** Status Parameter Set ***
DParms  	equ *
DPParmsCt  	dfb 3 ;Status calls have three parameters
DPUnit  	dfb 1
DPBuffer  	dw UNI
DPStatCode  	dfb StatusUNI
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
HHH    		dfb  0
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
*
******** CONTROL LISTS ********
*
*
*** Execute ***
CNTL_LIST2  	equ *
Clow_byte  	dfb $06
Chigh_byte  	dfb $00
AccValue  	dfb $00
X_reg  		dfb $00 ;($80E3)
Y_reg  		dfb $FF ;($80E4) One more before start
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
LenghtL_byte  	dfb $0B
LenghtH_byte  	dfb $00
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