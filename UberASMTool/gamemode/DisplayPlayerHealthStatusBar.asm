;This needs to be run under gamemode $13-$14 so that the meter appears during fade rather
;than abruptly after the level fully loads.

;This code displays the player HP (numerical and/or as a bar) on the layer 3 status bar.

incsrc "../GraphicalBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../StatusBarDefines.asm"
incsrc "../NumberDisplayRoutinesDefines.asm"
incsrc "../MotherHPDefines.asm"
macro WriteFixedDigitsToLayer3(TileLocation)
	if !StatusbarFormat == $01
		LDX.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.b !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1),x
		STA <TileLocation>,x
		DEX
		BPL -
	else
		LDX.b #((!Setting_PlayerHP_MaxDigits-1)*2)
		LDY.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.w !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1)|!dp,y
		STA <TileLocation>,x
		DEY
		DEX #2
		BPL -
	endif
endmacro

macro WriteTileAddress(TileLocation, PropLocation)
	LDA.b #<TileLocation>
	STA $00
	LDA.b #<TileLocation>>>8
	STA $01
	LDA.b #<TileLocation>>>16
	STA $02
	if !StatusBar_UsingCustomProperties != 0
		LDA.b #<PropLocation>
		STA $03
		LDA.b #<PropLocation>>>8
		STA $04
		LDA.b #<PropLocation>>>16
		STA $05
		LDA.b #!PlayerHP_TileProp_Level_Text
		STA $06
	endif
endmacro

macro WriteAlignedDigitsToLayer3()
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

	!StaticSlashTileExist = and(equal(!Setting_PlayerHP_DigitsAlignLevel,0), equal(!Setting_PlayerHP_DisplayNumericalLevel, 2))


if or(!StaticSlashTileExist, !Setting_PlayerHP_BarAnimation)
	init:
		;When displaying 2 numbers without aligned characters (not using left or right aligned, this writes a slash in between the two numbers)
		if !StaticSlashTileExist
			LDA #!StatusBarSlashCharacterTileNumb
			STA !PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
			if !StatusBar_UsingCustomProperties != 0
				LDA.b #!PlayerHP_TileProp_Level_Text
				STA !PlayerHP_Digit_StatBarPosProp+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
			endif
		endif
		;This initializes !Freeram_PlayerHP_BarRecord so that when entering a level, the bar instantly represents just your current HP.
		if and(!Setting_PlayerHP_DisplayBarLevel, !Setting_PlayerHP_BarAnimation)
			JSR SetGraphicalBarAttributesAndPercentage
			LDA $00
			STA !Freeram_PlayerHP_BarRecord
		endif
		RTL
