* @com.wudsn.ide.asm.hardware=APPLE2
COut  		equ $FDED
PTR		equ $EB
STARTCHK	lda	#<STARTCHK
		sta	PTR
		lda	#>STARTCHK
		sta	PTR+1
		ldy	#$00
		lda	#$00
		pha
		
LOOP		pla
		eor	(PTR),y
		pha
		inc	PTR
		bne	CHK
		inc	PTR+1
CHK		lda	PTR+1
		cmp	#>PROGEND
		bcc	LOOP
		lda	PTR
		cmp	#<PROGEND
		bcc	LOOP
		beq	LOOP
CHKCS		pla
		cmp	CHKSUM
		bne	ERROR
REALSTART	lda #0
		inc A
		sta $FA
PROGEND		rts
CHKSUM		chk
ERROR		sta CHKCALC
		lda #"E"
		jsr COut
		rts
CHKCALC		dfb	$00				