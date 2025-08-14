;Act as $025.

;0 = heal by fixed amount
;1 = heal as percentage of max HP.
	!Setting_PlayerHP_BlockMushroomRecoveryType = 1

;Recover HP by Dividend/Divisor of max HP (rounded
;to nearest integer but not to zero).
	!Setting_PlayerHP_BlockMushroomRecoveryDividend = 2
	!Setting_PlayerHP_BlockMushroomRecoveryDivisor = 5


db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

	MarioBelow:
	MarioAbove:
	MarioSide:
	TopCorner:
	BodyInside:
	HeadInside:
	WallFeet:
	WallBody:
	
	JSL $03B664|!bank				;>Get player clipping (hitbox/clipping B)
	%ItemSpriteHitbox()				;>Get item sprite hitbox
	JSL $03B72B|!bank				;>Check collision
	BCS +
	RTL
	+
	
	LDA #$09					;\Spawn score sprite
	%SpawnScoreSprite()				;/
	%PositionScoreSprite()				;>Position the score sprite.
	%erase_block()					;>Remove block

	LDA #$0A					;\Get powerup SFX
	STA $1DF9|!addr					;/

	;GrabMushroom:
	if !Setting_PlayerHP_GrowFromSmallFailsafe != 0
		LDA $19
		BEQ ConsumeMushroom
	endif
	if !Setting_PlayerHP_TwoByte == 0
		LDA !Freeram_PlayerHP_CurrentHP		;\If HP is full (or higher, in case if your hack allows it), place it item box
		CMP !Freeram_PlayerHP_MaxHP		;|
		BCC ConsumeMushroom			;/
	else
		REP #$20
		LDA !Freeram_PlayerHP_CurrentHP		;\If HP is full (or higher, in case if your hack allows it), place it item box
		CMP !Freeram_PlayerHP_MaxHP		;|
		SEP #$20				;|
		BCC ConsumeMushroom			;/
	endif
	;.ItemBox
	;..SoundEffects
	LDA #$0B					;\Item box placed SFX
	STA $1DFC|!addr					;/
	
	;..StoreItem
	LDA #$01					;\Place mushroom in item box
	STA $0DC2|!addr					;/
	RTL
	ConsumeMushroom:
	if !Setting_PlayerHP_GrowFromSmallFailsafe != 0
		LDA $19
		BNE AlreadyBig
		
		;.GrowingAnimation
		LDA #$02
		STA $71
		LDA #$2F
		STA $1496|!addr
		STA $9D
		
		
		AlreadyBig:
	endif
	if !Setting_PlayerHP_BlockMushroomRecoveryType == 0
		if !Setting_PlayerHP_TwoByte == 0
			LDA.b #!Setting_PlayerHP_MidwayRecoveryFixedAmt
			STA $00
		else
			REP #$20
			LDA.w #!Setting_PlayerHP_MidwayRecoveryFixedAmt
			STA $00
			SEP #$20
		endif
	else
	;Recovery = MaxHP*Dividend/Divisor  ;>if Dividend is > 1
	;Recovery = MaxHP/Divisor           ;>if Dividend is = 1
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_MaxHP
			if !Setting_PlayerHP_BlockMushroomRecoveryDividend > 1
				STA $00							;\MaxHP...
				STZ $01							;/
				REP #$20						;\...Times dividend
				LDA.w #!Setting_PlayerHP_BlockMushroomRecoveryDividend	;|
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
			LDA.w #!Setting_PlayerHP_BlockMushroomRecoveryDivisor	;|
			STA $04							;|
			SEP #$20						;|
			PHY							;|
			%MathDiv32_16()						;/;>$00 should be <= $FFFF
			PLY
		else
			REP #$20
			LDA !Freeram_PlayerHP_MaxHP
			if !Setting_PlayerHP_BlockMushroomRecoveryDividend > 1
				STA $00
				LDA.w #!Setting_PlayerHP_BlockMushroomRecoveryDividend
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
			LDA.w #!Setting_PlayerHP_BlockMushroomRecoveryDivisor
			STA $04
			SEP #$20
			PHY
			%MathDiv32_16() ;>$00 should be <= $FFFF
			PLY
		endif
		;Rounding to nearest integer
		
		.Round
		REP #$20
		LDA.w #round(!Setting_PlayerHP_BlockMushroomRecoveryDivisor/2, 0)	;\If HalfDivisor > Remainder (remainder smaller), don't round quotient.
		CMP $04									;/
		BEQ ..RoundQuotient							;>If =, round up
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
	%RecoverPlayerHP()

	SpriteV:
	SpriteH:

	MarioCape:
	MarioFireball:
	Return:
	RTL

print "Mushroom that recovers the player's HP")