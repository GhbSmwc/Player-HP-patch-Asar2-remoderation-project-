incsrc "../GraphicalBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../StatusBarDefines.asm"
incsrc "../NumberDisplayRoutinesDefines.asm"

macro WriteFixedDigitsToStatusBar(StatusbarLocation)
	if !StatusbarFormat == $01
		LDX.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.b !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1),x
		STA <StatusbarLocation>,x
		DEX
		BPL -
	else
		LDX.b #((!Setting_PlayerHP_MaxDigits-1)*2)
		LDY.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.w !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1)|!dp,y
		STA <StatusbarLocation>,x
		DEY
		DEX #2
		BPL -
	endif
endmacro

macro GetHealthDigits(ValueToDisplay)
	if !Setting_PlayerHP_TwoByte == 0
		LDA <ValueToDisplay>
		STA $00
		STZ $01
		%UberRoutine(SixteenBitHexDecDivision)
	else
		REP #$20
		LDA <ValueToDisplay>
		STA $00
		SEP #$20
		%UberRoutine(SixteenBitHexDecDivision)
	endif
endmacro


if and(equal(!Setting_PlayerHP_DigitsAlignLevel,0), equal(!Setting_PlayerHP_DisplayNumericalLevel, 2))
	init:
		LDA #!StatusBarSlashCharacterTileNumb
		STA !PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits)*2)
		RTL
endif

main:
	if !Setting_PlayerHP_DisplayNumericalLevel != 0 ;User allows display HP numerically
		if !Setting_PlayerHP_DigitsAlignLevel == 0 ;fixed digit location
			%GetHealthDigits(!Freeram_PlayerCurrHP)
			%UberRoutine(RemoveLeadingZeroes16Bit)
			%WriteFixedDigitsToStatusBar(!PlayerHP_Digit_StatBarPos)
			if !Setting_PlayerHP_DisplayNumericalLevel == 2
				%GetHealthDigits(!Freeram_PlayerMaxHP)
				%UberRoutine(RemoveLeadingZeroes16Bit)
				%WriteFixedDigitsToStatusBar(!PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits+1)*!StatusbarFormat))
			endif
		endif
	endif
	RTL