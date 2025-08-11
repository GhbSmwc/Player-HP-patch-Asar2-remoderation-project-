;Run this as "level"

incsrc "../StatusBarDefines.asm"
incsrc "../GraphicalBarDefines.asm"
incsrc "../MotherHPDefines.asm"
incsrc "../PlayerHPDefines.asm"

init:
	if !Setting_PlayerHP_Knockback != 0
		LDA #$00
		STA !Freeram_PlayerHP_Knockback
	endif
	RTL
main:
	if !Setting_PlayerHP_RollingHP != 0
		.RollingHP
		LDA $9D						;\Freeze if time is frozen
		ORA $13D4|!addr					;|
		ORA $1426|!addr					;|>In vanilla smw, message box doesn't set $9D
		;ORA <RAM to freeze>				;>Template if you want other stuff to freeze damage.
		BEQ +
		JMP ..DecrementDelayDone			;/
		+
		
		..CancelDamageCheck
		LDA !Freeram_PlayerHP_MotherHPDirection		;\If healing, don't allow canceling how much HP to fill.
		BNE ..ChangeHPCheck				;/
		
		LDA $1493|!addr					;\If level isn't end (not hitting the goal), allow HP decrement
		;ORA <address>					;>custom RAM that when set also cancel damage.
		BEQ ..ChangeHPCheck				;/
		
		...RemoveDamage
		if !Setting_PlayerHP_TwoByte == 0		;\Cancel damage when the player isn't meant to die at certain situations.
			LDA #$00				;|
			STA !Freeram_PlayerHP_MotherHPChanger	;|
		else
			REP #$20				;|
			LDA #$0000				;|
			STA !Freeram_PlayerHP_MotherHPChanger	;|
			SEP #$20				;/
		endif
		..ChangeHPCheck
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_MotherHPChanger	;\If there is no HP to be changed (no damage or healing),
			BNE +
			JMP ..DecrementDelayZero		;|then set the timer between each HP tick to 0.
			+
		else
			REP #$20				;|
			LDA !Freeram_PlayerHP_MotherHPChanger	;|
			SEP #$20				;|
			BNE +
			JMP ..DecrementDelayZero		;/
			+
		endif
		
		..DelayBetweenTicks
		LDA !Freeram_PlayerHP_MotherHPDelayFrameTimer	;\if timer is 0, change HP
		BEQ ..ChangeHP					;/
		DEC						;\Decrement timer
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer	;/
		BEQ ..ChangeHP					;>if decremented to zero, also allow change HP
		BRA ..DecrementDelayDone			;>Otherwise don't do anything between ticks
		
		..ChangeHP
		LDA !Freeram_PlayerHP_MotherHPDirection		;\Heal or damage?
		BEQ ...DamageTimer				;/
		
		...HealTimer
		LDA.b #!Setting_PlayerHP_MotherHPDelayRecoverLast	;>The next increment HP
		BRA ...SetTimer
		
		...DamageTimer
		LDA !Freeram_PlayerHP_MotherHPDelayDamageLast	;>The next decrement HP
		
		...SetTimer
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer
		
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_MotherHPChanger	;\Decrement how much HP left to heal or to damage
			DEC					;|
			STA !Freeram_PlayerHP_MotherHPChanger	;|
		else
			REP #$20				;|
			LDA !Freeram_PlayerHP_MotherHPChanger	;|
			DEC					;|
			STA !Freeram_PlayerHP_MotherHPChanger	;|
			SEP #$20				;/
		endif
		
		LDA !Freeram_PlayerHP_MotherHPDirection		;\taking damage or healing?
		BEQ ...Damage					;/
		;CMP #$01					;\In case if your hack have custom stuff (which is unlikely)
		;BEQ ...Heal
		;CMP #$02
		;BEQ ...Custom0
		
		...Heal
		if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0))
			if !Setting_PlayerHP_ShowHealedTransparent != 0
				LDA.b #!Setting_PlayerHP_BarChangeDelay			;\This is so that each tick freezes
				STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr		;/record instead of the inital grab of a healing item.
			endif
		endif
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_CurrentHP		;\Increment HP
			CMP #$FF
			BEQ ....FullHP
			INC					;|
			CMP !Freeram_PlayerHP_MaxHP
			BCC ....NotFullHP
			
			....FullHP
			LDA #$00				;|\Stop healing if player HP is full.
			STA !Freeram_PlayerHP_MotherHPChanger	;|/
			LDA !Freeram_PlayerHP_MaxHP
			
			....NotFullHP
			STA !Freeram_PlayerHP_CurrentHP		;|
		else
			REP #$20				;|
			LDA !Freeram_PlayerHP_CurrentHP		;|
			CMP #$FFFF				;|\In case if it attempts to overflow.
			BEQ ....FullHP				;|/
			INC					;|
			CMP !Freeram_PlayerHP_MaxHP		;|
			BCC ....NotFullHP			;|
			
			....FullHP
			LDA #$0000				;|\Stop healing if player HP is full.
			STA !Freeram_PlayerHP_MotherHPChanger	;|/
			LDA !Freeram_PlayerHP_MaxHP		;|
			
			....NotFullHP
			STA !Freeram_PlayerHP_CurrentHP		;|
			SEP #$20				;/
		endif
		BRA ..DecrementDelayDone
		
		...Damage
		if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0))
			LDA.b #!Setting_PlayerHP_BarChangeDelay
			STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
		endif
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_CurrentHP		;\Subtract HP
			BEQ ....Death				;|
			DEC					;|
			STA !Freeram_PlayerHP_CurrentHP		;|
			BEQ ....Death				;>Prevent damage equal to player's HP from landing on 0HP without dying.
			BRA ..DecrementDelayDone
			
			....Death
			JSL $00F606|!bank			;>kill player
			LDA #$00				;|\stop decrementing the already 0HP.
			STA !Freeram_PlayerHP_MotherHPChanger	;|/
		else
			REP #$20				;|
			LDA !Freeram_PlayerHP_CurrentHP		;|
			BEQ ....Death				;|
			DEC					;|
			STA !Freeram_PlayerHP_CurrentHP		;|
			BEQ ....Death				;>Prevent damage equal to player's HP from landing on 0HP without dying.
			SEP #$20
			BRA ..DecrementDelayDone
			
			....Death
			SEP #$20				;>8-bit mode
			JSL $00F606|!bank			;>kill player
			LDA #$00				;\stop decrementing the already 0HP.
			STA !Freeram_PlayerHP_MotherHPChanger	;|
			STA !Freeram_PlayerHP_MotherHPChanger+1	;/
		endif
		
		
		..DecrementDelayZero
		LDA #$00
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer
		
		..DecrementDelayDone
	endif
	
	if !Setting_PlayerHP_Knockback != 0
		.PlayerKnockBackStun
		..DeathPoseCheck
		LDA $71				;\Any animation that isn't powerup, don't apply to such actions.
		CMP #$05			;|
		BCS ..CancelStun		;/
		
		LDA !Freeram_PlayerHP_Knockback	;\If not stun, don't reset controller
		BEQ ..Done			;/
		LDA $75				;\If in water, ignore stun
		BNE ..CancelStun		;/
		if or(equal(!Setting_PlayerHP_Knockback, 1), equal(!Setting_PlayerHP_Knockback, 2)) ;>When user set it to use the timer
			LDA $9D			;>If frozen
			ORA $13D4|!addr		;>Or paused
			ORA $1426|!addr		;>Or message box open
			;ORA <address>		;>Custom RAM that freezes timer.
			BNE ..FreezeTimer	;>Then freeze timer

			..DecrementTimer
			LDA !Freeram_PlayerHP_Knockback	;\Stun countdown
			DEC				;|
			STA !Freeram_PlayerHP_Knockback	;/

			..FreezeTimer
		endif
		if !Setting_PlayerHP_Knockback >= 2 ;>If the user sets it to cancel stun when touching the ground.
			LDA $77					;\If on ground, cancel stun
			AND.b #%00000100			;|(reguardless if knockback type is "until land"
			BNE ..CancelStun			;/or timer)
		endif
		LDA $1426|!addr				;>If message box
		;ORA $xxxxxx				;>Or if custom RAM (if you have event that have controls that is not player character-related, such as menus).
		;ORA $yyyyyy
		BNE ..NoResetControls			;>If at least one RAM is non-zero, don't disable controls.

		..Stunplayer
		LDA.b #%11001111			;\Disable controls that affects the player character
		TRB $15					;|
		TRB $16					;|
		LDA.b #%11000000			;|
		TRB $17					;|
		TRB $18					;/
		LDA $140D|!addr				;\Don't have the spinning animation applying to
		BNE ..Done				;/the pose (probably that this is the only time I override smw's spinjump flag).
		LDA.b #!Setting_PlayerHP_StunPose		;\Set player pose
		STA $13E0|!addr				;/
		BRA ..Done

		..CancelStun
		LDA #$00
		STA !Freeram_PlayerHP_Knockback


		..NoResetControls
		..Done
	endif
	if !Setting_PlayerHP_GradualHPChange != 0
		.SlowHPChange
		LDA !Freeram_PlayerHP_GradualHPChange
		BEQ ..Return			;>if (already) = 0, no HP alterations
		BPL ..Heal			;>If > 0, incease HP

		..Damage
		if !Setting_PlayerHP_RollingHP != 0
			;Cancel counting up HP:
			LDA !Freeram_PlayerHP_MotherHPDirection		;\If HP counting down, leave the amount of HP to count down be
			BEQ ...DontCancelDamage				;/
			if !Setting_PlayerHP_TwoByte == 0
				LDA #$00
				STA !Freeram_PlayerHP_MotherHPChanger
			else
				REP #$20
				LDA #$0000
				STA !Freeram_PlayerHP_MotherHPChanger
				SEP #$20
			endif
			
			...DontCancelDamage
		endif
		LDA !Freeram_PlayerHP_GradualHPChange
		EOR #$FF					;\Positive damage value
		INC						;|
		STA $00						;|
		STZ $01						;/>HP gradual change doesn't have a high byte.
		%UberRoutine(SubtractPlayerHPNonRoll)		;>Of course, both the filename and the label to jump to is required in uberasm tool's library (avoid having the same name).
		LDA !Freeram_PlayerHP_CurrentHP			;\Kill player on 0HP
		if !Setting_PlayerHP_TwoByte != 0		;|
			ORA !Freeram_PlayerHP_CurrentHP		;|
		endif						;|
		BNE ..ClearSlowHPChange				;/
		
		...Death
		JSL $00F606|!bank		;>Make mario die
		BRA ..ClearSlowHPChange		;>And clear itself to prevent excuting the death every frame.

		..Heal
		if !Setting_PlayerHP_RollingHP != 0
			;Cancel counting down HP:
			PHA
			LDA !Freeram_PlayerHP_MotherHPDirection		;\If healing, leave the amount of HP to heal be
			BNE ...DontCancelHealing			;/
			if !Setting_PlayerHP_TwoByte == 0
				LDA #$00
				STA !Freeram_PlayerHP_MotherHPChanger
			else
				REP #$20
				LDA #$0000
				STA !Freeram_PlayerHP_MotherHPChanger
				SEP #$20
			endif
			
			...DontCancelHealing
			PLA
		endif
		STA $00					;>Store heal amount
		STZ $01					;>Remove high byte since gradual heal is a single byte.
		%UberRoutine(RecoverPlayerHP)

		..ClearSlowHPChange
		LDA #$00				;\And clear itself to not perform this code on the next frame after the player gets off.
		STA !Freeram_PlayerHP_GradualHPChange	;/

		..Return
	endif
	RTL