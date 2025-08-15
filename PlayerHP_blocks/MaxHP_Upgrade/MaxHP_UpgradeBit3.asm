;Act as $025
;This block is a permanent HP upgrade.

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"
incsrc "MaxHPUpgradeDef/HPUpgradeDef.asm"

	MarioBelow:
	MarioAbove:
	MarioSide:
	TopCorner:
	BodyInside:
	HeadInside:
	
	JSL $03B664|!bank				;>Get player clipping (hitbox/clipping B)
	%ItemSpriteHitbox()				;>Get item sprite hitbox
	JSL $03B72B|!bank				;>Check collision
	BCC Return
	
	%LevelListedIndex()							;\Get level indexing (X = which level sets to use)
	BCS Return								;/
	
	LDA !Freeram_PlayerHP_MaxHPUpgradePickupFlag,x				;\Set flag to not respawn.
	ORA.b #%00001000							;|
	STA !Freeram_PlayerHP_MaxHPUpgradePickupFlag,x				;/

	if !GiveScore != $00
		LDA #$09					;\Spawn score sprite
		%SpawnScoreSprite()				;/
		%PositionScoreSprite()				;>Position the score sprite.
	endif
	%erase_block()					;>Remove block

	if !HPUpgrade_SFXNum != $00
		LDA #!HPUpgrade_SFXNum			;\SFX
		STA !HPUpgrade_SFXRAM			;/
	endif
	
	if !MessageBox != $00
		LDA #!MessageBox			;\Display message
		STA $1426|!addr				;/
	endif
	
	if !Setting_PlayerHP_TwoByte
		REP #$20
	endif
	if !Setting_PlayerHP_TwoByte == 0
		if !HPUpgrade_VaryingIncrease == 0
			LDA !Freeram_PlayerHP_MaxHP
			CLC
			ADC.b #!HPUpgrade_MaxIncreaseBy
		else
			LDA !Freeram_PlayerHP_MaxHP
			CLC
			ADC MaxHPUpgradeBit0IncreaseList,x
		endif
		BCS .AboveTrueMax					;>When unsigned overflow occurs, the carry bit is set, so this prevents max HP from overflowing.
		CMP.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
	else
		if !HPUpgrade_VaryingIncrease == 0
			LDA !Freeram_PlayerHP_MaxHP
			CLC
			ADC.w #!HPUpgrade_MaxIncreaseBy
		else
			TXA						;\Double the index because each entry are 2 byte addresses long
			ASL						;|
			TAX						;/
			LDA !Freeram_PlayerHP_MaxHP
			CLC
			ADC MaxHPUpgradeBit0IncreaseList,x
		endif
		BCS .AboveTrueMax					;>When unsigned overflow occurs, the carry bit is set, so this prevents max HP from overflowing.
		CMP.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
	endif
	BCC .SetNewMaxHP						;>If between [9, 99, 999, 9999] and [255, 65535], also cap the max HP
	.AboveTrueMax
		if !Setting_PlayerHP_TwoByte == 0
			LDA.b #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
		else
			LDA.w #!Setting_PlayerHP_TrueMaximumHPAndDamageValue
		endif
	.SetNewMaxHP
		STA !Freeram_PlayerHP_MaxHP				;>Set max HP to the increased value
		STA !Freeram_PlayerHP_CurrentHP				;>Fully restore to new max HP
	if !Setting_PlayerHP_TwoByte
		SEP #$20
	endif
	if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_BarChangeDelay, 0))
		LDA.b #!Setting_PlayerHP_BarChangeDelay
		STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
	endif

	WallFeet:
	WallBody:

	SpriteV:
	SpriteH:

	MarioCape:
	MarioFireball:
	Return:
	RTL
	
if !HPUpgrade_VaryingIncrease != 0
 MaxHPUpgradeBit3IncreaseList:
 ;Order here corresponds with the table in "MaxHPUpgradeObtainLevelListIndex.asm"
 !PlayerHPDataTableSize 10            ;>Level 105 [!Freeram_PlayerHP_MaxHPUpgradePickupFlag+0]
 !PlayerHPDataTableSize 15            ;>Level 106 [!Freeram_PlayerHP_MaxHPUpgradePickupFlag+1]
 !PlayerHPDataTableSize 1             ;>Level 103 [!Freeram_PlayerHP_MaxHPUpgradePickupFlag+2]
 ;!PlayerHPDataTableSize 1             ;>template [!Freeram_PlayerHP_MaxHPUpgradePickupFlag+3]
endif

print "Increases the player's max HP."