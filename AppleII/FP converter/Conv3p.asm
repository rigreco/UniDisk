* @com.wudsn.ide.asm.hardware=APPLE2
************************************
* 	BASIC TO FAC TO FP1        *
*          X=NUMBER		   *
*          CALL 32768,X 768,X      *
************************************
		org $8000
		
CHKCOM		equ $DEBE
FRMNUM		equ $DD67
PTRGET		equ $DFE3
MOVMF		equ $EB2B
MOVFM		equ $EAF9

** Woz FP Accumulator 4 Byte + 1 Byte Extra + 1 Byte SIGN**
FP1		equ $FA	;Translate F8 --> FA
E		equ $FE ;Translate FC --> FE
SIGN		equ $EB

FP2		equ $EC

** Applesoft FP Accumulator 5 Byte + 1 Byte Sign **
FAC		equ $9D

** Variabile Memory location $0380 **

		***************************

ENTRY1		jsr CHKCOM
		jsr FRMNUM	;VARIABLE X ->FAC (6 Byte Unpacked)

** FPC to FP1 conversion **

		lda FAC
		dec A		; dec the EXP
		sta FP1
		sta FP2 ; Copy
		
		lda FAC+5
		bmi NEG		; chk the Hi bit of 1 byte Mantissa

POS		clc		; Hi bit 0 for negative
		lda FAC+5
		
		ora #$80	; Set Hi Bit 1 byte Mantissa (change Sign only if is positive)
		ror		; Didide for 2^1
		
		sta FP1+1
		sta FP2+1 ; Copy
		
		jmp CONT

NEG		clc		; Hi bit 1 for positive
		lda FAC+5
		
		ror		; Didide for 2^1
		
		eor #$FF	; One's complement, NOT
		clc
		adc #01		; Two's complement, +1
		
		sta FP1+1
		sta FP2+1 ; Copy		
		
CONT		lda FAC+2
		ror
		sta FP1+2
		sta FP2+2 ; Copy
		
		lda FAC+3
		ror
		sta FP1+3
		sta FP2+3 ; Copy FP2=FP1 X2=X1
		
		lda FAC+4
		ror
		sta E
	
		;brk
		rts

************************************
* 	FP1 TO FAC TO BASIC        *
*          CALL 32831,Y 831,Y 	   *
*	   PRINT Y		   *
************************************

*
** FP1 to FAC conversion **
*
ENTRY2		lda FP1		; X1 1 Byte --> 9D FAC
		inc A		; 2^(FP1+1) inc EXP
		sta FAC
		
		lda FP1+1
		bmi NEG2	; chk the Hi bit of 1 byte Mantissa
		
		
POS2		clc
		lda FP1+1	; M1 Hi 2 Byte --> 9E FAC
		rol		; Multiply for 2^1
		
		ora #$80	; Set Hi Bit 1 byte Mantissa (change Sign only if is positive)
		sta FAC+1	; To 6^ Byte of FAC Unpacked
		
		;sta FAC+5	; To 1^ Byte Mantissa of FAC UnPacked
		jmp CONT2

NEG2		lda FP1+1

		sec			
		sbc #01		; One's complement inv -1
		eor #$FF	; Two's complement inv NOT

		rol		; Multiply for 2^1
		
		sta FAC+1	; To 1^ Byte Mantissa of FAC Packed
		sta FAC+5	; To 6^ Byte of FAC Unpacked		
		
		
CONT2		lda FP1+2	; M1 3 Byte --> 9F FAC
		rol
		sta FAC+2
		
		lda FP1+3	; M1 Lo 4 Byte --> A0 FAC
		rol
		sta FAC+3
		
		lda E		; Extra 5 Byte --> A1 FAC
		rol
		sta FAC+4
		
		;brk
		***************************
* 
		;ldy #$03 	;Hi Byte MEM
		;lda #$80 	;Lo Byte MEM
*
		jsr CHKCOM
		jsr PTRGET	; Return the Y and A pointing to the specific variabile
		tax
		jsr MOVMF	;FAC->VARIABLE Y (5 Bytes Packed)
		
		;brk
		rts