endif
main:
	.WriteHPString
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
				if !Setting_PlayerHP_DigitsAlignLevel == 1
					STA !PlayerHP_Digit_StatBarPos,x
				elseif !Setting_PlayerHP_DigitsAlignLevel == 2
					STA !PlayerHP_Digit_StatBarPos_RightAligned-((((!Setting_PlayerHP_MaxDigits*2)+1)-1)*!StatusbarFormat),x
				endif
				if !StatusBar_UsingCustomProperties != 0
					LDA.b #!PlayerHP_TileProp_Level_Text
					if !Setting_PlayerHP_DigitsAlignLevel == 1
						STA !PlayerHP_Digit_StatBarPosProp,x
					elseif !Setting_PlayerHP_DigitsAlignLevel == 2
						STA !PlayerHP_Digit_StatBarPos_RightAlignedProp-((((!Setting_PlayerHP_MaxDigits*2)+1)-1)*!StatusbarFormat),x
					endif
				endif
				DEX #!StatusbarFormat
				BPL -
			endif
			if or(equal(!Setting_PlayerHP_DigitsAlignLevel, 0), equal(!IsUsingRightAlignedSingleNumber, 1)) ;fixed digit location
				%GetHealthDigits(!Freeram_PlayerCurrHP)
				%UberRoutine(RemoveLeadingZeroes16Bit)
				%WriteFixedDigitsToLayer3(!PlayerHP_Digit_StatBarPos)
				if !Setting_PlayerHP_DisplayNumericalLevel == 2
					%GetHealthDigits(!Freeram_PlayerMaxHP)
					%UberRoutine(RemoveLeadingZeroes16Bit)
					%WriteFixedDigitsToLayer3(!PlayerHP_Digit_StatBarPos+((!Setting_PlayerHP_MaxDigits+1)*!StatusbarFormat))
				endif
			elseif and(greaterequal(!Setting_PlayerHP_DigitsAlignLevel, 1), lessequal(!Setting_PlayerHP_DigitsAlignLevel, 2)) ;left/right-aligned
				%GetHealthDigits(!Freeram_PlayerCurrHP)
				LDX #$00
				%UberRoutine(SuppressLeadingZeroes)
				if !Setting_PlayerHP_DisplayNumericalLevel == 2 ;Displaying Current/Max
					LDA #!StatusBarSlashCharacterTileNumb
					STA !Scratchram_CharacterTileTable,x
					INX
					%GetHealthDigits(!Freeram_PlayerMaxHP)
					%UberRoutine(SuppressLeadingZeroes)
				endif
				if !Setting_PlayerHP_ExcessDigitProt != 0
					CPX.b #(((!Setting_PlayerHP_MaxDigits*2)+1)+1)
					BCS ..TooMuchChar
				endif
				if !Setting_PlayerHP_DigitsAlignLevel == 1
					%WriteTileAddress(!PlayerHP_Digit_StatBarPos, !PlayerHP_Digit_StatBarPosProp)
				elseif !Setting_PlayerHP_DigitsAlignLevel == 2
					%WriteTileAddress(!PlayerHP_Digit_StatBarPos_RightAligned, !PlayerHP_Digit_StatBarPos_RightAlignedProp)
				endif
				if !Setting_PlayerHP_DigitsAlignLevel == 2 ;Right-aligned
					if !StatusbarFormat == $01
						%UberRoutine(ConvertToRightAligned)
					else
						%UberRoutine(ConvertToRightAlignedFormat2)
					endif
				endif
				%WriteAlignedDigitsToLayer3()
				
			endif
	endif
		..TooMuchChar
	.WriteGraphicalBar
	if !Setting_PlayerHP_DisplayBarLevel
		..HandleTimersAndPreviousHPDisplay
			JSR SetGraphicalBarAttributesAndPercentage	;>$00~$01 = current HP percentage
			if !Setting_PlayerHP_BarAnimation
				if !PlayerHP_BarRecordDelay
					LDA !Freeram_PlayerHP_BarRecordDelayTmr
					BEQ ...TimerEnded
					DEC
					STA !Freeram_PlayerHP_BarRecordDelayTmr
					...TimerEnded
				endif
				
				LDA $00
				CMP !Freeram_PlayerHP_BarRecord
				BEQ ...PreviousAndCurrentHPEqual
				BCC ...Damage
				
				...Heal
					if or(equal(!Setting_PlayerHP_RollingHP, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0))
						if and(notequal(!Setting_PlayerHP_ShowHealedTransparent, 0), notequal(!PlayerHP_BarRecordDelay, 0))
							LDA !Freeram_PlayerHP_BarRecordDelayTmr		;>Freeze if timer is still active
							BNE ....OverwriteFill
						endif
						if and(notequal(!PlayerHP_BarFillUpSpeed, 0), less(!PlayerHP_BarFillUpSpeedPerFrame, 2))
							LDA $13							;\every 2^n frames, don't increment for slower speed.
							AND.b #!PlayerHP_BarFillUpSpeed				;|
							BNE ....OverwriteFill					;/
						endif
						LDA !Freeram_PlayerHP_BarRecord
						if !PlayerHP_BarFillUpSpeedPerFrame >= 2
							CLC						;\Increment fill
							ADC.b #!PlayerHP_BarFillUpSpeedPerFrame		;/
							BCS ....IncrementPast				;>In case the record fill increments past 255.
							CMP $00						;\Continue incrementing until greater than or equal to $00.
							BCC ....Increment				;/
							
							....IncrementPast
								LDA $00						;\If greater or equal to, set the record fill to $00.
								STA !Freeram_PlayerHP_BarRecord			;/
								BRA ..Calculate_WriteBar			
							
							....Increment
								STA !Freeram_PlayerHP_BarRecord
						else
							INC						;\Increment fill by 1.
							STA !Freeram_PlayerHP_BarRecord			;/
						endif
						
						....OverwriteFill
							if !Setting_PlayerHP_ShowHealedTransparent != 0
								LDA $13				;\Check bit 0 of the frame counter
								AND.b #%00000001		;/
								BNE ..Calculate_WriteBar	;>If odd frame, display current HP.
							endif
							LDA !Freeram_PlayerHP_BarRecord		;\Display previous HP.
							STA $00					;/
							BRA ..Calculate_WriteBar
					else
						LDA $00					;\Only display current HP sliding upwards when enabling rolling HP.
						STA !Freeram_PlayerHP_BarRecord		;/(writes to bar record so if taking damage while healing doesn't have record fall behind)
						BRA ..Calculate_WriteBar
					endif
				...Damage
					if and(notequal(!PlayerHP_BarFillDrainSpeed, 0), less(!PlayerHP_BarFillEmptyingSpeedPerFrame, 2))
						LDA $13							;\Decrement every 2^n frames
						AND.b #!PlayerHP_BarFillDrainSpeed			;|
						if !PlayerHP_BarRecordDelay != 0
							ORA !Freeram_PlayerHP_BarRecordDelayTmr		;|>Freeze if timer still active
						endif
						BNE ....TransperentAnimation				;/>If odd frame, display alternating frames of HP.
					else
						if !PlayerHP_BarRecordDelay != 0
							LDA !Freeram_PlayerHP_BarRecordDelayTmr
							BNE ....TransperentAnimation
						endif
					endif
					if !PlayerHP_BarFillEmptyingSpeedPerFrame >= 2
						LDA !Freeram_PlayerHP_BarRecord			;\Decrement fill
						SEC						;|
						SBC.b #!PlayerHP_BarFillEmptyingSpeedPerFrame	;/
						BCC ....Underflow				;>Underflow check
						CMP $00						;\Check if record decrements past the current HP.
						BCS ....Decrement				;/
						
						....Underflow
							LDA $00						;\Set record to current if it did goes past.
							STA !Freeram_PlayerHP_BarRecord			;/
							BRA ..Calculate_WriteBar
						
						....Decrement
							STA !Freeram_PlayerHP_BarRecord			;>And set the subtracted value to record
							BRA ....TransperentAnimation
					else
						LDA !Freeram_PlayerHP_BarRecord			;\Decrement by 1
						DEC						;|
						STA !Freeram_PlayerHP_BarRecord			;/
					endif
					....TransperentAnimation
						if !Setting_PlayerHP_ShowDamageTransperent != 0
							LDA $13					;\Alternating frames
							AND.b #%00000001			;/
							BNE ..Calculate_WriteBar		;>If odd frame, display current HP.
						endif
						LDA !Freeram_PlayerHP_BarRecord			;\Otherwise if even, display previous HP
						STA $00						;/
				...PreviousAndCurrentHPEqual
			endif
		..Calculate
			if !Setting_PlayerHP_BarAnimation
				LDA $13
				AND.b #%00000001
				BEQ ...ShowCurrentHPOnEvenFrames
				
					...ShowPreviousHPOnOddFrames
					LDA !Freeram_PlayerHP_BarRecord
					STA $00
				...ShowCurrentHPOnEvenFrames
			endif
			%UberRoutine(GraphicalBar_RoundAwayEmptyFull)
			...WriteBar
				%UberRoutine(GraphicalBar_DrawGraphicalBarSubtractionLoopEdition)
			STZ $00					;>Use level sets of fill tiles
			%UberRoutine(GraphicalBar_ConvertBarFillAmountToTiles)
		..WriteToHUD
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
	
	if !Setting_PlayerHP_DisplayBarLevel
		SetGraphicalBarAttributesAndPercentage:
			;$00~$01 = percentage
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
			RTS
	endif