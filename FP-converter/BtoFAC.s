*    Floating Point converter FAC to FP1 format
*
*    Copyright (C) 2015  Riccardo Greco

*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.

*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*    
* @com.wudsn.ide.asm.hardware=APPLE2
************************************
* 	BASIC TO FAC TO FP1        *
*          Y=NUMBER	           *
*          CALL 2048,Y             *
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
		jsr FRMNUM	;VARIABLE->FAC

** FP1 to FAC conversion **

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
