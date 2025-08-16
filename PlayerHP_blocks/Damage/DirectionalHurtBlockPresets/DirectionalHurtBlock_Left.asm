;Behaves $130

;Same as the muncher block, but is unaffected by any switches.

;Enable (set to 1) or disable (set to 0) damage on specific side.
	!Damage_Top		= 0
	!Damage_Bottom		= 0
	!Damage_LeftSide	= 1
	!Damage_RightSide	= 0


;Same as Damage_Top defines above, but for riding yoshi.
	!Damage_TopRidingYoshi	= 0

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP SpriteV : JMP SpriteH : JMP Return
JMP MarioFireBall : JMP MarioAbove : JMP BodyInside : JMP HeadInside

incsrc "../../../../StatusBarDefines.asm"
incsrc "../../../../PlayerHPDefines.asm"
incsrc "../../../../MotherHPDefines.asm"
incsrc "DirectionalHurtBlockPresetsCommonDefines.asm"

;========================================================================================
MarioAbove:
	if !Damage_Top != 0
		if !Damage_TopRidingYoshi == 0
			;CheckYoshi:
			LDA $187A|!addr				;\If riding yoshi, act like a cement block
			BNE AboveReturn				;/
		endif
		if !DamageType < 2
			%InvincibilityCheck()			;\Don't hurt if invincible.
			BNE AboveReturn				;/
			JSR GetDamageAmount
			%DamagePlayer()
			
			if !Setting_PlayerHP_Knockback != 0
				LDA.b #!Setting_PlayerHP_KnockbackLength	;\Set mario to be stunned
				STA !Freeram_PlayerHP_Knockback		;/
				LDA $71					;\Prevent affecting dying mario's Y speed
				CMP #$09				;|
				BEQ +					;/
				LDA.b #!MuncherKnockbackUp		;\Fling mario upward
				STA $7D					;/
				STZ $7B					;>Prevent horizontal movement (previously, this would've allow advantage of going backwards).
				
				+
			endif
		else
			JSL $00F606|!bank
		endif
	endif
	AboveReturn:
	RTL		;>and return (as a solid)

;========================================================================================
MarioSide:
HeadInside:
	if or(notequal(!Damage_LeftSide, 0), notequal(!Damage_RightSide, 0))
		ContactSide:
		if !DamageType < 2
			%InvincibilityCheck()			;\Don't hurt the player if invincible,
			BNE SideReturn				;/
		endif
		%SideContactCheck()			;>Check if player is 1 pixel or more inside the block than he should be
		BEQ SideReturn				;>if not, return.
		
		if !Damage_LeftSide == 0		;\act as a solid cement block if the player touches the harmless right/left side
			CMP #$01			;|
			BEQ SideReturn			;|
		endif					;|
		if !Damage_RightSide == 0		;|
			CMP #$02			;|
			BEQ SideReturn			;|
		endif					;/
		if !DamageType < 2
			SideDamage:
			PHA
			JSR GetDamageAmount
			%DamagePlayer()
			PLA
			if !Setting_PlayerHP_Knockback != 0
				LDX.b #!MuncherKnockbackHorizSpd
				STX $00
				LDX.b #!MuncherKnockbackHorizUpSpd
				STX $01
				%HorizKnockback()
				LDA.b #!Setting_PlayerHP_KnockbackLength		;\Set mario to be stunned
				STA !Freeram_PlayerHP_Knockback			;/
			endif
		else
			JSL $00F606|!bank
		endif
	endif
	SideReturn:
	Return:
	RTL
;========================================================================================
MarioBelow:
BodyInside:
	if !Damage_Bottom != 0
		if !DamageType < 2
			%InvincibilityCheck()				;\Don't hurt if invincible
			BNE BottomDone					;/
			JSR GetDamageAmount
			%DamagePlayer()
			
			if !Setting_PlayerHP_Knockback != 0
				LDA.b #!Setting_PlayerHP_KnockbackLength	;\Set mario to be stunned
				STA !Freeram_PlayerHP_Knockback		;/
				LDA $71					;\Prevent affecting dying mario's Y speed
				CMP #$09				;|
				BEQ +					;/
				LDA.b #!MuncherKnockbackDown		;\Fling mario downward
				STA $7D					;/
				
				+
			endif

			BottomDone:
		else
			JSL $00F606|!bank
		endif
	endif
MarioFireBall:
SpriteV:
SpriteH:
	RTL		;>return as a solid
	if !DamageType < 2
		GetDamageAmount:
			if !DamageType == 0
				if !Setting_PlayerHP_TwoByte == 0
					LDA.b #!FixedDamageAmount
					STA $00
				else
					REP #$20
					LDA.w #!FixedDamageAmount
					STA $00
					SEP #$20
				endif
			else
				;Damage = MaxHP*Dividend/Divisor  ;>if Dividend is > 1
				;Damage = MaxHP/Divisor           ;>if Dividend is = 1
				if !Setting_PlayerHP_TwoByte == 0
					LDA !Freeram_PlayerHP_MaxHP
					if !DamageDividend > 1
						STA $00							;\MaxHP...
						STZ $01							;/
						REP #$20						;\...Times dividend
						LDA.w #!DamageDividend					;|
						STA $02							;|
						SEP #$20						;|
						PHY							;|
						%MathMul16_16()						;|
						PLY							;/
						REP #$20
						LDA $04							;\Product...
						STA $00							;|
						LDA $06							;|
						STA $02							;/
					else
						STA $00
						STZ $01
						STZ $02
						STZ $03
					endif
					REP #$20						;\...divide by divisor
					LDA.w #!DamageDivisor					;|
					STA $04							;|
					SEP #$20						;|
					PHY							;|
					%MathDiv32_16()						;/;>$00 should be <= $FFFF
					PLY
				else
					REP #$20
					LDA !Freeram_PlayerHP_MaxHP
					if !DamageDividend > 1
						STA $00
						LDA.w #!DamageDividend
						STA $02
						SEP #$20
						PHY
						%MathMul16_16()
						PLY
						REP #$20
						LDA $04
						STA $00
						LDA $06
						STA $02
					else
						STA $00
						STZ $02
					endif
					LDA.w #!DamageDivisor
					STA $04
					SEP #$20
					PHY
					%MathDiv32_16() ;>$00 should be <= $FFFF
					PLY
				endif
				;Rounding to nearest integer
				
				.Round
				REP #$20
				LDA.w #round(!DamageDivisor/2, 0)				;\If HalfDivisor > Remainder (remainder smaller), don't round quotient.
				CMP $04								;/
				BEQ ..RoundQuotient						;>If =, round up
				BCS ..NoRoundQuotient
				
				..RoundQuotient
				INC $00
				
				..NoRoundQuotient
				;Check if rounded down to zero:
				.HealAtLeast1HP
				LDA #$0001
				CMP $00
				BCC ..ValidHealing					;>if 1 < $00 (or $00 greater than 1), don't set $00 to 1.
				STA $00
				
				..ValidHealing
				SEP #$20
			endif
		RTS
	endif
;========================================================================================
if !DamageType == 0
	print "Deals ", dec(!FixedDamageAmount), " damage to the player on left side of block."
elseif !DamageType == 1
	print "Deals ", dec(!DamageDividend), "/", dec(!DamageDivisor), " of the player's maximum HP on left side of block."
else
	print "Instantly kills the player on left side of block."
endif