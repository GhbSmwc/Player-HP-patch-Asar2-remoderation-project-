	incsrc "../NumberDisplayRoutinesDefines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Convert string that has its leading zeroes suppressed (also left-aligned)
	;to OWB digits.
	;
	;This Works similarly to "SixteenBitHexDecDivisionToOWB" and
	;"ThirtyTwoBitHexDecDivisionToOWB" but the string to convert is stored in
	;!Scratchram_CharacterTileTable.
	;
	;Input:
	; - !Scratchram_CharacterTileTable (NumberOfBytes = NumberOfChar): The string
	;   to convert.
	; - X = Number of characters in the string
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?ConvertAlignedDigitToOWB:
		PHX
		DEX
		?.Loop
			;These here checks if a given character is a specific
			;status bar tile number to convert to.
			LDA !Scratchram_CharacterTileTable,x
			CMP #$0A				;\0-9 are digits
			BCC ?..Digits				;/
			CMP #!StatusBarBlankTile
			BEQ ?..Blank
			CMP #!StatusBarSlashCharacterTileNumb
			BEQ ?..Slash
			CMP #!StatusBarPercentTile
			BEQ ?..Percent
			CMP #!StatusBarDotTile
			BEQ ?..Dot
			CMP #!StatusBarMinusSymbol
			BEQ ?..Minus
			CMP #!StatusBarPlusSymbol
			BEQ ?..Plus
			;You can add more checks here to add more characters to convert to
			
			;Stuff below here are the tile numbers to convert to.
			?..Blank
				LDA #!OverWorldBorderBlankTile
				BRA ?..Write
			?..Slash
				LDA #!OverWorldBorderSlashCharacterTileNumb
				BRA ?..Write
			?..Percent
				LDA #!OverWorldBorderPercentTile
				BRA ?..Write
			?..Dot
				LDA #!OverWorldBorderDotTile
				BRA ?..Write
			?..Minus
				LDA #!OverWorldBorderMinusSymbol
				BRA ?..Write
			?..Plus
				LDA #!OverWorldBorderPlusSymbol
				BRa ?..Write
			?..Digits
				CLC			;\Status bar digits are at tile numbers $00-$09 and Overworld digits are at tile numbers $22-$2B, so we can just add whats in $00-$09 by $22.
				ADC #$22		;/
			?..Write
				STA !Scratchram_CharacterTileTable,x
			?..Next
				DEX
				BPL ?.Loop
		PLX
		RTL