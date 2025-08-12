incsrc "../StatusBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../MotherHPDefines.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Damage the player (made for blocks,
;knockback not included).
;
;Input:
;$00: (8/16-bit) the amount of HP loss.
;
;This also kills the player if HP hits zero,
;unlike the main patch.
;
;Note that this routine itself doesn't
;check invulnerability.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?DamagePlayer:
	LDA $1407|!addr			;\If not flying
	BEQ ?++				;/
	JSL $00F5E2|!bank		;>Cancel soaring instead
	RTL
	
	?++
	;Damage player
	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages		;\Set invulnerability timer
	STA $1497|!addr					;/
	if !Setting_PlayerHP_RollingHP == 0
		;^If you're not using rolling HP (instant subtraction)
		if !Setting_PlayerHP_TwoByte == 0
			;^8-bit HP
			LDA !Freeram_PlayerHP_CurrentHP		;\SubtractedHP = Health - damage
			SEC					;|
			SBC $00					;/
			BCS ?++					;>If value didn't subtract by larger value, go write HP.
			LDA #$00				;>Otherwise set HP to 0.
			
			?++
			STA !Freeram_PlayerHP_CurrentHP		;>Write difference to current HP.
		else
			;16-bit health
			REP #$20				;>16-bit A
			LDA !Freeram_PlayerHP_CurrentHP		;\SubtractedHP = Health - damage
			SEC					;|
			SBC $00					;/
			BCS ?++					;>If subtracted by a smaller or equal to current HP number, subtract as usual
			LDA #$0000				;>Otherwise if the player suffers larger damage, set HP to 0 and kill.
			
			?++
			STA !Freeram_PlayerHP_CurrentHP		;>Write difference to current HP.
			SEP #$20
		endif
	else
		;rolling HP code.
		;
		;this uses CLC : ADC to allow damage to stack when the player
		;takes damage while HP is counting down.
		LDA !Freeram_PlayerHP_MotherHPDirection			;\Check if the player is healing or under HP drain
		BEQ ?+++							;/(if mario is currently having an HP countdown, stack it)
		if !Setting_PlayerHP_TwoByte == 0
			LDA $00						;\Otherwise if the player is currently having a countup, then replace healing with damage
			BRA ?++
		else
			REP #$20
			LDA $00
			BRA ?++
		endif
		
		?+++
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_MotherHPChanger			;\Add more remaining damage to the stacker
		CLC							;|
		ADC $00							;|
		BCC ?++							;/
		if !Setting_PlayerHP_TwoByte == 0
			LDA #$FF					;|
			
			?++
			STA !Freeram_PlayerHP_MotherHPChanger		;|
		else
			LDA #$FFFF					;|
			
			?++
			STA !Freeram_PlayerHP_MotherHPChanger		;|
			SEP #$20					;/
		endif
		?.SetToDamage
		LDA #$00						;\Set to damage the player (countdown mode)
		STA !Freeram_PlayerHP_MotherHPDirection			;/
		;LDA #$00						;\Initially start out with first decrement immediately.
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer		;/(prevents delay when the player transitions from heal to damage)
	endif
	if and(notequal(!Setting_PlayerHP_BarChangeDelay, 0), notequal(!Setting_PlayerHP_BarAnimation, 0))	;\display transparent segment when the player gets killed
		LDA.b #!Setting_PlayerHP_BarChangeDelay								;|
		STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr							;|
	endif												;/
	
	LDA !Freeram_PlayerHP_CurrentHP				;\Check if HP = 0
	if !Setting_PlayerHP_TwoByte != 0			;|
		ORA !Freeram_PlayerHP_CurrentHP+1			;/
	endif
	BEQ ?++							;>if mario dies, skip
	
	;DamageAndSurvive
	if !Setting_PlayerHP_LosePowerupOnDamage != 0
		LDA #$01					;\lose powerup
		STA $19						;/
	endif
	LDA #$04						;\SFX (pipe)
	STA $1DF9|!addr						;/
	STZ $14A6|!addr						;>Cancel cape spin (in the original, mario retains his spin pose after damage)
	
	;Add code here that runs when the player takes damage (but not when the player dies).
	
	RTL
	
	?++
	JSL $00F606|!bank						;>Kill player
	
	;Add code here that runs 1 frame the player dies.
	RTL