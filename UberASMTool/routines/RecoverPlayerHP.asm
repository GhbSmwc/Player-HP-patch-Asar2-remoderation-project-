	incsrc "../PlayerHPDefines.asm"
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Recover player HP.
	;
	;Input:
	; $00 (8/16-bit) = the amount of HP to recover
	;
	;Automatically writes to !Freeram_PlayerCurrHP. Doesn't
	;heal past the maximum HP.
	;
	;Note that this doesn't include the rolling HP
	;(so this ALWAYS instantly heals by a specified amount).
	;This is for use with the gradual heal block.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?RecoverPlayerHP0:
	if !Setting_PlayerHP_TwoByte == 0
		LDA !Freeram_PlayerCurrHP		;\Health + Recovery
		CLC					;|
		ADC $00					;/
		BCC ?.NotMaxed				;>If not exceeding 255, compare with max HP
		CMP !Freeram_PlayerMaxHP		;\If not exceeding max HP, write to HP.
		BCC ?.NotMaxed				;/
		
		?.Maxed
		LDA !Freeram_PlayerMaxHP
		
		?.NotMaxed
		STA !Freeram_PlayerCurrHP
	else
		REP #$20
		LDA !Freeram_PlayerCurrHP
		CLC
		ADC $00
		BCS ?.Maxed				;>If not exceeding 65535
		CMP !Freeram_PlayerMaxHP
		BCC ?.NotMaxed				;>If not exceeding max HP, write to HP.
		
		?.Maxed
		LDA !Freeram_PlayerMaxHP
		
		?.NotMaxed
		STA !Freeram_PlayerCurrHP
		SEP #$20
	endif
	RTL