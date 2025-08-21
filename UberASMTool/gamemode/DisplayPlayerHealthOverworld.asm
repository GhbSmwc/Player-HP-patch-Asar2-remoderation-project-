;;This needs to be run under gamemode $0D-$0E so that the meter appears during fade rather
;;than abruptly after the overworld fully loads.

incsrc "../GraphicalBarDefines.asm"		;\Needed first else defines are being used before they are set
incsrc "../StatusBarDefines.asm"		;/
incsrc "../PlayerHPDefines.asm"
incsrc "../NumberDisplayRoutinesDefines.asm"
incsrc "../MotherHPDefines.asm"
macro WriteFixedDigitsToLayer3(TileLocation, TileLocationProp)
	LDX.b #((!Setting_PlayerHP_MaxDigits-1)*2)
	LDY.b #(!Setting_PlayerHP_MaxDigits-1)
	-
	LDA.w !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1)|!dp,y
	STA <TileLocation>,x
	LDA.b #!Setting_PlayerHP_CurrentAndMax_Overworld_Prop
	STA <TileLocationProp>,x
	DEY
	DEX #2
	BPL -
endmacro

macro WriteTileAddress(TileLocation, PropLocation)
	LDA.b #<TileLocation>
	STA $00
	LDA.b #<TileLocation>>>8
	STA $01
	LDA.b #<TileLocation>>>16
	STA $02
	LDA.b #<PropLocation>
	STA $03
	LDA.b #<PropLocation>>>8
	STA $04
	LDA.b #<PropLocation>>>16
	STA $05
	LDA.b #!Setting_PlayerHP_CurrentAndMax_Overworld_Prop
	STA $06
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

	!StaticSlashTileExist = and(equal(!Setting_PlayerHP_DigitsAlignOverworld,0), equal(!Setting_PlayerHP_DisplayNumericalOverworld, 2))


if !StaticSlashTileExist
	init:
		if !sa1
			%invoke_sa1(.RunSA1)
			RTL
			.RunSA1
		endif
		;When displaying 2 numbers without aligned characters (not using left or right aligned, this writes a slash in between the two numbers)
		if !StaticSlashTileExist
			LDA #!OverWorldBorderSlashCharacterTileNumb
			STA !Setting_PlayerHP_StringPos_Owb_XYPos+((!Setting_PlayerHP_MaxDigits)*$02)
			LDA.b #!Setting_PlayerHP_CurrentAndMax_Overworld_Prop
			STA !Setting_PlayerHP_StringPos_Owb_XYPosProp+((!Setting_PlayerHP_MaxDigits)*$02)
		endif
		;This initializes !Freeram_PlayerHP_BarRecord so that when entering a level, the bar instantly represents just your current HP.
		if !Setting_PlayerHP_DisplayBarOverworld
			JSR SetGraphicalBarAttributesAndPercentage
			LDA $00
			STA !Freeram_PlayerHP_BarRecord
		endif
		RTL
