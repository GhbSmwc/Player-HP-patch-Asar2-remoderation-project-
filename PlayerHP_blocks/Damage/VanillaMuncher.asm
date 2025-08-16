;Behaves $130

;Unlike blockreator, this block, when touched on the side without ovelapping
;(ovelapping as in, moving into the block) with mario's hitbox will not damage
;the player, this happens on the origional smw (the spikes from ghost houses
;and castles too).

;You can also set what side not to hurt mario (but it will instead, act like a
;harmless cement block, why would you allow the player to walk through a solid
;muncher?!), Like in NSMBWII in world 9-7 (oh god its ridiculously hard, unless
;if you are mini mario and use spinjump to jump high enough over tall pipes.)

;reverse flags:
; - 0 = muncher when ram flag is 0.
; - 1 = muncher when ram flag non-zero.
	!reverse		= 0

;what ram address switches between muncher and coin:
; *$14AD = blue p-switch.
; *$14AE = silver p-switch
; *$14AF = on/off switch.
	!Ram_Switch		= $14AE|!addr

;Damage type:
; - 0 = fixed damage amount.
; - 1 = damage amount equal to proportion of max HP.
; - 2 = instant kill (regardless of invincibility frames).
	!DamageType		= 0

;Damage when touching the block in muncher form, only used  when !DamageType == 0.
	!FixedDamageAmount		= 5
;Proportion of max HP damage when touching the block in muncher form, only used when
;!DamageType == 1
	!DamageDividend	= 2
	!DamageDivisor	= 5
;Knockback speeds. For left and up speeds, use only values #$80-#$FF with #$80 being the fastest, for
;right/down speeds, use only values #$01-#$7F with #$7F being the fastest speed.
	!MuncherKnockbackUp		= $C0
	!MuncherKnockbackDown		= $70
	!MuncherKnockbackHorizSpd	= !Setting_PlayerHP_KnockbackHorizSpd
	!MuncherKnockbackHorizUpSpd	= !Setting_PlayerHP_KnockbackUpwardsSpd ;>horizontal upwards speed.

; Enable (set to 1) or disable (set to 0) damage on specific side. When Mario touches
; a non-damaging side, would simply act like a solid cement block when in "muncher" mode and
; and always a coin regardless if the side the player touches harms or not if in "coin" mode.
	!Damage_Top		= 1
	!Damage_Bottom		= 1
	!Damage_LeftSide	= 1
	!Damage_RightSide	= 1

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP SpriteV : JMP SpriteH : JMP Return
JMP MarioFireBall : JMP MarioAbove : JMP BodyInside : JMP HeadInside

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

;========================================================================================
MarioAbove:
	LDA !Ram_Switch
	if !Damage_Top != 0
		if !reverse == 0
			BEQ CheckYoshi
		else
			BNE CheckYoshi
		endif
	else
		if !reverse == 0
			BEQ AboveReturn	;>branch out of range
		else
			BNE AboveReturn
		endif
	endif
	JMP Coin
	if !Damage_Top != 0
		CheckYoshi:
		LDA $187A|!addr				;\If riding yoshi, act like a cement block
		BNE AboveReturn				;/
		if !DamageType < 2
			%InvincibilityCheck()
			BNE AboveReturn

			JSR GetDamageAmount
			%DamagePlayer()
			
			
			if !Setting_PlayerHP_Knockback != 0
				LDA.b #!Setting_PlayerHP_KnockbackLength	;\Set mario to be stunned
				STA !Freeram_PlayerHP_Knockback		;/
				LDA $71					;\Prevent altering dying mario's Y speed.
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
	LDA !Ram_Switch
	if or(notequal(!Damage_LeftSide, 0), notequal(!Damage_RightSide, 0))
		if !reverse == 0
			BEQ ContactSide
		else
			BNE ContactSide
		endif
	else
		if !reverse == 0
			BEQ SideReturn
		else
			BNE SideReturn
		endif
	endif
	JMP Coin

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
		
		SideDamage:
		if !DamageType < 2
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
	RTL
;========================================================================================
MarioBelow:
BodyInside:
	LDA !Ram_Switch
	if !Damage_Bottom != 0
		if !reverse == 0
			BEQ MuncherBottom
		else
			BNE MuncherBottom
		endif
	else
		if !reverse == 0
			BEQ Return
		else
			BNE Return
		endif
	endif
	JMP Coin
	if !Damage_Bottom != 0
		MuncherBottom:
		if !DamageType < 2
			%InvincibilityCheck()
			BNE BottomDone
			
			JSR GetDamageAmount
			%DamagePlayer()
			
			if !Setting_PlayerHP_Knockback != 0
				LDA.b #!Setting_PlayerHP_KnockbackLength	;\Set mario to be stunned
				STA !Freeram_PlayerHP_Knockback		;/
				LDA $71					;\Prevent altering dying mario's Y speed
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
		RTL
	endif
;========================================================================================
MarioFireBall:
SpriteV:
SpriteH:
	LDA !Ram_Switch
	if !reverse == 0
		BEQ Return
	else
		BNE Return
	endif
	JSR passable
	
	Return:
	RTL		;>return as a solid
;========================================================================================
	Coin:
	JSR passable		;>coins are not solid!
	INC $13CC|!addr		;>in case the player grabs 2 coins simultaneously
	LDA #$01		;\coin sfx
	STA $1DFC|!addr		;/
	%erase_block()		;>delete block
	;%give_points()		;>give player points (only happens if you get coins from ? and turn blocks)

	;glitter
	PHY			;>protect tile behavor
	PHK			;\the JSL-RTS trick.
	PEA.w .jslrtsreturn-1	;|Thanks LX5 and imamelia!
	PEA.w $84CF-1		;/
	JML $00FD5A		;>glitter subroutine
	.jslrtsreturn
	PLY			;>end protect to avoid stack overflow.
	RTL

	passable:
	LDY #$00
	LDA #$25
	STA $1693|!addr
	RTS
	
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
if !reverse == 0
	print "OMNOMNOMNOMNOMNOMN"
else
	print "NWONWONWONWONWONWO"
endif