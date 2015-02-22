* @com.wudsn.ide.asm.hardware=APPLE2
************************************
* 	BASIC TO FAC TO FP1        *
*          X=NUMBER		   *
*          CALL 2048,X             *
************************************
		org $800
		
CHKCOM		equ $DEBE
FRMNUM		equ $DD67

** Woz FP Accumulator 4 Byte + 1 Byte Extra + 1 Byte SIGN**
FP1		equ $FA	;Translate F8 --> FA
E		equ $FE ;Translate FC --> FE
SIGN		equ $EB

** Applesoft FP Accumulator 5 Byte + 1 Byte Sign **
FAC		equ $9D

		***************************

ENTRY		jsr CHKCOM
		jsr FRMNUM	;VARIABLE X ->FAC

** FP1 to FAC conversion (conversion not yet) **

		lda FAC
		dec A
		sta FP1
		
		lda FAC+1
		eor #$80
		lsr
		sta FP1+1
		
		lda FAC+2
		sta FP1+2
		
		lda FAC+3
		sta FP1+3
		
		lda FAC+3
		sta E
		
		lda FAC+4
		sta SIGN
		
		brk