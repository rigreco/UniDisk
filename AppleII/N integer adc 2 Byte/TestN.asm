* @com.wudsn.ide.asm.hardware=APPLE2
*** Start UNIDISK Program ***
** Two byte adc **
		org $300
RSLTU		equ $C0
NDEC		equ $C2
N		equ $C4

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
		
LOOP		lda N
		
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
DONE		ldx RSLTU
		ldy RSLTU+1
		  		
  		rts
  		
  		
** Input Dynamic Data append in the end of Unidisk routine **  		
N1U		dfb $FF
		dfb $FF