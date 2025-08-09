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

macro WriteAlignedDigitsToStatusBar(StatusbarLocationTile, StatusbarLocationProp)
	LDA.b #<StatusbarLocationTile>
	STA $00
	LDA.b #<StatusbarLocationTile>>>8
	STA $01
	LDA.b #<StatusbarLocationTile>>>16
	STA $02
	if !StatusBar_UsingCustomProperties != 0
		LDA.b #<StatusbarLocationProp>
		STA $03
		LDA.b #<StatusbarLocationProp>>>8
		STA $04
		LDA.b #<StatusbarLocationProp>>>16
		STA $05
		LDA.b #!PlayerHP_TileProp_Level_Text
		STA $06
	endif
	if !StatusbarFormat == $01
		%UberRoutine(WriteStringDigitsToHUD)
	else
		%UberRoutine(WriteStringDigitsToHUDFormat2)
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
		STA !PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
		if !StatusBar_UsingCustomProperties != 0
			LDA.b #!PlayerHP_TileProp_Level_Text
			STA !PlayerHP_Digit_StatBarPosProp+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
		endif
		RTL
endif
main:
	;Detect user trying to make a right-aligned single number (which avoids unnecessarily uses suppress leading zeroes)
		!IsUsingRightAlignedSingleNumber = and(equal(!Setting_PlayerHP_DigitsAlignLevel, 2),equal(!Setting_PlayerHP_DisplayNumericalLevel, 1))
	if !Setting_PlayerHP_DisplayNumericalLevel != 0 ;User allows display HP numerically
		;Clear the tiles. To prevent leftover "ghost" tiles that should've
		;disappear when the number of digits decreases (so when "10" becomes "9",
		;won't display "90").
		if !Setting_PlayerHP_DigitsAlignLevel != 0
			LDX.b #(((!Setting_PlayerHP_MaxDigits*2)+1)-1)*!StatusbarFormat	;>2 Setting_PlayerHP_MaxDigits due to 2 numbers displayed, plus 1 because of the "/" symbol.
			-
			LDA #!StatusBarBlankTile
			STA !PlayerHP_Digit_StatBarPos,x
			if !StatusBar_UsingCustomProperties != 0
				LDA.b #!PlayerHP_TileProp_Level_Text
				STA !PlayerHP_Digit_StatBarPosProp,x
			endif
			DEX #!StatusbarFormat
			BPL -
		endif
		if or(equal(!Setting_PlayerHP_DigitsAlignLevel, 0), equal(!IsUsingRightAlignedSingleNumber, 1)) ;fixed digit location
			%GetHealthDigits(!Freeram_PlayerCurrHP)
			%UberRoutine(RemoveLeadingZeroes16Bit)
			%WriteFixedDigitsToStatusBar(!PlayerHP_Digit_StatBarPos)
			if !Setting_PlayerHP_DisplayNumericalLevel == 2
				%GetHealthDigits(!Freeram_PlayerMaxHP)
				%UberRoutine(RemoveLeadingZeroes16Bit)
				%WriteFixedDigitsToStatusBar(!PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits+1)*!StatusbarFormat))
			endif
		elseif !Setting_PlayerHP_DigitsAlignLevel == 1 ;left-aligned
			%GetHealthDigits(!Freeram_PlayerCurrHP)
			LDX #$00
			%UberRoutine(SuppressLeadingZeroes)
			if !Setting_PlayerHP_DisplayNumericalLevel == 2
				LDA #!StatusBarSlashCharacterTileNumb
				STA !Scratchram_CharacterTileTable,x
				INX
				%GetHealthDigits(!Freeram_PlayerMaxHP)
				%UberRoutine(SuppressLeadingZeroes)
			endif
			if !Setting_PlayerHP_ExcessDigitProt != 0
				CPX.b #(((!Setting_PlayerHP_MaxDigits*2)+1)+1)
				BCS .TooMuchChar
			endif
			%WriteAlignedDigitsToStatusBar(!PlayerHP_Digit_StatBarPos, !PlayerHP_Digit_StatBarPosProp)
			.TooMuchChar
		endif
	endif
	if !Setting_PlayerHP_DisplayBarLevel != 0
		LDA !Freeram_PlayerCurrHP
		STA !Scratchram_GraphicalBar_FillByteTbl
		LDA !Freeram_PlayerMaxHP
		STA !Scratchram_GraphicalBar_FillByteTbl+2
		if !Setting_PlayerHP_TwoByte != 0
			LDA !Freeram_PlayerCurrHP+1
			STA !Scratchram_GraphicalBar_FillByteTbl+1
			LDA !Freeram_PlayerMaxHP+1
			STA !Scratchram_GraphicalBar_FillByteTbl+3
		endif
		LDA.b #!Default_LeftPieces				;\Left end normally have 3 pieces.
		STA !Scratchram_GraphicalBar_LeftEndPiece		;/
		LDA.b #!Default_MiddlePieces				;\Number of pieces in each middle byte/8x8 tile
		STA !Scratchram_GraphicalBar_MiddlePiece		;/
		LDA.b #!Default_RightPieces				;\Right end
		STA !Scratchram_GraphicalBar_RightEndPiece		;/
		LDA.b #!Default_MiddleLengthLevel			;\length (number of middle tiles)
		STA !Scratchram_GraphicalBar_TempLength			;/
		%UberRoutine(GraphicalBar_CalculatePercentage)
		%UberRoutine(GraphicalBar_RoundAwayEmptyFull)
		%UberRoutine(GraphicalBar_DrawGraphicalBarSubtractionLoopEdition)
		STZ $00
		%UberRoutine(GraphicalBar_ConvertBarFillAmountToTiles)
		LDA.b #!Setting_PlayerHP_BarPosLevel
		STA $00
		LDA.b #!Setting_PlayerHP_BarPosLevel>>8
		STA $01
		LDA.b #!Setting_PlayerHP_BarPosLevel>>16
		STA $02
		if !StatusBar_UsingCustomProperties != 0
			LDA.b #!Setting_PlayerHP_BarPosLevelProp
			STA $03
			LDA.b #!Setting_PlayerHP_BarPosLevelProp>>8
			STA $04
			LDA.b #!Setting_PlayerHP_BarPosLevelProp>>16
			STA $05
			if !Setting_PlayerHP_LeftwardsBarLevel == 0
				LDA.b #!PlayerHP_BarProps_Lvl
			else
				LDA.b #(!PlayerHP_BarProps_Lvl|(!Setting_PlayerHP_LeftwardsBarLevel<<6))
			endif
			STA $06
		endif
		if !Setting_PlayerHP_LeftwardsBarLevel == 0
			if !StatusbarFormat == $01
				%UberRoutine(GraphicalBar_WriteToStatusBar)
			else
				%UberRoutine(GraphicalBar_WriteToStatusBar_Format2)
			endif
		else
			if !StatusbarFormat == $01
				%UberRoutine(GraphicalBar_WriteToStatusBarLeftwards)
			else
				%UberRoutine(GraphicalBar_WriteToStatusBarLeftwards_Format2)
			endif
		endif
	endif
	RTL