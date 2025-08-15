;Note that this asm itself only handles with when the player takes
;damage, healing, etc. This does not do anything related to the HUD, or
;any visual based on that.
;
;Routines likely to be used by other codes (if you want to merge with the shared subroutines patch)
;-InvinciblePlayerCheck
;-RecoverPlayerHP
;-SubtractPlayerHP
;-MathMul16_16
;-MathDiv32_16
;
;^Use CTRL+F to find them.

incsrc "Defines/SA1StuffDefines.asm"
incsrc "Defines/StatusBarDefines.asm"
incsrc "Defines/PlayerHPDefines.asm"
incsrc "Defines/MotherHPDefines.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;hijacks:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;itembox and hex edits:
	org $01C510		;\Disable mushroom giving item
	db $00,$00,$00,$00	;/

	org $01C514		;\Disable flower giving mushroom
	db $00,$00		;/

	org $01C51C		;\Disable feather giving mushroom
	db $00,$00		;/

	org $00F5FC		;\disable powerdown animation and small mario.
	nop #6			;/

	;^Here is a better way to understand this (item box insertion):
	;$19 index:     #$00  #$01  #$02  #$03  ;>#$00 = small, #$01 = big, #$02 = cape, #$03 = fire.
	;--------------------------------------------------
	;$01C510:       #$00  #$01  #$01  #$01  ;>Mushroom
	;$01C514:       #$00  #$01  #$04  #$02  ;>Flower
	;$01C518:       #$00  #$00  #$00  #$00  ;>Star
	;$01C51C:       #$00  #$01  #$04  #$02  ;>Feather
	;$01C520:       #$00  #$00  #$00  #$00  ;>1-up
	;--------------------------------------------------
	;The numbers in here are what item goes into the item box. #$00 = none.

	;		^this is what item goes into item box

	org $00F5F8	;\Disable item box getting used when hurt 
	nop #4		;|Also disable the powerdown animation (the
			;|shrinking animation, based on the metroid HP).
			;|
			;/
;Powerup animation
	org $00D129		;\remove powerdown animation.
	NOP #3			;|
	db $80			;/>opcode $80 is BRA, which should always branch to $00D140


	org $01C524
	db $00,$00,$00,$00 	;>Mushroom always trys to make you big.
	;^Format:
	;$19 index:     #$00  #$01  #$02  #$03  #$04  #$05
	;-------------------------------------------------
	;$01C520:       #$00  #$01  #$01  #$01  #$04  #$04 ;>Numbers here are the powerup animation.
	;-------------------------------------------------
;Player Powerdown animation (freeze time and hurt frame timer)
	org $00F605
	db $1C			;>Fix mario's frozen pose (modifies the BRA to jump to $00F622).
;Cape stuff
	org $00F5ED					;\modify the invincibility timer after
	db !Setting_PlayerHP_InvulnerabilityTmrCape		;/getting hit while cape flying.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Freespace hijacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Healing
	org $00F2E0			;\Midway recovery
	autoclean JML MidwayHeal	;|
	NOP #4				;/

	org $01C561			;\Mushroom powerup hijack to make it heal the player.
	autoclean JML MushroomHeal	;/
;Damage
	org $00F5D5			;\Hijack a portion of the standard damage routine.
	autoclean JML SpriteDamage	;/(note that this ONLY runs during non-instant death)

	org $02A4AE				;\[Use [JSL read3($02A4AE+1)] to access this routine] reroute extended sprite's damage.
	autoclean JSL ExtendSpriteDamage	;/

	org $02F9FA				;\[Use [JSL read3($02F9FA+1)] to access this routine] reroute cluster sprite's damage.
	autoclean JSL ClusterSpriteDamage	;/
	
	org $028CF6				;\The ONLY minor extended sprite that damages the player.
	autoclean JSL BooStreamDamage		;/

	org $00F159				;\New damage blocks code (munchers, spikes from ghost houses and castles, etc.)
	autoclean JSL BlocksDamage		;/

	org $00F614				;\Hijack instant death routine.
	autoclean JML InstantDeath		;/
