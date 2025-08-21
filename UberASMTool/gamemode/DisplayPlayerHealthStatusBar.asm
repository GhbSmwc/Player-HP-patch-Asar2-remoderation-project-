;This needs to be run under gamemode $13-$14 so that the meter appears during fade rather
;than abruptly after the level fully loads.

;This code displays the player HP (numerical and/or as a bar) on the layer 3 status bar.

incsrc "../GraphicalBarDefines.asm"		;\Needed first else defines are being used before they are set
incsrc "../StatusBarDefines.asm"		;/
incsrc "../PlayerHPDefines.asm"
incsrc "../NumberDisplayRoutinesDefines.asm"
incsrc "../MotherHPDefines.asm"

macro WriteFixedDigitsToLayer3(TileLocation, TileLocationProps)
	if !StatusbarFormat == $01
		LDX.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.b !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1),x
		STA <TileLocation>,x
		
		if !StatusBar_UsingCustomProperties
			if !Setting_PlayerHP_LowHPWarning == 0
				LDA.b #!Setting_PlayerHP_CurrentAndMax_Level_Prop
				STA <TileLocationProps>,x
			else
				LDY $8A
				LDA CurrentAndMaxHPPropsCycle,y
				STA <TileLocationProps>,x
			endif
		endif
		
		DEX
		BPL -
	else
		LDX.b #((!Setting_PlayerHP_MaxDigits-1)*2)
		LDY.b #(!Setting_PlayerHP_MaxDigits-1)
		-
		LDA.w !Scratchram_16bitHexDecOutput+$04-(!Setting_PlayerHP_MaxDigits-1)|!dp,y
		STA <TileLocation>,x
		
		if !StatusBar_UsingCustomProperties
			if !Setting_PlayerHP_LowHPWarning == 0
				LDA.b #!Setting_PlayerHP_CurrentAndMax_Level_Prop
				STA <TileLocationProps>,x
			else
				LDY $8A
				LDA CurrentAndMaxHPPropsCycle,y
				STA <TileLocationProps>,x
			endif
		endif
		
		DEY
		DEX #2
		BPL -
	endif
endmacro

macro WriteTileAddress(TileLocation, PropLocation, PropValue)
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
		LDA.b #<PropValue>
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

macro ConvertToRightAligned()
	if !StatusbarFormat == $01
		%UberRoutine(ConvertToRightAligned)
	else
		%UberRoutine(ConvertToRightAlignedFormat2)
	endif
endmacro

	!StaticSlashTileExist = and(equal(!Setting_PlayerHP_DigitsAlignLevel,0), equal(!Setting_PlayerHP_DisplayNumericalLevel, 2))


