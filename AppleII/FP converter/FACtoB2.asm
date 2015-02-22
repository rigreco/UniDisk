* @com.wudsn.ide.asm.hardware=APPLE2
************************************
* 	FP1 TO FAC TO BASIC        *
*          CALL 768,Y      	   *
*	   PRINT Y		   *
************************************
		org $300
		
CHKCOM		equ $DEBE
PTRGET		equ $DFE3
MOVMF		equ $EB2B
MOVFM		equ $EAF9

** Woz FP Accumulator 4 Byte + 1 Byte Extra + 1 Byte SIGN**
FP1		equ $FA	;Translate F8 --> FA
E		equ $FE ;Translate FC --> FE
SIGN		equ $EB ;Translate F3 --> EB

MEM		equ $0380
*
		** FP1 to MEM to FAC conversion FAC 5 Bytes **
*
ENTRY		lda FP1		; X1 1 Byte --> 9D FAC
		inc A		; 2^(FP1+1)
		sta MEM
		
		clc
		lda FP1+1	; M1 Hi 2 Byte --> 9E FAC
		rol
		;asl
		eor #$80	; Not Hi Bit Mantissa (change Sign)
		sta MEM+1
		
		lda FP1+2	; M1 3 Byte --> 9F FAC
		rol
		sta MEM+2
		
		lda FP1+3	; M1 Lo 4 Byte --> A0 FAC
		rol
		sta MEM+3
		
		lda E		; Extra 00 5 Byte --> A1 FAC
		rol
		sta MEM+4
		
*		lda $EB		; SIGN (F3 to EB) 6 Byte --> A2 FAC
*		sta MEM+5
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
DONE		rts