;Knockback
	if !Setting_PlayerHP_Knockback == 0
		if read1($00D01A) == $5C
			autoclean read3($00D01A+1)
		endif
		LDY.w $13E3
		BEQ $11
	else
		org $00D01A
		autoclean JML KnockbackStunPose
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Code to insert to freespace
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
freecode
	MidwayHeal: ;>JML jumps here from $00F2E0
	if !Setting_PlayerHP_MidwayRecoveryType == 0
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
			if !Setting_PlayerHP_MidwayRecoveryDividend > 1
				STA $00							;\MaxHP...
				STZ $01							;/
				REP #$20						;\...Times dividend
				LDA.w #!Setting_PlayerHP_MidwayRecoveryDividend		;|
				STA $02							;|
				SEP #$20						;|
				JSL MathMul16_16					;/
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
			LDA.w #!Setting_PlayerHP_MidwayRecoveryDivisor		;|
			STA $04							;|
			SEP #$20						;|
			JSL MathDiv32_16					;/;>$00 should be <= $FFFF
		else
			REP #$20
			LDA !Freeram_PlayerHP_MaxHP
			if !Setting_PlayerHP_MidwayRecoveryDividend > 1
				STA $00
				LDA.w #!Setting_PlayerHP_MidwayRecoveryDividend
				STA $02
				SEP #$20
				JSL MathMul16_16
				REP #$20
				LDA $04
				STA $00
				LDA $06
				STA $02
			else
				STA $00
				STZ $02
			endif
			LDA.w #!Setting_PlayerHP_MidwayRecoveryDivisor
			STA $04
			SEP #$20
			JSL MathDiv32_16 ;>$00 should be <= $FFFF
		endif
		;Rounding to nearest integer
		
		.Round
		REP #$20
		LDA.w #round(!Setting_PlayerHP_MidwayRecoveryDivisor/2, 0)	;\If HalfDivisor > Remainder (remainder smaller), don't round quotient.
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
	JSL RecoverPlayerHP
	
	.PowerupCheck
	LDA $19				;\If mario is already big, skip incrementing his powerup
	BNE .MidwayRecoveryDone		;/
	INC $19				;>Small -> Big mario
	
	.MidwayRecoveryDone
	JML $00F2E8|!bank		;>Return back to smw.
	;-------------------------------------------------------------------------------------------------------------------------------------------
	MushroomHeal: ;>JML from $01C561
	if !Setting_PlayerHP_MushroomToItemBox != 0
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_CurrentHP
			CMP !Freeram_PlayerHP_MaxHP
			BCS .AddToItemBox
		else
			REP #$20
			LDA !Freeram_PlayerHP_CurrentHP
			CMP !Freeram_PlayerHP_MaxHP
			BCS .AddToItemBox
		endif
	endif
	if !Setting_PlayerHP_MushroomRecoveryType == 0
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
			if !Setting_PlayerHP_MushroomRecoveryDividend > 1
				STA $00							;\MaxHP...
				STZ $01							;/
				REP #$20						;\...Times dividend
				LDA.w #!Setting_PlayerHP_MushroomRecoveryDividend	;|
				STA $02							;|
				SEP #$20						;|
				PHY							;|
				JSL MathMul16_16					;|
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
			LDA.w #!Setting_PlayerHP_MushroomRecoveryDivisor	;|
			STA $04							;|
			SEP #$20						;|
			PHY							;|
			JSL MathDiv32_16					;/;>$00 should be <= $FFFF
			PLY
		else
			REP #$20
			LDA !Freeram_PlayerHP_MaxHP
			if !Setting_PlayerHP_MushroomRecoveryDividend > 1
				STA $00
				LDA.w #!Setting_PlayerHP_MushroomRecoveryDividend
				STA $02
				SEP #$20
				PHY
				JSL MathMul16_16
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
			LDA.w #!Setting_PlayerHP_MushroomRecoveryDivisor
			STA $04
			SEP #$20
			PHY
			JSL MathDiv32_16 ;>$00 should be <= $FFFF
			PLY
		endif
		;Rounding to nearest integer
		
		.Round
		REP #$20
		LDA.w #round(!Setting_PlayerHP_MushroomRecoveryDivisor/2, 0)	;\If HalfDivisor > Remainder (remainder smaller), don't round quotient.
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
	JSL RecoverPlayerHP
	
	.MushroomBehavor
	if !Setting_PlayerHP_GrowFromSmallFailsafe != 0
		LDA $19
		BNE ..AlreadyBig
		
		LDA #$02			;\growing animation
		STA $71				;/
		JML $01C565|!bank			;>The rest of the code that handles the animation and other stuff.
	endif
	..AlreadyBig
	.MushroomReturn
	JML $01C56F|!bank				;>Rest of the mushroom code.
	
	.AddToItemBox
	SEP #$20
	;If you're small mario with full HP, simply do the growing animation instead of filling the item box.
	if !Setting_PlayerHP_GrowFromSmallFailsafe != 0
		LDA $19
		BNE ..AlreadyBig
		
		LDA #$02			;\growing animation
		STA $71				;/
		JML $01C565|!bank			;>The rest of the code that handles the animation and other stuff.
	endif
	..AlreadyBig
	LDA #$0B			;\"Item placed in item box" sfx.
	STA $1DFC|!addr			;/
	LDA $0DC2|!addr			;\Don't replace item in item box if already an item there.
	BNE .MushroomReturn		;/
	INC $0DC2|!addr			;>next "better powerup" in item box (normally puts a mushroom from #$00).
	BRA .MushroomReturn		;>and done
	;-------------------------------------------------------------------------------------------------------------------------------------------
	SpriteDamage: ;>JML From $00F5D5
	PHB		;>Save bank
	PHK		;\Switch bank.
	PLB		;/
	
	if !Setting_PlayerHP_Knockback != 0
		JSL SpriteKnockBack
	endif
	JSL CancelCapeSoaringIfSoaring
	BCS .DamageReturn
	if !Setting_PlayerHP_VaryingDamage == 0
		.OneDamage
		LDA #$01
		STA $00
		if !Setting_PlayerHP_TwoByte != 0 ;>Not sure if anyone would ever have HP over 255 when damages only subtract HP by 1.
			STZ $01
		endif
	else
		.Damage
		if !Setting_PlayerHP_UsingCustomSprites != 0
			LDA !7FAB10,x					;\check the type of sprite
			AND.b #%00001000				;/
			BEQ ..SMWRegSpr					;>smw normal sprites

			..CustomSprites
			if !Setting_PlayerHP_TwoByte == 0
				LDA !7FAB9E,x					;>Custom sprite number
				TAY						;>Transfer to Y index
			else
				REP #$30					;>16-bit AXY
				LDA !7FAB9E,x					;>Custom sprite number
				AND #$00FF					;>Rid the high byte
				ASL						;>*2 since each value is 2 bytes.
				TAY						;>Transfer to Y index
			endif
			PHX						;\Get damage values from table.
			TYX						;|There isn't a [LDA.l $xxxxxx,y], so I had
			LDA.l CustomSpriteDamageTbl,x			;|to temporally switch to using X.
			STA $00						;|
			PLX						;/
			
			BRA ..ApplyDamage
		endif
		..SMWRegSpr
		if !Setting_PlayerHP_TwoByte == 0
			LDA !9E,x					;>Custom sprite number
			TAY						;>Transfer to Y index
		else
			REP #$30					;>16-bit AXY
			LDA !9E,x					;>Custom sprite number
			AND #$00FF					;>Rid the high byte
			ASL						;>*2 since each value is 2 bytes.
			TAY						;>Transfer to Y index
		endif
		PHX
		TYX
		LDA.l SmwSpriteDamageTbl,x			;\Write damage
		STA $00						;/
		PLX

		..ApplyDamage
		LDA $00						;\If damage nonzero, leave it be
		BNE ...DealsValidDamage				;/

		...InvalidDamage
		INC $00						;>Otherwise deal at least 1.
		
		...DealsValidDamage
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$30
		endif
	endif
	JSL SubtractPlayerHP
	JSL DamageEffect
	
	.DamageReturn
	PLB
	JML $00F628|!bank		;>Return
	;-------------------------------------------------------------------------------------------------------------------------------------------
	ExtendSpriteDamage: ;>JSL from $02A4AE
	PHB				;>save bank to stack
	PHK				;\change bank to freespace bank.
	PLB				;/
	
	JSL InvinciblePlayerCheck
	BNE .ExtendSpriteDone
	
	if !Setting_PlayerHP_Knockback != 0
		JSL ExtenSpriteKnockback
	endif
	JSL CancelCapeSoaringIfSoaring
	BCS .ExtendSpriteDone

	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages		;\Set invulnerability timer
	STA $1497|!addr					;/
	if !Setting_PlayerHP_VaryingDamage == 0
		.OneDamage
		LDA #$01
		STA $00
		if !Setting_PlayerHP_TwoByte != 0 ;>Not sure if anyone would ever have HP over 255 when damages only subtract HP by 1.
			STZ $01
		endif
	else
		if !Setting_PlayerHP_TwoByte == 0
			LDA $170B|!addr,x
			TAY
		else
			REP #$30					;>AXY 16-bit
			LDA $170B|!addr,x				;>Extended sprite number
			AND #$00FF					;>rid the high byte
			ASL						;>
			TAY
		endif
		PHX
		TYX
		LDA.l ExtendSpriteDamageTbl,x
		STA $00
		PLX
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$30
		endif
	endif
	JSL SubtractPlayerHP
	JSL DamageEffect
	
	.ExtendSpriteDone
	PLB
	RTL
	;-------------------------------------------------------------------------------------------------------------------------------------------
	ClusterSpriteDamage: ;>JSL from $02F9FA
	PHB				;>save bank to stack
	PHK				;\change bank to freespace bank.
	PLB				;/
	JSL InvinciblePlayerCheck
	BNE .ClusterSpriteDone		;>If any of these above are >= 1, don't enable damage.
	
	if !Setting_PlayerHP_Knockback != 0
		JSL ClusterSpriteKnockback
	endif
	JSL CancelCapeSoaringIfSoaring
	BCS .ClusterSpriteDone
	
	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages		;\Set invulnerability timer
	STA $1497|!addr					;/
	if !Setting_PlayerHP_VaryingDamage == 0
		.OneDamage
		LDA #$01
		STA $00
		if !Setting_PlayerHP_TwoByte != 0 ;>Not sure if anyone would ever have HP over 255 when damages only subtract HP by 1.
			STZ $01
		endif
	else
		if !Setting_PlayerHP_TwoByte == 0
			LDA $1892|!addr,x			;\cluster sprite number to Y index
			TAY					;|
		else
			REP #$30				;|
			LDA $1892|!addr,x			;|
			AND #$00FF				;|
			ASL					;|
			TAY					;/
		endif
		PHX
		TYX
		LDA.l ClusterSpriteDamageTbl,x
		STA $00
		PLX
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$30
		endif
	endif
	JSL SubtractPlayerHP
	JSL DamageEffect
	.ClusterSpriteDone
	PLB
	RTL
	;-------------------------------------------------------------------------------------------------------------------------------------------
	BooStreamDamage: ;>JSL from $028CF6
	;X = minor extended sprite slot.
	JSL InvinciblePlayerCheck
	BNE .BooStreamDone			;>If any of these above are >= 1, don't enable damage.
	
	if !Setting_PlayerHP_Knockback != 0
		LDA $18EA|!addr,x
		XBA
		LDA $1808|!addr,x
		REP #$20
		JSL CompareWithMarioAndKnockBk
	endif
	JSL CancelCapeSoaringIfSoaring
	BCS .BooStreamDone
	
	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages		;\Set invulnerability timer
	STA $1497|!addr					;/
	if !Setting_PlayerHP_VaryingDamage == 0
		.OneDamage
		LDA #$01
		STA $00
		if !Setting_PlayerHP_TwoByte != 0 ;>Not sure if anyone would ever have HP over 255 when damages only subtract HP by 1.
			STZ $01
		endif
	else
		if !Setting_PlayerHP_TwoByte == 0
			LDA.b #!Setting_PlayerHP_DamageAmount_ReflectBooStream
			STA $00
		else
			REP #$20
			LDA.w #!Setting_PlayerHP_DamageAmount_ReflectBooStream
			STA $00
			SEP #$20
		endif
	endif
	JSL SubtractPlayerHP
	JSL DamageEffect
	
	.BooStreamDone
	RTL
	;-------------------------------------------------------------------------------------------------------------------------------------------
	BlocksDamage: ;>JSL from $00F159
	;Because address $00F159 is used by ALL offsets of the block, there is no way telling
	;which part mario is touching, therefore knockback would be buggy.
	
	JSL InvinciblePlayerCheck
	BNE .BlockDamageDone
	JSL CancelCapeSoaringIfSoaring
	BCS .BlockDamageDone
	
	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages		;\Set invulnerability timer
	STA $1497|!addr					;/
	if !Setting_PlayerHP_TwoByte == 0
		LDA.b #!Setting_PlayerHP_DamageAmount_VanillaSmwBlocks
		STA $00
	else
		REP #$20
		LDA.w #!Setting_PlayerHP_DamageAmount_VanillaSmwBlocks
		STA $00
		SEP #$20
	endif
	JSL SubtractPlayerHP
	JSL DamageEffect
	
	.BlockDamageDone
	RTL
	;-------------------------------------------------------------------------------------------------------------------------------------------
	InstantDeath: ;>JML from $00F614
	LDA #$09
	CMP $71
	BEQ .AlreadyDead
	
	.Dying
	;Feel free to add some codes here that runs for 1 frame the player instantly dies
	STA $71
	LDA #$00
	STA !Freeram_PlayerHP_CurrentHP
	if !Setting_PlayerHP_TwoByte != 0
		STA !Freeram_PlayerHP_CurrentHP+1
	endif
	.TransperentDamageOnBar
	if and(and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0)), !Setting_PlayerHP_DisplayBarLevel)	;\display transparent segment when the player gets killed
		LDA.b #!Setting_PlayerHP_BarChangeDelay								;|
		STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr							;|
	endif												;/
	LDA $19					;\Prevent a single frame of showing super mario when small mario dies.
	CMP #$02				;|
	BEQ .AlreadyDead			;/
	LDA #$01				;\Prevent cape flying sfx from playing when falling into a bottomless pit when the player is flying.
	STA $19					;/
	.AlreadyDead
	JML $00F618|!bank	;>Using RTL here can crash the game, so it must jump to a return of the same bank.
	;-------------------------------------------------------------------------------------------------------------------------------------------
	if !Setting_PlayerHP_Knockback != 0
		;Be careful not to have the pose write disabled when the player dies.
		KnockbackStunPose: ;>JML from $00D01A
		PHA					;>A was used for the pose number
		
		.CheckIfSafeToDisable
		..OverworldCheck
		LDA $0100|!addr				;\Allow pose write when on the title screen and overworld map.
		CMP #$0B				;|
		BCC .RestoreCode			;|
		CMP #$12				;|
		BCS ..SpinJumpCheck			;|
		BRA .RestoreCode			;/
		
		..SpinJumpCheck
		LDA $140D|!addr				;\Avoid weirdness with mario when taking damage while spinning.
		BNE .RestoreCode			;/
		
		..SafeToDisable				;\Allow disabling the consant write to player's pose.
		LDA !Freeram_PlayerHP_Knockback		;\If player is stunned, don't set pose.
		;ORA <address>				;>custom RAM to also disable writing to player's pose.
		BNE .NoWritePose			;
		
		.RestoreCode				;\Restore code (enable smw to write poses)
		PLA
		LDY.w $13E3|!addr
		BEQ ..MarioAnimNo45
		
		..CODE_00D01F
		JML $00D01F|!bank
		
		..MarioAnimNo45
		JML $00D030|!bank				;/
		
		.NoWritePose
		PLA				;\return without setting the player's pose
		JML $00D033|!bank			;/
	endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Damage table.
