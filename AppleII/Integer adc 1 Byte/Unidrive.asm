* @com.wudsn.ide.asm.hardware=APPLE2
* Protocol Converter Call
		XC
ZPTempL  	equ $0006 ;Temporary zero page storage
ZPTempH  	equ $0007
N1		equ $0A
N2		equ $0B
RSLT		equ $0C
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
Eject  		equ 4
Run  		equ 5
SetDWLoad  	equ 6
DWLoad  	equ 7
*
  		org $8000
*****************************************************
* Presentation message **************
*
*  		ldx #0
* LOOP  		equ *
*  		lda DATA,x
*  		beq ME2
*  		jsr COut
*  		inx
*  		bne LOOP
*
* DATA	  	asc 'UNIDISK 3.5 UTILITY BY R. GRECO'
*		dfb $8D,0 ; Inverse mode on
*
* ME2  		jsr CROut
*		jsr CROut
*
*		ldx #0
* LOOP2  		equ *
*  		lda DATA2,x
*  		beq START
*  		ora #$80
*  		jsr COut
*  		inx
*  		bne LOOP2
*
* DATA2	  	asc 'A    X  Y    P'
*		dfb $8D,0 ; Inverse mode on
*****************************************************
*
* Find a Protocol Converter in one of the slots.
START  		jsr FindPC
  		bcs Error
		
		jsr CROut
** Wait keypress to continue **
*
*		jsr KEYIN
*		
*** Eject ***
 		jsr Dispatch
 		dfb ControlCmd
 		dw E_JECT 		
*** Set Address ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw SET_ADD
*** Download ***
  		jsr Dispatch
  		dfb ControlCmd
  		dw DOWNLOAD
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
Message  	asc 'NO PC OR NO DEVICE'
  		dfb $8D,0
*********************************************   		
*
** Set the Input Value first **
EXEC  		lda #$00
		sta AccValue
		lda N1
		sta X_reg
		lda N2
		sta Y_reg
** Execute **			
		jsr Dispatch
  		dfb ControlCmd
  		dw EXE
READ  		jsr Dispatch
  		dfb StatusCmd
  		dw DParms
  		bcs Error
*
**** Screen Output ****
*		
*** Accumulator ***
   		lda UNIAcc_reg
   		sta RSLT ; Store the result
*  		jsr PRbyte
*  		ldx #03 ; Set 3 space
*  		jsr PRBL2
*** X Register ***
*		lda UNIX_reg
*  		jsr PRbyte
*  		ldx #01 ; Set one space
*  		jsr PRBL2
*** Y Register ***
*  		lda UNIY_reg
*  		jsr PRbyte
*  		ldx #03 ; Set one space
*		jsr PRBL2
*** Process Status ***
*  		lda UNIP_val
*  		jsr PRbyte
*  		ldx #05 ; Set five space
*  		jsr PRBL2
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
AccValue  	dfb $00 ; Input Value
X_reg  		dfb $00 ; Input Value (N1)
Y_reg  		dfb $00 ; Input Value (N2)
ProStatus  	dfb $00
LowPC_reg  	dfb $05 ; Like ORG
HighPC_reg  	dfb $05
*
*** Set Address ***
CNTL_LIST3  	equ *
CountL_byte  	dfb $02
CountH_byte  	dfb $00
LByte_Addr  	dfb $05 ; Like ORG
HByte_Addr  	dfb $05
*
*** Download ***
CNTL_LIST4  	equ *
LenghtL_byte  	dfb $09 ;<----- Lenght of Unidisk program Lo Byte
LenghtH_byte  	dfb $00 ;<----- Lenght of Unidisk program Hi Byte
*
*** Start UNIDISK Program ***

  		stx $C0
  		sty $C1

  		lda $C0
  		adc $C1
  		
  		rts