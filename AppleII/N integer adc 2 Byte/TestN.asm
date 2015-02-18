*
*    TestN <alfa>
*
*    This routine is identical replica of Unidisk routin: 
*    2 Byte Add of the first N integer numbers calculation.
*    For speed test compare between Apple II and Unidisk.
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