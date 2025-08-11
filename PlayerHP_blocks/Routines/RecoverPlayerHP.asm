incsrc "../StatusBarDefines.asm"
incsrc "../PlayerHPDefines.asm"
incsrc "../MotherHPDefines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Recover player HP.
	;
	;Input:
	; $00 (8/16-bit) = the amount of HP to recover
	;
	;Automatically writes to !Freeram_PlayerHP_CurrentHP. Doesn't
	;heal past the maximum HP.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if !Setting_PlayerHP_RollingHP == 0
		;Not using rolling HP here
		if !Setting_PlayerHP_TwoByte == 0
			;8-bit health
			LDA !Freeram_PlayerHP_CurrentHP		;\Health + Recovery
			CLC					;|
			ADC $00					;/
			BCC ?+					;>If not exceeding 255, compare with max HP
			CMP !Freeram_PlayerHP_MaxHP		;\If not exceeding max HP, write to HP.
			BCC ?+					;/
			
			;.Maxed
			LDA !Freeram_PlayerHP_MaxHP		;>>Prevent healing over the maximum HP.
			
			?+
			STA !Freeram_PlayerHP_CurrentHP
		else
			;16-bit health
			REP #$20
			LDA !Freeram_PlayerHP_CurrentHP
			CLC
			ADC $00
			BCS ?+					;>If not exceeding 65535
			CMP !Freeram_PlayerHP_MaxHP
			BCC ?++					;>If not exceeding max HP, write to HP.
			
			?+
			LDA !Freeram_PlayerHP_MaxHP		;>Prevent healing over the maximum HP.
			
			?++
			STA !Freeram_PlayerHP_CurrentHP
			SEP #$20
		endif
		if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0))
			if !Setting_PlayerHP_BarChangeDelay != 0
				LDA.b #!Setting_PlayerHP_BarChangeDelay									;\Freeze record to represent HP healed.
				STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr								;/
			endif
		endif
		RTL
	else
		;Rolling HP
		LDA !Freeram_PlayerHP_MotherHPDirection		;\If player's HP is currently counting upwards, stack the healing
		BNE ?+						;/
		if !Setting_PlayerHP_TwoByte == 0
			LDA $00					;\Otherwise cancel damage countdown
			BRA ?++					;|
		else
			REP #$20				;|
			LDA $00					;|
			BRA ?++					;/
		endif
		?+
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_MotherHPChanger		;\Stack healing
		CLC						;|
		ADC $00						;/
		BCC ?++						;>Prevent overflow
		if !Setting_PlayerHP_TwoByte == 0
			.Maxed
			LDA #$FF				;\Apply stack healing
			
			?++					;|
			STA !Freeram_PlayerHP_MotherHPChanger	;/
		else
			.Maxed					;\Same as above, but 16-bit
			LDA #$FFFF				;|
			
			?++					;|
			STA !Freeram_PlayerHP_MotherHPChanger	;|
			SEP #$20				;/
		endif
		LDA #$01						;\Set direction to count upwards
		STA !Freeram_PlayerHP_MotherHPDirection			;/
		LDA #$00						;\Initially start out with first increment immediately.
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer		;/
		if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0))
			if !Setting_PlayerHP_BarChangeDelay != 0
				LDA.b #!Setting_PlayerHP_BarChangeDelay			;\Freeze record to represent HP healed.
				STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr		;/
			endif
		endif
		RTL
	endif