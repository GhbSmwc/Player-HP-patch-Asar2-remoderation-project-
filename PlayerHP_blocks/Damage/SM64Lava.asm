;Act as $000-$003 $025 or $130. Sprites will treat this block as $004 or $005

;Just like in SM64, this will fling the player upwards and ignores
;invulnerability frames. However, this this block features sideways
;and upsidedown rolled into one block. Note that the block teleports
;the player away a few pixels to prevent a possible chance of hitting
;the block multiple times within 1 or 2 frames.
;
;Unlike the previous version (before version 4.0), this does set the
;invulnerability timer despite that the block ignores it. This is done
;to prevent frustration that the player can get hit by enemies while
;lava bouncing (which those stun the player when knockback is enabled.)

;Damage when touching the block.
	!Sm64LavaDamage			= 10

;Knockback speeds (note that these speeds is always applied even if you disabled it beforehand),
;it will not utilize the stun timer.
	!Sm64LavaKnockUpSpd		= $B0 ;>$80 to $FF (the top of the block)
	!Sm64LavaKnockDownSpd		= $30 ;>$01 to $7F (the bottom of the block)
	!Sm64LavaKnockHorizXSpd		= $20 ;>$01 to $7F (both left and right calculated).
	!Sm64LavaKnockHorizYSpd		= $E0 ;>$80 to $7F (flings the player upwards when hitting side).


db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

	MarioAbove:
	TopCorner:
	
	JSR SpecialInvulnerabilityCheck		;\Don't hurt on special occasions.
	BNE AboveReturn				;/
	
	STZ $1407|!addr				;>Cancel cape flying (always damage with no exceptions)
	if !Setting_PlayerHP_TwoByte == 0
		LDA.b #!Sm64LavaDamage
		STA $00
	else
		REP #$20
		LDA.w #!Sm64LavaDamage
		STA $00
		SEP #$20
	endif
	%DamagePlayer()				;>damage player
	
	LDA $71					;\Don't apply knockback on death.
	CMP #$09				;|
	BEQ AboveReturn				;/
	
	LDX #$00				;\Displacement based on riding yoshi
	LDA $187A|!addr				;|
	BEQ +					;|
	INX #2					;|
	+					;/
	
	REP #$20				;\Warp the player upwards a few pixels.
	LDA $98					;|
	AND #$FFF0				;|
	SEC					;|
	SBC AboveBlockYDisp,x			;|
	STA $98					;|
	SEP #$20				;/
	
	LDA.b #!Sm64LavaKnockUpSpd		;\Fling player upward
	STA $7D					;/
	
	LDA #$17				;\spit fire sfx.
	STA $1DFC|!addr				;/
	
	AboveReturn:
	RTL
	;============================================================================================================
	MarioSide:
	BodyInside:
	HeadInside:
	
	JSR SpecialInvulnerabilityCheck		;\Don't hurt on special occasions.
	BNE AboveReturn				;/
	
	%SideContactCheck()
	BEQ SideReturn				;>Don't react if the player is on the very edge of the block.
	DEC A					;>Map the left and right numbers from 1-2 to 0-1.
	ASL					;>Times 2 (0-1 turns into 0-2)
	PHA					;>Push A.
	
	STZ $1407|!addr				;>Cancel cape flying (always damage with no exceptions)
	if !Setting_PlayerHP_TwoByte == 0
		LDA.b #!Sm64LavaDamage
		STA $00
	else
		REP #$20
		LDA.w #!Sm64LavaDamage
		STA $00
		SEP #$20
	endif
	%DamagePlayer()				;>damage player
	PLX					;>Pull A as X
	LDA $71					;\Don't apply knockback on death.
	CMP #$09				;|
	BEQ SideReturn				;/
	
	
	REP #$20				;\Teleport player few pixels away from block.
	LDA $9A					;|
	AND #$FFF0				;|
	CLC					;|
	ADC SideBlockXDisp,x			;|
	STA $94					;|
	SEP #$20				;/
	LDA HorizKnockSpeeds,x			;\Set horizontal speed.
	STA $7B					;/
	LDA.b #!Sm64LavaKnockHorizYSpd		;\Set vertical speed.
	STA $7D					;/
	LDA #$17				;\spit fire sfx.
	STA $1DFC|!addr				;/
	
	SideReturn:
	RTL
	;============================================================================================================
	MarioBelow:
	JSR SpecialInvulnerabilityCheck		;\Don't hurt on special occasions.
	BNE BelowReturn				;/
	
	STZ $1407|!addr				;>Cancel cape flying (always damage with no exceptions)
	if !Setting_PlayerHP_TwoByte == 0
		LDA.b #!Sm64LavaDamage
		STA $00
	else
		REP #$20
		LDA.w #!Sm64LavaDamage
		STA $00
		SEP #$20
	endif
	%DamagePlayer()				;>damage player
	
	LDA $71					;\Don't apply knockback on death.
	CMP #$09				;|
	BEQ BelowReturn				;/
	
	JSR SmallPlayerHitboxCheck
	
	REP #$20
	LDA $98
	AND #$FFF0
	CLC
	ADC BelowBlockYDisp,x
	STA $96
	SEP #$20
	
	LDA.b #!Sm64LavaKnockDownSpd
	STA $7D
	LDA #$17				;\spit fire sfx.
	STA $1DFC|!addr				;/
	
	BelowReturn:
	RTL
	;============================================================================================================
	
	SpriteV:
	SpriteH:
	LDY #$00		;\Act like a lava block.
	LDA #$04		;|
	STA $1693|!addr		;/
	;============================================================================================================
	MarioCape:
	MarioFireball:
	WallFeet:
	WallBody:
	RTL
	
	AboveBlockYDisp:
	;How many pixels up the player warps. First number (index #$00) is not riding yoshi, second number (index #$02)
	;is riding yoshi. index #$01 is unused.
	dw $0024, $0034
	
	HorizKnockSpeeds:
	;Left and right knock speeds (without stunning the player):
	;index #$00 = left speed
	;index #$01 = unused
	;index #$02 = right speed
	db ($100-!Sm64LavaKnockHorizXSpd), $00, !Sm64LavaKnockHorizXSpd
	
	BelowBlockYDisp:
	;A few pixels up in case if there is a 1 block space between the floor
	;and this block to prevent clipping.
	dw $FFFC, $000C
	
	SideBlockXDisp:
	;These numbers are signed.
	dw $FFF0, $0010
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;Special invulnerability check.
	;;output:
	;; A = nonzero when the player shouldn't be harmed.
	;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	SpecialInvulnerabilityCheck:
	LDA $1490|!addr		;>star power
	ORA $1493|!addr		;>level end timer
	RTS
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;Small player hitbox check.
	;;
	;;To be used for preventing the player's top-half from clipping the block.
	;;
	;;output:
	;; X:
	;;  #$00 if mario is 1 tile tall on his hitbox
	;;  #$02 if mario is 2 tiles tall on his hitbox
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	SmallPlayerHitboxCheck:
	LDX #$00
	LDA $73				;\If crouching, branch as small hitbox
	BNE +				;/
	LDA $19				;\If small mario, branch as small hitbox.
	BEQ +				;/
	INX #2
	+
	RTS

print "Sm64 lava. Deals !Sm64LavaDamage damage to the player."