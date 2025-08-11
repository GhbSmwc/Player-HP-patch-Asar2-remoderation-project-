	incsrc "../StatusBarDefines.asm"
	incsrc "../PlayerHPDefines.asm"
	incsrc "../MotherHPDefines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Hurt player (merely subtracts HP and nothing else, useful
	;if you want certain damage to ignore invulnerability or
	;during a cutscene to display 0 HP without playing the
	;death animation)
	;
	;Input:
	; $00 (8/16-bit) = amount of HP loss.
	;
	;Automatically writes to !Freeram_PlayerCurrHP. Does not
	;subtract HP to below zero.
	;
	;The conditions here are different unlike the block or
	;patch version, as even if you enabled rolling HP, the
	;add/subtract HP by x amount per interval requires this,
	;and does not use the rolling HP system.
	;
	;For some reason, if you need a standard damage routine
	;(non-rolling) and have "!Setting_PlayerHP_GradualHPChange"
	;disabled (you're not using the gradual heal or damage
	;blocks) on uberasm tool, comment out
	;"if !Setting_PlayerHP_GradualHPChange != 0" and the
	;"endif" before "if !Setting_PlayerHP_RollingHP != 0".
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?SubtractPlayerHPNonRoll:
	if !Setting_PlayerHP_TwoByte == 0
		LDA !Freeram_PlayerCurrHP		;\Health - damage
		SEC					;|
		SBC $00					;/
		BCS ?.NotPastZero			;>If value didn't subtract by larger value, go write HP.
		
		?.PastZero
		LDA #$00				;>Otherwise set HP to 0.
		
		?.NotPastZero
		STA !Freeram_PlayerCurrHP		;>Write HP value.
	else
		REP #$20
		LDA !Freeram_PlayerCurrHP
		SEC
		SBC $00
		BCS ?.NotPastZero
		
		?.PastZero
		LDA #$0000
		
		?.NotPastZero
		STA !Freeram_PlayerCurrHP
		SEP #$20
	endif
	RTL