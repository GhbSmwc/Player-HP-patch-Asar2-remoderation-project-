;Insert this as gamemode $07
;
;This is a failsafe so that when the player enters the level after booting up the game
;will have the damage and recovery display not be shown and not have potential
;uninitialized values.
	incsrc "../StatusBarDefines.asm"
	incsrc "../PlayerHPDefines.asm"
	init:
		if !Setting_PlayerHP_TwoByte
			REP #$20
			LDA.w #$0000
		else
			LDA.b #$00
		endif
		if !Setting_PlayerHP_DisplayDamageTotal
			STA !Freeram_PlayerHP_DamageTotalDisplay
		endif
		if !Setting_PlayerHP_DisplayRecoveryTotal
			STA !Freeram_PlayerHP_RecoveryTotalDisplay
		endif
		if !Setting_PlayerHP_TwoByte
			SEP #$20
		endif
		if !Setting_PlayerHP_DisplayDamageTotal
			STA !Freeram_PlayerHP_DamageTotalTimerDisplay
		endif
		if !Setting_PlayerHP_DisplayRecoveryTotal
			STA !Freeram_PlayerHP_RecoveryTotalTimerDisplay
		endif
		RTL