;Values here are decimal. If you want hex, prefix the number
;with "$" (i.e 16 becomes $10).
;
;!PlayerHPDataTableSize is basically a substitution between
;"db" and "dw" when choosing between 8 and 16-bit HP. Be
;very careful when changing from a 16-bit to an 8-bit when
;the numbers are above 255 (they'll get modulo'ed by 256).
;
;If you have bank issues, use "freedata"/"freecode"
;before a block that crossed the border. Be careful not to
;separate connecting codes though (freedata/freecode
;basically reposition the following code to another
;freespace area).
;
;Table is formated like this (also applies to knockback
;displacements as well): Each sprite number is a number on
;the table. As you increase the sprite number, it goes to the
;next number on the table. I've added comments for convenience
;for what sprite number the numbers on the table corresponds. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if !Setting_PlayerHP_VaryingDamage != 0
 SmwSpriteDamageTbl:

 ;SMW Sprite Damage (use up to 255 for 8-bit, and 65535 for 16-bit health).
 ;NOTE: Bob-omb and its explosion share the same damage due to the fact that the explosion is considered a normal sprite type
 ;(not cluster or extended).
 ;                          0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
 !PlayerHPDataTableSize 00001, 00001, 00002, 00001, 00002, 00002, 00004, 00003, 00003, 00003, 00003, 00003, 00004, 00004, 00000, 00001 ;#$00-#$0F
 !PlayerHPDataTableSize 00002, 00003, 00002, 00003, 00002, 00002, 00002, 00000, 00002, 00000, 00002, 00003, 00004, 00003, 00003, 00002 ;#$10-#$1F
 !PlayerHPDataTableSize 00005, 00000, 00002, 00002, 00002, 00002, 00006, 00004, 00003, 00003, 00003, 00000, 00000, 00000, 00003, 00000 ;#$20-#$2F
 !PlayerHPDataTableSize 00004, 00003, 00003, 00003, 00004, 00000, 00000, 00003, 00004, 00004, 00003, 00003, 00003, 00004, 00000, 00002 ;#$30-#$3F
 !PlayerHPDataTableSize 00004, 00000, 00000, 00000, 00004, 00000, 00003, 00002, 00005, 00000, 00000, 00001, 00002, 00002, 00002, 00003 ;#$40-#$4F
 !PlayerHPDataTableSize 00003, 00002, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$50-#$5F
 !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00004, 00004, 00005, 00003, 00000, 00000, 00000, 00000, 00000, 00003, 00002 ;#$60-#$6F
 !PlayerHPDataTableSize 00003, 00003, 00003, 00003, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$70-#$7F
 !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00004, 00000, 00000, 00007, 00000, 00000, 00000, 00000, 00000, 00000 ;#$80-#$8F
 !PlayerHPDataTableSize 00004, 00003, 00003, 00003, 00003, 00003, 00003, 00003, 00003, 00004, 00004, 00002, 00000, 00000, 00005, 00004 ;#$90-#$9F
 !PlayerHPDataTableSize 00005, 00004, 00000, 00000, 00003, 00003, 00005, 00002, 00004, 00004, 00004, 00003, 00004, 00004, 00002, 00003 ;#$A0-#$AF
 !PlayerHPDataTableSize 00004, 00000, 00003, 00004, 00005, 00000, 00004, 00000, 00000, 00000, 00000, 00000, 00000, 00004, 00002, 00004 ;#$B0-#$BF
 !PlayerHPDataTableSize 00000, 00000, 00003, 00004, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$C0-#$CF

 if !Setting_PlayerHP_UsingCustomSprites != 0
  CustomSpriteDamageTbl:
  ;Custom Sprite Damage (use up to 255 for 8-bit, and 65535 for 16-bit health).
  ;                          0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$00-#$0F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$10-#$1F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$20-#$2F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$30-#$3F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$40-#$4F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$50-#$5F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$60-#$6F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$70-#$7F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$80-#$8F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$90-#$9F
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$A0-#$AF
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$B0-#$BF
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$C0-#$CF
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$D0-#$DF
  !PlayerHPDataTableSize 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$E0-#$EF
 endif

	ExtendSpriteDamageTbl:
	;Extended sprite damage (use up to 255 for 8-bit, and 65535 for 16-bit health).
	;#$00 = freeslot
	;#$01 = puff of smoke with various objects
	;#$02 = reznor fireball
	;#$03 = hopping flame's small flame
	;#$04 = hammer
	;#$05 = player's fireball
	;#$06 = dry bone's bone being throwned
	;#$07 = lava splash
	;#$08 = torpedo ted's shooter arm
	;#$09 = ??? (flickering object?)
	;#$0A = coin from coin cloud game
	;#$0B = piranha plant's fireball
	;#$0C = volcano lotus's seeds
	;#$0D = pichin' chuck's baseballs
	;#$0E = wiggler's flower
	;#$0F = trail of smoke (yellow yoshi stomping the ground)
	;#$10 = stars from spinjumping on an enemy
	;#$11 = yoshi's fireballs
	;#$12 = water bubble (when the player is in water)
	;                          0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
	!PlayerHPDataTableSize 00000, 00000, 00002, 00001, 00002, 00000, 00002, 00001, 00001, 00001, 00001, 00002, 00003, 00002, 00001, 00001 ;#$00-#$0F
	!PlayerHPDataTableSize 00000, 00001, 00001 ;>#$10-#$XX
	;^If you use a tool to add more extended sprites, feel free to add more to this list.

	ClusterSpriteDamageTbl:
	;Cluster sprite damage (use up to 255 for 8-bit, and 65535 for 16-bit health).
	;#$00 = free slot, Nonexistent cluster sprite.
	;#$01 = bonus game's 1up
	;#$02 = unused (crash).
	;#$03 = Boo ceiling
	;#$04 = Boo ring (clockwise and counterclockwise)
	;#$05 = castle candle flame (used on the background)
	;#$06 = sumo brother's lightning flames
	;#$07 = Reappearing boo (found on sunken ghost ship on the 2nd room/level)
	;#$08 = unused swooper from swooper death bat ceiling
	;#$09~#$FF are made for cluster spritetool (apparently, Alacro's)
	;                          0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
	!PlayerHPDataTableSize 00000, 00000, 00002, 00002, 00002, 00000, 00004, 00002, 00001, 00000, 00000, 00000, 00000, 00000, 00000, 00000 ;#$00-#$0F
	;^If you use a tool to add more cluster sprites, feel free to add more to this list.

endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Knockback displacement tables.
;
;These tables are displacement values that marks the vertical line boundary
;that determines which direction should knock the player left or right.
;To position this vertical line, it simply does this formula:
;
;SpriteCenterXPos = SpriteXPos + DisplacementValue
;^DisplacementValue can be a negative value ($8000-$FFFF), which position the
; boundary to the left.
;
;It then compares SpriteCenterXPos with Mario's X position ($94-$95) if it
;is signed less than or greater than /equal-to.
;
;Note that SpriteCenterXPos doesn't mean the center position of the sprite's
;left and right edge, for example if:
;
; -A sprite have a width of 8-pixels with a X position point to the left edge.
; -A player with a width of 16-pixels also with a X position point on left
;  edge.
;
; You would set the displacement value to $FFFC. The easiest way to do this
; is have both mario and the sprite's center position at the same spot, then
; take the difference (MarioXpos - SpriteXpos) and that will be your
; displacement value. See the readme for more information.
;
;Another note is that most of these tables are commented out using a semicolon
;";" due to not ALL sprite numbers being used and that many SMW hackers rarely
;ever used custom cluster/extended sprites.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if !Setting_PlayerHP_Knockback != 0
 SmwSpriteKnockbackCenterDisp:
 ;SMW sprite knockback displacement
 ;      0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$00-#$0F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$10-#$1F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0010,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$20-#$2F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0008,$0008,$0008,$0000,$0000,$0000 ;#$30-#$3F
 dw $0000,$0000,$0000,$0000,$0008,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$40-#$4F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$50-#$5F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$60-#$6F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$70-#$7F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$80-#$8F
 dw $0010,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0008,$0000,$0000,$0000,$0018 ;#$90-#$9F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$A0-#$AF
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0008 ;#$B0-#$BF
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$C0-#$CF

 if !Setting_PlayerHP_UsingCustomSprites != 0
  CustomSpriteKnockbackCenterDisp:
  ;Custom sprite knockback displacement
  ;      0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$00-#$0F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$10-#$1F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$20-#$2F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$30-#$3F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$40-#$4F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$50-#$5F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$60-#$6F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$70-#$7F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$80-#$8F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$90-#$9F
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$A0-#$AF
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$B0-#$BF
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$C0-#$CF
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$D0-#$DF
  dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$E0-#$EF
 endif
 ExtendSpriteKnockbackCenterDisp:
 ;Extended sprite knockback displacement
 ;Note: Minor extended sprites is not listed here, since almost all of them do no damage to the player.
 ;There is one however, that is the boo stream. The head sprite is sprite number $B0, but the sprites
 ;left behind are the ONLY minor extended sprite to damage the player. To modify how much damage the
 ;player suffer, open "PlayerHPDef.asm", and look for "!Setting_PlayerHP_DamageAmount_ReflectBooStream".
 ;      0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
 dw $0000,$0000,$0000,$FFFC,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$FFFC,$FFFC,$0000,$0000 ;#$00-#$0F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$10-#$1F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$20-#$2F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$30-#$3F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$40-#$4F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$50-#$5F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$60-#$6F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$70-#$7F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$80-#$8F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$90-#$9F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$A0-#$AF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$B0-#$BF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$C0-#$CF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$D0-#$DF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$E0-#$EF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$F0-#$FF
 
 ClusterSpriteKnockbackCenterDisp:
 ;Cluster sprite knockback displacement
 ;      0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
 dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$00-#$0F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$10-#$1F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$20-#$2F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$30-#$3F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$40-#$4F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$50-#$5F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$60-#$6F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$70-#$7F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$80-#$8F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$90-#$9F
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$A0-#$AF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$B0-#$BF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$C0-#$CF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$D0-#$DF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$E0-#$EF
 ;dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ;#$F0-#$FF
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In-patch subroutines. Feel free to move them to the
;shared subroutines patch.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Invincible Player check.
	;Output: A = nonzero when the player cannot be
	;harmed.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	InvinciblePlayerCheck:
	LDA $1497|!addr			;\Don't hurt mario when he's invincible
	ORA $1490|!addr			;|
	ORA $1493|!addr			;/
	ORA $71				;>SMW had the hitbox & damage code run every frame from some sprites even when $9D is set.
	RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Cancel cape soaring (with condition).
	;
	;Output:
	;Carry: Set if the player is flying prior.
	;
	;Useful to cancel the player's flight instead
	;of damaging.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	CancelCapeSoaringIfSoaring:
	LDA $1407|!addr
	BEQ .NotFlying
	
	.Flying
	JSL $00F5E2|!bank
	SEC
	RTL
	
	.NotFlying
	CLC
	RTL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Damage effect
	;
	;Had to be separate in case if your hack have
	;a cutscene that would display 0HP without
	;forcing back to the map. This also handles
	;death when 0HP.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DamageEffect:
	.TransperentDamageOnBar
	if and(and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0)), !Setting_PlayerHP_DisplayBarLevel)
		LDA.b #!Setting_PlayerHP_BarChangeDelay
		STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
	endif
	
	if !Setting_PlayerHP_RollingHP == 0
		.SurviveOrDeath
		LDA !Freeram_PlayerHP_CurrentHP
		if !Setting_PlayerHP_TwoByte != 0
			ORA !Freeram_PlayerHP_CurrentHP+1
		endif
		BEQ .Death
	endif
	
	.Survive
	LDA.b #!Setting_PlayerHP_InvulnerabilityTmrMostDamages			;\From $00D140 (jumped from $00C599 as player animation trigger)(smw activates the invulnerability
	STA $1497|!addr						;/during the powerdown code, not during the hurt subroutine besides losing cape flight.
	if !Setting_PlayerHP_LosePowerupOnDamage != 0
		LDA #$01					;\lose powerup
		STA $19						;/
	endif
	LDA #$04						;\SFX
	STA $1DF9|!addr						;/
	STZ $14A6|!addr						;>Cancel cape spin (in the original, mario retains his spin pose after damage)
	
	;Add code here that runs when the player takes damage (but not when the player dies).
	RTL
	if !Setting_PlayerHP_RollingHP == 0
		.Death
		LDA $71
		CMP #$09
		BEQ ..AlreadyDead
		
		..Dying
		if !Setting_PlayerHP_Knockback != 0
			LDA #$00
			STA !Freeram_PlayerHP_Knockback
		endif
		;Add code here that runs 1 frame the player dies.
		JSL $00F606|!bank
		
		..AlreadyDead
		RTL
	endif

	if !Setting_PlayerHP_Knockback != 0
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;knockback code
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		SpriteKnockBack:
		JSL SharedKnockBack
		
		LDA !14E0,x				;\Sprite's X position
		XBA					;|
		LDA !E4,x				;/
		REP #$20				;\Push sprite's X position into stack
		PHA					;|
		SEP #$20				;/
		
		if !Setting_PlayerHP_UsingCustomSprites != 0
			LDA !7FAB10,x				;\check the type of sprite
			AND.b #%00001000			;|
			REP #$30				;|
			BEQ .SMWSpriteKnockback			;/
			
			.CustomSpriteKnockback
			LDA !7FAB9E,x				;>Custom sprite number
			AND #$00FF				;>Remove high byte
			ASL					;>*2 because each item is 2 bytes
			TAY					;>Transfer to Y index (instead of directly to X since we have A in the stack)
			PLA					;>Pull out sprite X position (base)
			PHX					;\Transfer Y -> X because [ADC.l $xxxxxx,y] doesn't exist
			TYX					;/
			CLC					;\displace it
			ADC.l CustomSpriteKnockbackCenterDisp,x	;/
			PLX					;>Restore X.
			BRA CompareWithMarioAndKnockBk
		endif
		.SMWSpriteKnockback
		if !Setting_PlayerHP_UsingCustomSprites == 0
			REP #$30
		endif
		LDA !9E,x				;>Sprite number
		AND #$00FF				;>Remove high byte
		ASL					;>*2 because each item is 2 bytes
		TAY					;>Transfer to Y index (instead of directly to X since we have A in the stack)
		PLA					;>Pull out sprite X position (base)
		PHX					;\Transfer Y to X
		TYX					;/
		CLC					;\Displace it
		ADC.l SmwSpriteKnockbackCenterDisp,x	;/
		PLX
		
		CompareWithMarioAndKnockBk:
		CMP $94					;>Compare sprite's X pos with player's X pos (SpriteXPos - PlayerXPos)
		SEP #$30
		BMI .SpriteOnLeft			;>Knock player right
		
		.SpriteOnRight ;>Knock player left
		LDA.b #($100-!Setting_PlayerHP_KnockbackHorizSpd)
		BRA .SetPlayerXSpeed
		
		.SpriteOnLeft
		LDA.b #!Setting_PlayerHP_KnockbackHorizSpd
		
		.SetPlayerXSpeed
		STA $7B
		
		;LDA.b #!Setting_PlayerHP_KnockbackLength	;\stun player.
		;STA !Freeram_PlayerHP_Knockback		;/
		RTL
		
		SharedKnockBack:
		LDA.b #!Setting_PlayerHP_KnockbackLength	;\Set mario to be stunned
		STA !Freeram_PlayerHP_Knockback		;/
		STZ $74					;>Lose climbing
		LDA.b #!Setting_PlayerHP_KnockbackUpwardsSpd	;\Mario flies upward
		STA $7D					;/
		if !Setting_PlayerHP_Knockback >= 2
			LDA.b #00000100			;\So if mario get hit while on ground,
			TRB $77				;/doesn't immediately gain control when damaged while on ground.
		endif
		RTL
		
		ExtenSpriteKnockback:
		JSL SharedKnockBack
		LDA $1733|!addr,x			;\Extended sprite X position
		XBA					;|
		LDA $171F|!addr,x			;/
		REP #$30
		PHA					;>preserve it.
		
		LDA $170B|!addr,x			;>Extended sprite number
		AND #$00FF				;>Rid high byte
		ASL					;>*2 because each item have 2 bytes
		TAY					;>Transfer to Y index (instead of directly to X since we have A in the stack)
		PLA					;>A = extended sprite's X pos
		PHX					;\Transfer Y -> X
		TYX					;/
		CLC					;\displace center position
		ADC.l ExtendSpriteKnockbackCenterDisp,x	;/
		PLX					;>Restore X
		BRA CompareWithMarioAndKnockBk
		
		ClusterSpriteKnockback:
		JSL SharedKnockBack
		LDA $1E3E|!addr,x				;\Extended sprite X position into stack
		XBA						;|
		LDA $1E16|!addr,x				;|
		REP #$30					;|
		PHA						;/
		LDA $1892|!addr,x				;\cluster sprite number to Y index
		AND #$00FF					;|(instead of directly to X since we have A in the stack)
		ASL						;|
		TAY						;/
		PLA						;>Obtain extended sprite X pos
		PHX						;\Transfer Y to X ([ADC.l $xxxxxx,y] doesn't exist)
		TYX						;/
		CLC						;\Displace to get center x pos
		ADC.l ClusterSpriteKnockbackCenterDisp,x	;/
		PLX
		BRA CompareWithMarioAndKnockBk			;>And reuse code that would knock player away from sprite.
	endif
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Recover player HP.
	;
	;Input:
	; $00 (8/16-bit) = the amount of HP to recover
	;
	;Automatically writes to !Freeram_PlayerHP_CurrentHP. Doesn't
	;heal past the maximum HP.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	RecoverPlayerHP:
		.DisplayRecovery
		if !Setting_PlayerHP_DisplayRecoveryTotal
			LDA.b #!Setting_PlayerHP_DamageHeal_Duration
			STA !Freeram_PlayerHP_RecoveryTotalTimerDisplay
			if !Setting_PlayerHP_TwoByte != 0
				REP #$20
			endif
			LDA !Freeram_PlayerHP_RecoveryTotalDisplay
			CLC
			ADC $00
			BCS ..Overflow
			if !Setting_PlayerHP_TwoByte != 0
				CMP.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
			else
				CMP.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
			endif
			BCC ..Write
			
			..Overflow
				if !Setting_PlayerHP_TwoByte != 0
					LDA.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
				else
					LDA.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
				endif
			..Write
				STA !Freeram_PlayerHP_RecoveryTotalDisplay
			..Done
			if !Setting_PlayerHP_TwoByte != 0
				SEP #$20
			endif
		endif
	if !Setting_PlayerHP_RollingHP == 0
		if !Setting_PlayerHP_TwoByte == 0
			LDA !Freeram_PlayerHP_CurrentHP		;\Health + Recovery
			CLC					;|
			ADC $00					;/
			BCC .NotMaxed				;>If not exceeding 255, compare with max HP
			CMP !Freeram_PlayerHP_MaxHP		;\If not exceeding max HP, write to HP.
			BCC .NotMaxed				;/
			
			.Maxed
			LDA !Freeram_PlayerHP_MaxHP
			
			.NotMaxed
			STA !Freeram_PlayerHP_CurrentHP
		else
			REP #$20
			LDA !Freeram_PlayerHP_CurrentHP
			CLC
			ADC $00
			BCS .Maxed				;>If not exceeding 65535
			CMP !Freeram_PlayerHP_MaxHP
			BCC .NotMaxed				;>If not exceeding max HP, write to HP.
			
			.Maxed
			LDA !Freeram_PlayerHP_MaxHP
			
			.NotMaxed
			STA !Freeram_PlayerHP_CurrentHP
			SEP #$20
		endif
		if and(and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0)), !Setting_PlayerHP_DisplayBarLevel)
			if !Setting_PlayerHP_BarChangeDelay != 0
				LDA.b #!Setting_PlayerHP_BarChangeDelay
				STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
			endif
		endif
		RTL
	else
		LDA !Freeram_PlayerHP_MotherHPDirection		;\If player's HP is currently counting upwards, stack the healing
		BNE .StackHealing				;/
		if !Setting_PlayerHP_TwoByte == 0
			LDA $00
			BRA .Write
		else
			REP #$20
			LDA $00
			BRA .Write
		endif
		.StackHealing
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_MotherHPChanger
		CLC
		ADC $00
		BCC .Write
		if !Setting_PlayerHP_TwoByte == 0
			.Maxed
			LDA #$FF
			
			.Write
			STA !Freeram_PlayerHP_MotherHPChanger
		else
			.Maxed
			LDA #$FFFF
			
			.Write
			STA !Freeram_PlayerHP_MotherHPChanger
			SEP #$20
		endif
		LDA #$01
		STA !Freeram_PlayerHP_MotherHPDirection
		LDA #$00						;\Initially start out with first increment immediately.
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer		;/
		if and(and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0)), !Setting_PlayerHP_DisplayBarLevel)
			if !Setting_PlayerHP_BarChangeDelay != 0
				LDA.b #!Setting_PlayerHP_BarChangeDelay
				STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
			endif
		endif
		RTL
	endif
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Hurt player (merely subtracts HP and nothing else, useful
	;if you want certain damage to ignore invulnerability or
	;during a cutscene to display 0 HP without playing the
	;death animation)
	;
	;Input:
	; $00 (8/16-bit) = amount of HP loss.
	;
	;Automatically writes to !Freeram_PlayerHP_CurrentHP. Does not
	;subtract HP to below zero.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	SubtractPlayerHP:
	.DisplayDamage
	if !Setting_PlayerHP_DisplayDamageTotal
		LDA.b #!Setting_PlayerHP_DamageHeal_Duration
		STA !Freeram_PlayerHP_DamageTotalTimerDisplay
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_DamageTotalDisplay
		CLC
		ADC $00
		BCS ..Overflow
		if !Setting_PlayerHP_TwoByte != 0
			CMP.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
		else
			CMP.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
		endif
		BCC ..Write
		
		..Overflow
			if !Setting_PlayerHP_TwoByte != 0
				LDA.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
			else
				LDA.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
			endif
		..Write
			STA !Freeram_PlayerHP_DamageTotalDisplay
		..Done
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
	endif
	.SubtractHealth
	if !Setting_PlayerHP_RollingHP == 0
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_CurrentHP		;\Health - damage
		SEC					;|
		SBC $00					;/
		BCS .NotPastZero			;>If value didn't subtract by larger value, go write HP.
		
		.PastZero
		if !Setting_PlayerHP_TwoByte != 0
			LDA #$0000				;>Otherwise set HP to 0.
		else
			LDA #$00				;>Otherwise set HP to 0.
		endif
		
		.NotPastZero
		STA !Freeram_PlayerHP_CurrentHP		;>Write HP value.
		if !Setting_PlayerHP_TwoByte != 0
			SEP #$20
		endif
	else
		;this uses CLC : ADC to allow damage to stack when the player
		;takes damage while HP is counting down.
		LDA #$00						;\So if the player was healing then takes damage, immidiately
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer		;/starts with 1 HP loss.
		LDA !Freeram_PlayerHP_MotherHPDirection			;\Check if the player is healing or under HP drain
		BEQ .StackDamage					;/
		if !Setting_PlayerHP_TwoByte == 0
			LDA $00
			BRA .Write
		else
			REP #$20
			LDA $00
			BRA .Write
		endif
		
		.StackDamage
		if !Setting_PlayerHP_TwoByte != 0
			REP #$20
		endif
		LDA !Freeram_PlayerHP_MotherHPChanger			;\Add more remaining damage to the stacker
		CLC							;|
		ADC $00							;|
		BCC .Write						;/
		if !Setting_PlayerHP_TwoByte == 0
			
			.Maxed
			LDA #$FF					;\set to subtract HP.
			
			.Write
			STA !Freeram_PlayerHP_MotherHPChanger		;|
		else
			.Maxed
			LDA #$FFFF					;|
			
			.Write
			STA !Freeram_PlayerHP_MotherHPChanger		;|
			SEP #$20					;/
		endif
		.SetToDamage
		LDA #$00						;\Set to damage the player
		STA !Freeram_PlayerHP_MotherHPDirection			;/
		;LDA #$00						;\Initially start out with first decrement immediately.
		STA !Freeram_PlayerHP_MotherHPDelayFrameTimer		;/
	endif
	RTL

	if !sa1 == 0
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Unsigned 16bit * 16bit Multiplication (non-sa-1)
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Argusment
		; $00-$01 : Multiplicand
		; $02-$03 : Multiplier
		; Return values
		; $04-$07 : Product
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		MathMul16_16:	REP #$20
				LDY $00
				STY $4202
				LDY $02
				STY $4203
				STZ $06
				LDY $03
				LDA $4216
				STY $4203
				STA $04
				LDA $05
				REP #$11
				ADC $4216
				LDY $01
				STY $4202
				SEP #$10
				CLC
				LDY $03
				ADC $4216
				STY $4203
				STA $05
				LDA $06
				CLC
				ADC $4216
				STA $06
				SEP #$20
				RTL
	else
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Unsigned 16bit * 16bit Multiplication SA-1 version
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Argusment
		; $00-$01 : Multiplicand
		; $02-$03 : Multiplier
		; Return values
		; $04-$07 : Product
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		MathMul16_16:	STZ $2250
				REP #$20
				LDA $00
				STA $2251
				ASL A
				LDA $02
				STA $2253
				BCS +
				LDA.w #$0000
		+		BIT $02
				BPL +
				CLC
				ADC $00
		+		CLC
				ADC $2308
				STA $06
				LDA $2306
				STA $04
				SEP #$20
				RTL
	endif
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Unsigned 32bit / 16bit Division
	; By Akaginite (ID:8691), fixed the overflow
	; bitshift by GreenHammerBro (ID:18802)
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Arguments
	; $00-$03 : Dividend
	; $04-$05 : Divisor
	; Return values
	; $00-$03 : Quotient
	; $04-$05 : Remainder
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MathDiv32_16:	REP #$20
			ASL $00
			ROL $02
			LDY #$1F
			LDA.w #$0000
	-		ROL A
			BCS +
			CMP $04
			BCC ++
	+		SBC $04
			SEC
	++		ROL $00
			ROL $02
			DEY
			BPL -
			STA $04
			SEP #$20
			RTL