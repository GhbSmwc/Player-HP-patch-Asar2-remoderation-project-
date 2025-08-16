incsrc "../StatusBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../MotherHPDefines.asm"
incsrc "../GraphicalBarDefines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This subroutine cancels out the graphical bar's damage/recovery display
;
;This is needed so that if your max HP changes, will not misleadingly
;display that you have healed or taken damage (since the percentage changes
;also if the denominator of the fraction changes. For example, having 10/10
; (100%) HP, and when the player picks up a +10 max HP without affecting
;his current HP, he would have 10/20 (50%) HP, and this can cause the
;graphical bar's damage indicator to show.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	LDA.b #!Setting_PlayerHP_GraphicalBarMiddleLengthLevel		;\length (number of middle tiles)
	STA !Scratchram_GraphicalBar_TempLength				;/
	if !Setting_PlayerHP_BarFillRoundDirection == 0
		%GraphicalBar_CalculatePercentage()
	elseif !Setting_PlayerHP_BarFillRoundDirection == 1
		%GraphicalBar_CalculatePercentageRoundDown()
	elseif !Setting_PlayerHP_BarFillRoundDirection == 2
		%GraphicalBar_CalculatePercentageRoundUp()
	endif
	;$00~$01 = percentage
	if !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 1
		%GraphicalBar_RoundAwayEmpty()
	elseif !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 2
		%GraphicalBar_RoundAwayFull()
	elseif !Setting_PlayerHP_GraphicalBar_RoundAwayEmptyFull == 3
		%GraphicalBar_RoundAwayEmptyFull()
	endif
	LDA $00
	STA !Freeram_PlayerHP_BarRecord
	RTL