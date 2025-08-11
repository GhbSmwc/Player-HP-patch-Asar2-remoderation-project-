;Gamemode init 0D (overworld fade in, executes once (to prevent
;top screen flickering)).

;This restores HP when the player returns to the map, most of these
;restores HP after the player dies.

incsrc "../StatusBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../GraphicalBarDefines.asm"
incsrc "../MotherHPDefines.asm"

init:

	.RecoverDeath
	LDA $1B87|!addr			;\If during a continue/end gameover, display 0HP.
	BNE ..NoRecover			;/
	if !Setting_PlayerHP_OverworldRecovery == 0
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_CurrentHP	;\If HP not empty, don't refill
		BNE ..NoHeal			;/

		LDA !Freeram_PlayerHP_MaxHP	;\Fully restore HP
		STA !Freeram_PlayerHP_CurrentHP	;/

		..NoHeal
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
		
	elseif !Setting_PlayerHP_OverworldRecovery == 1
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_MaxHP	;\Always heal to full HP.
		STA !Freeram_PlayerHP_CurrentHP	;/
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
	elseif !Setting_PlayerHP_OverworldRecovery == 2
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_CurrentHP				;\If HP not empty, don't refill
		BNE ..NoHeal						;/
		if !Setting_PlayerHP_TwoByte == 0
			LDA.b #!Setting_PlayerHP_HPSetAfterDeath	;\Set HP to specific amount.
		else
			LDA.w #!Setting_PlayerHP_HPSetAfterDeath
		endif
		STA !Freeram_PlayerHP_CurrentHP				;/

		..NoHeal
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
	elseif !Setting_PlayerHP_OverworldRecovery == 3
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_CurrentHP	;\If HP not empty, don't refill
		BNE ..NoHeal			;/
		LDA !Freeram_PlayerHP_MaxHP
		LSR				;>Divide by 2
		if !Setting_PlayerHP_TwoByte == 0
			ADC #$00		;>Add by 1 if carry set (round 1/2 up)
		else
			ADC #$0000		;>Add by 1 if carry set (round 1/2 up)
		endif
		STA !Freeram_PlayerHP_CurrentHP	;>And set HP 1/2 of max.

		..NoHeal
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
	endif
	..NoRecover
	
	if !Setting_PlayerHP_RollingHP != 0
		.CancelDamageRollingHP
		LDA !Freeram_PlayerHP_MotherHPDirection			;\If player is in heal mode and goes to map,
		BNE ..Done						;/don't cancel the remaining HP to heal.
		
		LDA #$00						;\Cancel out the remaining damage
		STA !Freeram_PlayerHP_MotherHPChanger			;|
		if !Setting_PlayerHP_TwoByte != 0
			STA !Freeram_PlayerHP_MotherHPChanger+1		;/
		endif
		
		..Done
	endif
	RTL