;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unsigned 32bit * 32bit Multiplication
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Argument
; $00-$03 : Multiplicand
; $04-$07 : Multiplier
; Return values
; $08-$0F : Product
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GHB's note to self:
;$4202 = 1st Multiplicand
;$4203 = 2nd Multiplicand
;$4216 = Product
;During SA-1:
;$2251 = 1st Multiplicand
;$2253 = 2nd Multiplicand
;$2306 = Product

if !sa1 != 0
	!Reg4202 = $2251
	!Reg4203 = $2253
	!Reg4216 = $2306
else
	!Reg4202 = $4202
	!Reg4203 = $4203
	!Reg4216 = $4216
endif

MathMul32_32:
		if !sa1 != 0
			STZ $2250
			STZ $2252
		endif
		REP #$21
		LDY $00
		BNE ?+
		STZ $08
		STZ $0A
		STY $0C
		BRA ?++
?+		STY !Reg4202
		LDY $04
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		STZ $0A
		STZ $0C
		LDY $05
		LDA !Reg4216		;>This is always spitting out as 0.
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $08
		LDA $09
		ADC !Reg4216
		LDY $06
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $09
		LDA $0A
		ADC !Reg4216
		LDY $07
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0A
		LDA $0B
		ADC !Reg4216
		STA $0B
		
?++		LDY $01
		BNE ?+
		STY $0D
		BRA ?++
?+		STY !Reg4202
		LDY $04
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		LDY #$00
		STY $0D
		LDA $09
		ADC !Reg4216
		LDY $05
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $09
		LDA $0A
		ADC !Reg4216
		LDY $06
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0A
		LDA $0B
		ADC !Reg4216
		LDY $07
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0B
		LDA $0C
		ADC !Reg4216
		STA $0C
		
?++		LDY $02
		BNE ?+
		STY $0E
		BRA ?++
?+		STY !Reg4202
		LDY $04
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		LDY #$00
		STY $0E
		LDA $0A
		ADC !Reg4216
		LDY $05
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0A
		LDA $0B
		ADC !Reg4216
		LDY $06
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0B
		LDA $0C
		ADC !Reg4216
		LDY $07
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0C
		LDA $0D
		ADC !Reg4216
		STA $0D
		
?++		LDY $03
		BNE ?+
		STY $0F
		BRA ?++
?+		STY !Reg4202
		LDY $04
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		LDY #$00
		STY $0F
		LDA $0B
		ADC !Reg4216
		LDY $05
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0B
		LDA $0C
		ADC !Reg4216
		LDY $06
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0C
		LDA $0D
		ADC !Reg4216
		LDY $07
		STY !Reg4203
		if !sa1 != 0
			STZ $2254	;>Multiplication actually happens when $2254 is written.
			NOP		;\Wait till multiplication is done
			BRA $00		;/
		endif
		
		STA $0D
		LDA $0E
		ADC !Reg4216
		STA $0E
?++		SEP #$20
		RTL