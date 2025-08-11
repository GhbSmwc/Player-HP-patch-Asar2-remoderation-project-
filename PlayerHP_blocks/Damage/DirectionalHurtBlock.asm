;Behaves $130

;Same as the muncher block, but is unaffected by any switches.

;^Damage or instant kill:
; *0 = hurt
; *1 = instant kill (regardless of invincibility frames)
	!HurtKill		= 0

;^How much HP loss from touching this block on the harmful side.
	!DamageAmount		= 5

;^Knockback speeds. For left and up speeds, use only values #$80-#$FF with #$80 being the fastest, for
; right/down speeds, use only values #$01-#$7F with #$7F being the fastest speed.
	!MuncherKnockbackUp		= $C0
	!MuncherKnockbackDown		= $70
	!MuncherKnockbackHorizSpd	= !Setting_PlayerHP_KnockbackHorizSpd
	!MuncherKnockbackHorizUpSpd	= !Setting_PlayerHP_KnockbackUpwardsSpd ;>horizontal upwards speed.

;Enable (set to 1) or disable (set to 0) damage on specific side.
	!Damage_Top		= 1
	!Damage_Bottom		= 1
	!Damage_LeftSide	= 1
	!Damage_RightSide	= 1


;Same as Damage_Top defines above, but for riding yoshi.
	!Damage_TopRidingYoshi	= 0

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP SpriteV : JMP SpriteH : JMP Return
JMP MarioFireBall : JMP MarioAbove : JMP BodyInside : JMP HeadInside

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

;========================================================================================
MarioAbove:
	if !Damage_Top != 0
		if !Damage_TopRidingYoshi == 0
			;CheckYoshi:
			LDA $187A|!addr				;\If riding yoshi, act like a cement block
			BNE AboveReturn				;/
		endif
		if !HurtKill == 0
			%InvincibilityCheck()			;\Don't hurt if invincible.
			BNE AboveReturn				;/

			if !Setting_PlayerHP_TwoByte == 0
				LDA.b #!DamageAmount
				STA $00
			else
				REP #$20
				LDA.w #!DamageAmount
				STA $00
				SEP #$20
			endif
			
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
			JSL $00F606
		endif
	endif
	AboveReturn:
	RTL		;>and return (as a solid)

;========================================================================================
MarioSide:
HeadInside:
	if or(notequal(!Damage_LeftSide, 0), notequal(!Damage_RightSide, 0))
		ContactSide:
		if !HurtKill == 0
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
		if !HurtKill == 0
			SideDamage:
			if !Setting_PlayerHP_TwoByte == 0	;\Damage the player
				LDX.b #!DamageAmount		;|
				STX $00				;|
			else					;|
				REP #$10			;|
				LDX.w #!DamageAmount		;|
				STX $00				;|
				SEP #$10			;|
			endif					;|
			PHA					;|
			%DamagePlayer()				;|
			PLA					;/
			
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
			JSL $00F606
		endif
	endif
	SideReturn:
	Return:
	RTL
;========================================================================================
MarioBelow:
BodyInside:
	if !Damage_Bottom != 0
		if !HurtKill == 0
			%InvincibilityCheck()				;\Don't hurt if invincible
			BNE BottomDone					;/
			
			if !Setting_PlayerHP_TwoByte == 0
				LDA.b #!DamageAmount
				STA $00
			else
				REP #$20
				LDA.w #!DamageAmount
				STA $00
				SEP #$20
			endif
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
			JSL $00F606
		endif
	endif
MarioFireBall:
SpriteV:
SpriteH:
	RTL		;>return as a solid
;========================================================================================
if !HurtKill == 0
	print "Deals !DamageAmount damage to the player."
else
	print "Instantly kills the player."
endif