endif
main:
	if !sa1
		%invoke_sa1(.RunSA1)
		RTL
		.RunSA1
	endif
	.WriteHPString
		;Detect user trying to make a right-aligned single number (which avoids unnecessarily uses suppress leading zeroes)
			!IsUsingRightAlignedSingleNumber = and(equal(!Setting_PlayerHP_DigitsAlignOverworld, 2),equal(!Setting_PlayerHP_DisplayNumericalOverworld, 1))
		if !Setting_PlayerHP_DisplayNumericalOverworld != 0 ;User allows display HP numerically
			;Clear the tiles. To prevent leftover "ghost" tiles that should've
			;disappear when the number of digits decreases (so when "10" becomes "9",
			;won't display "90").
			if !IsUsingRightAlignedSingleNumber == 0
				LDX.b #(!Setting_PlayerHP_Overworld_MaxStringLength-1)*$02	;>2 Setting_PlayerHP_MaxDigits due to 2 numbers displayed, plus 1 because of the "/" symbol.
				-
				LDA #!OverWorldBorderBlankTile
				if !Setting_PlayerHP_DigitsAlignOverworld == 1
					STA !Setting_PlayerHP_StringPos_Owb_XYPos,x
				elseif !Setting_PlayerHP_DigitsAlignOverworld == 2
					STA !Setting_PlayerHP_StringPosRightAligned_Owb_XYPos-((!Setting_PlayerHP_Overworld_MaxStringLength-1)*$02),x
				endif
				LDA.b #!Setting_PlayerHP_CurrentAndMax_Overworld_Prop
				if !Setting_PlayerHP_DigitsAlignOverworld == 1
					STA !Setting_PlayerHP_StringPos_Owb_XYPosProp,x
				elseif !Setting_PlayerHP_DigitsAlignOverworld == 2
					STA !Setting_PlayerHP_StringPosRightAligned_Owb_XYPosProp-((!Setting_PlayerHP_Overworld_MaxStringLength-1)*$02),x
				endif
				DEX #$02
				BPL -
			endif
			if or(equal(!Setting_PlayerHP_DigitsAlignOverworld, 0), equal(!IsUsingRightAlignedSingleNumber, 1)) ;fixed digit location
				%GetHealthDigits(!Freeram_PlayerHP_CurrentHP)
				%UberRoutine(RemoveLeadingZeroes16Bit)
				%UberRoutine(SixteenBitHexDecDivisionToOWB)
				%WriteFixedDigitsToLayer3(!Setting_PlayerHP_StringPos_Owb_XYPos, !Setting_PlayerHP_StringPos_Owb_XYPosProp)
				if !Setting_PlayerHP_DisplayNumericalOverworld == 2
					%GetHealthDigits(!Freeram_PlayerHP_MaxHP)
					%UberRoutine(RemoveLeadingZeroes16Bit)
					%UberRoutine(SixteenBitHexDecDivisionToOWB)
					%WriteFixedDigitsToLayer3(!Setting_PlayerHP_StringPos_Owb_XYPos+((!Setting_PlayerHP_MaxDigits+1)*$02), !Setting_PlayerHP_StringPos_Owb_XYPosProp+((!Setting_PlayerHP_MaxDigits+1)*$02))
				endif
			elseif and(greaterequal(!Setting_PlayerHP_DigitsAlignOverworld, 1), lessequal(!Setting_PlayerHP_DigitsAlignOverworld, 2)) ;left/right-aligned
				%GetHealthDigits(!Freeram_PlayerHP_CurrentHP)
				LDX #$00
				%UberRoutine(SuppressLeadingZeroes)
				if !Setting_PlayerHP_DisplayNumericalOverworld == 2 ;Displaying Current/Max
					LDA #!StatusBarSlashCharacterTileNumb
					STA !Scratchram_CharacterTileTable,x
					INX
					%GetHealthDigits(!Freeram_PlayerHP_MaxHP)
					%UberRoutine(SuppressLeadingZeroes)
				endif
				%UberRoutine(ConvertAlignedDigitToOWB)
				if !Setting_PlayerHP_ExcessDigitProt != 0
					CPX.b #(!Setting_PlayerHP_Overworld_MaxStringLength+1)
					BCS ..TooMuchChar
				endif
				if !Setting_PlayerHP_DigitsAlignOverworld == 1
					%WriteTileAddress(!Setting_PlayerHP_StringPos_Owb_XYPos, !Setting_PlayerHP_StringPos_Owb_XYPosProp)
				elseif !Setting_PlayerHP_DigitsAlignOverworld == 2
					%WriteTileAddress(!Setting_PlayerHP_StringPosRightAligned_Owb_XYPos, !Setting_PlayerHP_StringPosRightAligned_Owb_XYPosProp)
				endif
				if !Setting_PlayerHP_DigitsAlignOverworld == 2 ;Right-aligned
					%UberRoutine(ConvertToRightAlignedFormat2)
				endif
				%UberRoutine(WriteStringDigitsToHUDFormat2)
				
			endif
		endif
		..TooMuchChar
	.WriteGraphicalBar
	if !Setting_PlayerHP_DisplayBarOverworld
		..HandleTimersAndPreviousHPDisplay
			JSR SetGraphicalBarAttributesAndPercentage	;>$00~$01 = current HP percentage
			%UberRoutine(GraphicalBar_DrawGraphicalBarSubtractionLoopEdition)
			LDA #$02				;\Use overworld sets of fill tiles
			STA $00					;/
			%UberRoutine(GraphicalBar_ConvertBarFillAmountToTiles)
		..WriteToHUD
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPos
			STA $00
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPos>>8
			STA $01
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPos>>16
			STA $02
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPosProp
			STA $03
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPosProp>>8
			STA $04
			LDA.b #!Setting_PlayerHP_GraphicalBarPos_Owb_XYPosProp>>16
			STA $05
			if !Setting_PlayerHP_LeftwardsBarOverworld == 0
				LDA.b #!Setting_PlayerHP_Bar_Overworld_Prop
			else
				LDA.b #(!Setting_PlayerHP_Bar_Overworld_Prop|(!Setting_PlayerHP_LeftwardsBarOverworld<<6))
			endif
			STA $06
			if !Setting_PlayerHP_LeftwardsBarOverworld == 0
				%UberRoutine(GraphicalBar_WriteToStatusBar_Format2)
			else
				%UberRoutine(GraphicalBar_WriteToStatusBarLeftwards_Format2)
			endif
	endif
	RTL
	
	if !Setting_PlayerHP_DisplayBarOverworld
		SetGraphicalBarAttributesAndPercentage:
			LDA !Freeram_PlayerHP_CurrentHP
			STA !Scratchram_GraphicalBar_FillByteTbl
			LDA !Freeram_PlayerHP_MaxHP
			STA !Scratchram_GraphicalBar_FillByteTbl+2
			if !Setting_PlayerHP_TwoByte != 0
				LDA !Freeram_PlayerHP_CurrentHP+1
				STA !Scratchram_GraphicalBar_FillByteTbl+1
				LDA !Freeram_PlayerHP_MaxHP+1
				STA !Scratchram_GraphicalBar_FillByteTbl+3
			else
				LDA #$00
				STA !Scratchram_GraphicalBar_FillByteTbl+1
				STA !Scratchram_GraphicalBar_FillByteTbl+3
			endif
			LDA.b #!Setting_PlayerHP_GraphicalBar_LeftPieces		;\Left end normally have 3 pieces.
			STA !Scratchram_GraphicalBar_LeftEndPiece			;/
			LDA.b #!Setting_PlayerHP_GraphicalBar_MiddlePieces		;\Number of pieces in each middle byte/8x8 tile
			STA !Scratchram_GraphicalBar_MiddlePiece			;/
			LDA.b #!Setting_PlayerHP_GraphicalBar_RightPieces		;\Right end
			STA !Scratchram_GraphicalBar_RightEndPiece			;/
			LDA.b #!Setting_PlayerHP_GraphicalBarMiddleLengthOverworld	;\length (number of middle tiles)
			STA !Scratchram_GraphicalBar_TempLength				;/
			if !Setting_PlayerHP_BarFillRoundDirection == 0
				%UberRoutine(GraphicalBar_CalculatePercentage)
			elseif !Setting_PlayerHP_BarFillRoundDirection == 1
				%UberRoutine(GraphicalBar_CalculatePercentageRoundDown)
			elseif !Setting_PlayerHP_BarFillRoundDirection == 2
				%UberRoutine(GraphicalBar_CalculatePercentageRoundUp)
			endif
			;$00~$01 = percentage
			if !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 1
				%UberRoutine(GraphicalBar_RoundAwayEmpty)
			elseif !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 2
				%UberRoutine(GraphicalBar_RoundAwayFull)
			elseif !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 3
				%UberRoutine(GraphicalBar_RoundAwayEmptyFull)
			endif
			RTS
	endif