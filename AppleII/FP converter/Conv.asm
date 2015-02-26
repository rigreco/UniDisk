* @com.wudsn.ide.asm.hardware=APPLE2
************************************
* 	BASIC TO FAC TO FP1        *
*          X=NUMBER		   *
*          CALL 768,X             *
************************************
		org $300
		
CHKCOM		equ $DEBE
FRMNUM		equ $DD67
PTRGET		equ $DFE3
MOVMF		equ $EB2B
MOVFM		equ $EAF9

** Woz FP Accumulator 4 Byte + 1 Byte Extra + 1 Byte SIGN**
FP1		equ $FA	;Translate F8 --> FA
E		equ $FE ;Translate FC --> FE
SIGN		equ $EB

** Applesoft FP Accumulator 5 Byte + 1 Byte Sign **
FAC		equ $9D

MEM		equ $0380

		***************************

ENTRY1		jsr CHKCOM
		jsr FRMNUM	;VARIABLE X ->FAC

** FPC to FP1 conversion (conversion not yet) **

		lda FAC
		dec A
		sta FP1
		
		clc
		lda FAC+5
		ora #$80	; Not Hi Bit Mantissa (change Sign only if is positive)
		ror
		sta FP1+1
		
		;clc
		;lda FAC+1
		;ror
		;sta FP1+1
		
		lda FAC+2
		;ror
		sta FP1+2
		
		lda FAC+3
		;ror
		sta FP1+3
		
;		lda #0
;		ror
;		sta E
		
		lda FAC+4
		;ror
		sta E
	
		
		rts
		
************************************
* 	FP1 TO FAC TO BASIC        *
*          CALL 800,Y      	   *
*	   PRINT Y		   *
************************************

*
		** FP1 to MEM to FAC conversion FAC 5 Bytes **
*
ENTRY2		lda FP1		; X1 1 Byte --> 9D FAC
		inc A		; 2^(FP1+1)
		sta MEM
		
		clc
		lda FP1+1	; M1 Hi 2 Byte --> 9E FAC
		rol
		;asl
		ora #$80	; Not Hi Bit Mantissa (change Sign)
		sta MEM+1
		
		lda FP1+2	; M1 3 Byte --> 9F FAC
		;rol
		sta MEM+2
		
		lda FP1+3	; M1 Lo 4 Byte --> A0 FAC
		;rol
		sta MEM+3
		
;		lda E		; Extra 00 5 Byte --> A1 FAC
		lda #0
		;rol
		sta MEM+4
		
;		lda SIGN	; SIGN (F3 to EB) 6 Byte --> A2 FAC
;		sta MEM+5
		
		***************************
* 
		ldy #$03 	;Hi Byte MEM
		lda #$80 	;Lo Byte MEM
		jsr MOVFM	;MEM->FAC (9D to A2)
*
		jsr CHKCOM
		jsr PTRGET
		tax
		jsr MOVMF	;FAC->VARIABLE Y
		rts