if or(!StaticSlashTileExist, !Setting_PlayerHP_BarAnimation)
	init:
		if !sa1
			%invoke_sa1(.RunSA1)
			RTL
			.RunSA1
		endif
		;When displaying 2 numbers without aligned characters (not using left or right aligned, this writes a slash in between the two numbers)
		if !StaticSlashTileExist
			LDA #!StatusBarSlashCharacterTileNumb
			STA !Setting_PlayerHP_StringPos_Lvl_XYPos+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
			if !StatusBar_UsingCustomProperties != 0
				LDA.b #!Setting_PlayerHP_CurrentAndMax_Level_Prop
				STA !Setting_PlayerHP_StringPos_Lvl_XYPosProp+((!Setting_PlayerHP_MaxDigits)*!StatusbarFormat)
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
	if !sa1
		%invoke_sa1(.RunSA1)
		RTL
		.RunSA1
	endif
	PHB
	PHK
	PLB
	.LowHealthIndex
		if !Setting_PlayerHP_LowHPWarning
			LDA #$00				;\$8A = YXPCCCTT index for alternating palette
			STA $8A					;/$00 for default palette, $01 for showing it in red when at or below 25%
			if !Setting_PlayerHP_TwoByte
				REP #$20
			endif
			LDA !Freeram_PlayerHP_CurrentHP
			BEQ ..Flash				;>If 0 HP, don't flash, but stay in palette 2 at all times.
			LDA !Freeram_PlayerHP_MaxHP		;\1/4 of max HP (rounded down)
			LSR #2					;/
			CMP !Freeram_PlayerHP_CurrentHP
			BCC ..Above25Percent
			
			..Below25Percent
				if !Setting_PlayerHP_TwoByte
					SEP #$20
				endif
				LDA $13
				AND.b #%00100000		;>Every 64 frames
				BNE ..NoFlash
				
			..Flash
				INC $8A
			..NoFlash
			..Above25Percent
			if !Setting_PlayerHP_TwoByte
				SEP #$20
			endif
		endif
	.WriteHPString
		;Detect user trying to make a right-aligned single number (which avoids unnecessarily uses suppress leading zeroes)
			!IsUsingRightAlignedSingleNumber = and(equal(!Setting_PlayerHP_DigitsAlignLevel, 2),equal(!Setting_PlayerHP_DisplayNumericalLevel, 1))
		if !Setting_PlayerHP_DisplayNumericalLevel != 0 ;User allows display HP numerically
			;Clear the tiles. To prevent leftover "ghost" tiles that should've
			;disappear when the number of digits decreases (so when "10" becomes "9",
			;won't display "90").
			if !IsUsingRightAlignedSingleNumber == 0
				LDX.b #(!Setting_PlayerHP_Level_MaxStringLength-1)*!StatusbarFormat	;>2 Setting_PlayerHP_MaxDigits due to 2 numbers displayed, plus 1 because of the "/" symbol.
				-
				LDA #!StatusBarBlankTile
				if !Setting_PlayerHP_DigitsAlignLevel == 1
					STA !Setting_PlayerHP_StringPos_Lvl_XYPos,x
				elseif !Setting_PlayerHP_DigitsAlignLevel == 2
					STA !Setting_PlayerHP_StringPosRightAligned_Lvl_XYPos-((!Setting_PlayerHP_Level_MaxStringLength-1)*!StatusbarFormat),x
				endif
				if !StatusBar_UsingCustomProperties != 0
					LDA.b #!Setting_PlayerHP_CurrentAndMax_Level_Prop
					if !Setting_PlayerHP_DigitsAlignLevel == 1
						STA !Setting_PlayerHP_StringPos_Lvl_XYPosProp,x
					elseif !Setting_PlayerHP_DigitsAlignLevel == 2
						STA !Setting_PlayerHP_StringPosRightAligned_Lvl_XYPosProp-((!Setting_PlayerHP_Level_MaxStringLength-1)*!StatusbarFormat),x
					endif
				endif
				DEX #!StatusbarFormat
				BPL -
			endif
			if or(equal(!Setting_PlayerHP_DigitsAlignLevel, 0), equal(!IsUsingRightAlignedSingleNumber, 1)) ;fixed digit location
				%GetHealthDigits(!Freeram_PlayerHP_CurrentHP)
				%UberRoutine(RemoveLeadingZeroes16Bit)
				%WriteFixedDigitsToLayer3(!Setting_PlayerHP_StringPos_Lvl_XYPos, !Setting_PlayerHP_StringPos_Lvl_XYPosProp)
				if !Setting_PlayerHP_DisplayNumericalLevel == 2
					%GetHealthDigits(!Freeram_PlayerHP_MaxHP)
					%UberRoutine(RemoveLeadingZeroes16Bit)
					%WriteFixedDigitsToLayer3(!Setting_PlayerHP_StringPos_Lvl_XYPos+((!Setting_PlayerHP_MaxDigits+1)*!StatusbarFormat), !Setting_PlayerHP_StringPos_Lvl_XYPosProp+((!Setting_PlayerHP_MaxDigits+1)*!StatusbarFormat))
				endif
			elseif and(greaterequal(!Setting_PlayerHP_DigitsAlignLevel, 1), lessequal(!Setting_PlayerHP_DigitsAlignLevel, 2)) ;left/right-aligned
				%GetHealthDigits(!Freeram_PlayerHP_CurrentHP)
				LDX #$00
				%UberRoutine(SuppressLeadingZeroes)
				if !Setting_PlayerHP_DisplayNumericalLevel == 2 ;Displaying Current/Max
					LDA #!StatusBarSlashCharacterTileNumb
					STA !Scratchram_CharacterTileTable,x
					INX
					%GetHealthDigits(!Freeram_PlayerHP_MaxHP)
					%UberRoutine(SuppressLeadingZeroes)
				endif
				if !Setting_PlayerHP_ExcessDigitProt
					CPX.b #(!Setting_PlayerHP_Level_MaxStringLength+1)
					BCS ..TooMuchChar
				endif
				if !Setting_PlayerHP_DigitsAlignLevel == 1
					%WriteTileAddress(!Setting_PlayerHP_StringPos_Lvl_XYPos, !Setting_PlayerHP_StringPos_Lvl_XYPosProp, !Setting_PlayerHP_CurrentAndMax_Level_Prop)
				elseif !Setting_PlayerHP_DigitsAlignLevel == 2
					%WriteTileAddress(!Setting_PlayerHP_StringPosRightAligned_Lvl_XYPos, !Setting_PlayerHP_StringPosRightAligned_Lvl_XYPosProp, !Setting_PlayerHP_CurrentAndMax_Level_Prop)
				endif
				if !Setting_PlayerHP_LowHPWarning_CanPaletteChange
					LDY $8A
					LDA CurrentAndMaxHPPropsCycle,y
					STA $06
				endif
				if !Setting_PlayerHP_DigitsAlignLevel == 2 ;Right-aligned
					%ConvertToRightAligned()
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
					if !Setting_PlayerHP_BarChangeDelay
						LDA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
						BEQ ...TimerEnded
						DEC
						STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
						...TimerEnded
					endif
					
					LDA $00
					CMP !Freeram_PlayerHP_BarRecord
					BEQ ...PreviousAndCurrentHPEqual
					BCC ...Damage
					
					...Heal
						if or(equal(!Setting_PlayerHP_RollingHP, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0))
							if and(notequal(!Setting_PlayerHP_ShowHealedTransparent, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0))
								LDA !Freeram_Setting_PlayerHP_BarChangeDelayTmr		;>Freeze if timer is still active
								BNE ....OverwriteFill
							endif
							if and(notequal(!Setting_PlayerHP_FillDelayFrames, 0), less(!Setting_PlayerHP_BarFillUpPerFrame, 2))
								LDA $13							;\every 2^n frames, don't increment for slower speed.
								AND.b #!Setting_PlayerHP_FillDelayFrames		;|
								BNE ....OverwriteFill					;/
							endif
							LDA !Freeram_PlayerHP_BarRecord
							if !Setting_PlayerHP_BarFillUpPerFrame >= 2
								CLC						;\Increment fill
								ADC.b #!Setting_PlayerHP_BarFillUpPerFrame		;/
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
						if and(notequal(!Setting_PlayerHP_EmptyDelayFrames, 0), less(!Setting_PlayerHP_BarEmptyPerFrame, 2))
							LDA $13							;\Decrement every 2^n frames
							AND.b #!Setting_PlayerHP_EmptyDelayFrames		;|
							if !Setting_PlayerHP_BarChangeDelay != 0
								ORA !Freeram_Setting_PlayerHP_BarChangeDelayTmr		;|>Freeze if timer still active
							endif
							BNE ....TransperentAnimation				;/>If odd frame, display alternating frames of HP.
						else
							if !Setting_PlayerHP_BarChangeDelay != 0
								LDA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
								BNE ....TransperentAnimation
							endif
						endif
						if !Setting_PlayerHP_BarEmptyPerFrame >= 2
							LDA !Freeram_PlayerHP_BarRecord			;\Decrement fill
							SEC						;|
							SBC.b #!Setting_PlayerHP_BarEmptyPerFrame	;/
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
				...WriteBar
					%UberRoutine(GraphicalBar_DrawGraphicalBarSubtractionLoopEdition)
				STZ $00					;>Use level sets of fill tiles
				%UberRoutine(GraphicalBar_ConvertBarFillAmountToTiles)
			..WriteToHUD
				LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPos
				STA $00
				LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPos>>8
				STA $01
				LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPos>>16
				STA $02
				if !StatusBar_UsingCustomProperties != 0
					LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPosProp
					STA $03
					LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPosProp>>8
					STA $04
					LDA.b #!Setting_PlayerHP_GraphicalBarPos_Lvl_XYPosProp>>16
					STA $05
					if not(!Setting_PlayerHP_LowHPWarning_CanPaletteChange)
						if !Setting_PlayerHP_LeftwardsBarLevel == 0
							LDA.b #!Setting_PlayerHP_Bar_Level_Prop
						else
							LDA.b #(!Setting_PlayerHP_Bar_Level_Prop|(!Setting_PlayerHP_LeftwardsBarLevel<<6))
						endif
					else
						LDY $8A
						LDA GraphicalBarPropsCycle,y
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
	.ClearDamageRecover
		if or(notequal(!Setting_PlayerHP_DisplayDamageTotal, 0), notequal(!Setting_PlayerHP_DisplayRecoveryTotal, 0))
			LDX.b #((!Setting_PlayerHP_MaxDigits+1)-1)*!StatusbarFormat
				;^Number of digits, plus the "-" and "+" symbol, making it 6 characters when !Setting_PlayerHP_MaxDigits == 5
				; minus 1 because we include "index zero"
			..Loop
				...TileNumber
					LDA.b #!StatusBarBlankTile
					if !Setting_PlayerHP_DisplayDamageTotal == 1
						STA !Setting_PlayerHP_DamageNumber_XYPos,x
					elseif !Setting_PlayerHP_DisplayDamageTotal == 2
						STA !Setting_PlayerHP_DamageNumber_RightAligned_XYPos-((!Setting_PlayerHP_MaxDigits+1-1)*!StatusbarFormat),x
					endif
					if !Setting_PlayerHP_DisplayRecoveryTotal == 1
						STA !Setting_PlayerHP_RecoverNumber_XYPos,x
					elseif !Setting_PlayerHP_DisplayRecoveryTotal == 2
						STA !Setting_PlayerHP_RecoverNumber_RightAligned_XYPos-((!Setting_PlayerHP_MaxDigits+1-1)*!StatusbarFormat),x
					endif
				...TileProp
					if !StatusBar_UsingCustomProperties
						if !Setting_PlayerHP_DisplayDamageTotal != 0
							LDA.b #!Setting_PlayerHP_DamageNumber_Prop
						endif
						if !Setting_PlayerHP_DisplayDamageTotal == 1
							STA !Setting_PlayerHP_DamageNumber_XYPosProp,x
						elseif !Setting_PlayerHP_DisplayDamageTotal == 2
							STA !Setting_PlayerHP_DamageNumber_RightAligned_XYPosProp-((!Setting_PlayerHP_MaxDigits+1-1)*!StatusbarFormat),x
						endif
						if !Setting_PlayerHP_DisplayRecoveryTotal != 0
							LDA.b #!Setting_PlayerHP_RecoverNumber_Prop
						endif
						if !Setting_PlayerHP_DisplayRecoveryTotal == 1
							STA !Setting_PlayerHP_RecoverNumber_XYPosProp,x
						elseif !Setting_PlayerHP_DisplayRecoveryTotal == 2
							STA !Setting_PlayerHP_RecoverNumber_RightAligned_XYPosProp-((!Setting_PlayerHP_MaxDigits+1-1)*!StatusbarFormat),x
						endif
					endif
				...Next
					DEX #!StatusbarFormat
					BPL ..Loop
		endif
	.WriteHPDamage
		if !Setting_PlayerHP_DisplayDamageTotal
			LDA !Freeram_PlayerHP_DamageTotalTimerDisplay
			BEQ ..Done
			..DecrementDisplayTimer
				LDA $13
				AND.b #%00000011
				BNE ...No
				LDA !Freeram_PlayerHP_DamageTotalTimerDisplay
				DEC
				STA !Freeram_PlayerHP_DamageTotalTimerDisplay
				BNE ...SkipClear
				LDA #$00
				STA !Freeram_PlayerHP_DamageTotalDisplay
				if !Setting_PlayerHP_TwoByte != 0
					STA !Freeram_PlayerHP_DamageTotalDisplay+1
				endif
				BRA ..Done ;>Prevent "-0" for 1 frame when timer ends
				...SkipClear
				...No
			%GetHealthDigits(!Freeram_PlayerHP_DamageTotalDisplay)
			LDA.b #!StatusBarMinusSymbol
			STA !Scratchram_CharacterTileTable
			LDX #$01
			%UberRoutine(SuppressLeadingZeroes)
			if !Setting_PlayerHP_ExcessDigitProt
				CPX.b #(!Setting_PlayerHP_MaxDigits+1+1)	;>Number of digits at max, plus the "-" symbol, plus one again because it is the first character beyond limits
				BCS ..Done
			endif
			if !Setting_PlayerHP_DisplayDamageTotal == 1
				%WriteTileAddress(!Setting_PlayerHP_DamageNumber_XYPos, !Setting_PlayerHP_DamageNumber_XYPosProp, !Setting_PlayerHP_DamageNumber_Prop)
			elseif !Setting_PlayerHP_DisplayDamageTotal == 2
				%WriteTileAddress(!Setting_PlayerHP_DamageNumber_RightAligned_XYPos, !Setting_PlayerHP_DamageNumber_RightAligned_XYPosProp, !Setting_PlayerHP_DamageNumber_Prop)
			endif
			if !Setting_PlayerHP_DisplayDamageTotal == 2
				%ConvertToRightAligned()
			endif
			%WriteAlignedDigitsToLayer3()
			
			..Done
		endif
	.WriteHPRecover
		if !Setting_PlayerHP_DisplayRecoveryTotal
			LDA !Freeram_PlayerHP_RecoveryTotalTimerDisplay
			BEQ ..Done
			..DecrementDisplayTimer
				LDA $13
				AND.b #%00000011
				BNE ...No
				LDA !Freeram_PlayerHP_RecoveryTotalTimerDisplay
				DEC
				STA !Freeram_PlayerHP_RecoveryTotalTimerDisplay
				BNE ...SkipClear
				LDA #$00
				STA !Freeram_PlayerHP_RecoveryTotalDisplay
				if !Setting_PlayerHP_TwoByte != 0
					STA !Freeram_PlayerHP_RecoveryTotalDisplay+1
				endif
				BRA ..Done ;>Prevent "-0" for 1 frame when timer ends
				...SkipClear
				...No
			%GetHealthDigits(!Freeram_PlayerHP_RecoveryTotalDisplay)
			LDA.b #!StatusBarPlusSymbol
			STA !Scratchram_CharacterTileTable
			LDX #$01
			%UberRoutine(SuppressLeadingZeroes)
			if !Setting_PlayerHP_ExcessDigitProt
				CPX.b #(!Setting_PlayerHP_MaxDigits+1+1)	;>Number of digits at max, plus the "-" symbol, plus one again because it is the first character beyond limits
				BCS ..Done
			endif
			if !Setting_PlayerHP_DisplayRecoveryTotal == 1
				%WriteTileAddress(!Setting_PlayerHP_RecoverNumber_XYPos, !Setting_PlayerHP_RecoverNumber_XYPosProp, !Setting_PlayerHP_RecoverNumber_Prop)
			elseif !Setting_PlayerHP_DisplayRecoveryTotal == 2
				%WriteTileAddress(!Setting_PlayerHP_RecoverNumber_RightAligned_XYPos, !Setting_PlayerHP_RecoverNumber_RightAligned_XYPosProp, !Setting_PlayerHP_RecoverNumber_Prop)
			endif
			if !Setting_PlayerHP_DisplayRecoveryTotal == 2
				%ConvertToRightAligned()
			endif
			%WriteAlignedDigitsToLayer3()
			
			..Done
		endif
	PLB
	RTL
	
	if !Setting_PlayerHP_DisplayBarLevel
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
			LDA.b #!Setting_PlayerHP_GraphicalBar_LeftPieces	;\Left end normally have 3 pieces.
			STA !Scratchram_GraphicalBar_LeftEndPiece		;/
			LDA.b #!Setting_PlayerHP_GraphicalBar_MiddlePieces	;\Number of pieces in each middle byte/8x8 tile
			STA !Scratchram_GraphicalBar_MiddlePiece		;/
			LDA.b #!Setting_PlayerHP_GraphicalBar_RightPieces	;\Right end
			STA !Scratchram_GraphicalBar_RightEndPiece		;/
			LDA.b #!Setting_PlayerHP_GraphicalBarMiddleLengthLevel	;\length (number of middle tiles)
			STA !Scratchram_GraphicalBar_TempLength			;/
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
	if !Setting_PlayerHP_LowHPWarning_CanPaletteChange
		CurrentAndMaxHPPropsCycle:
		db !Setting_PlayerHP_CurrentAndMax_Level_Prop
		db !Setting_PlayerHP_CurrentAndMax_Level_LowHP_Prop
		GraphicalBarPropsCycle:
		db !Setting_PlayerHP_Bar_Level_Prop|(!Setting_PlayerHP_LeftwardsBarLevel<<6)
		db !Setting_PlayerHP_Bar_Level_LowHP_Prop|(!Setting_PlayerHP_LeftwardsBarLevel<<6)
	endif