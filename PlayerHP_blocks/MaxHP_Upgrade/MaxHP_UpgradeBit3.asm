;Act as $025
;This block is a permanent HP upgrade.

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"
incsrc "MaxHPUpgradeDef/HPUpgradeDef.asm"

	MarioBelow:
	MarioAbove:
	MarioSide:
	TopCorner:
	BodyInside:
	HeadInside:
	
	JSL $03B664					;>Get player clipping (hitbox/clipping B)
	%ItemSpriteHitbox()				;>Get item sprite hitbox
	JSL $03B72B					;>Check collision
	BCC Return
	
	%LevelListedIndex()							;\Get level indexing
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
	
	if !HPUpgrade_VaryingIncrease == 0
		if !Setting_PlayerHP_TwoByte == 0		;\Increase max health
			LDA !Freeram_PlayerMaxHP		;|
			CLC					;|
			ADC.b #!HPUpgrade_MaxIncreaseBy		;|
			STA !Freeram_PlayerMaxHP		;|
			STA !Freeram_PlayerCurrHP		;|
		else						;|
			REP #$20				;|
			LDA !Freeram_PlayerMaxHP		;|
			CLC					;|
			ADC.w #!HPUpgrade_MaxIncreaseBy		;|
			STA !Freeram_PlayerMaxHP		;|
			STA !Freeram_PlayerCurrHP		;|
			SEP #$20				;/
		endif
	else
		if !Setting_PlayerHP_TwoByte == 0		;\Increase max health
			LDA !Freeram_PlayerMaxHP		;|
			CLC					;|
			ADC MaxHPUpgradeBit3IncreaseList,x	;|
			STA !Freeram_PlayerMaxHP		;|
			STA !Freeram_PlayerCurrHP		;|
		else						;|
			TXA					;|
			ASL					;|
			TAX					;|
			REP #$20				;|
			LDA !Freeram_PlayerMaxHP		;|
			CLC					;|
			ADC MaxHPUpgradeBit3IncreaseList,x	;|
			STA !Freeram_PlayerMaxHP		;|
			STA !Freeram_PlayerCurrHP		;|
			SEP #$20				;/
		endif
	endif
	if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!PlayerHP_BarRecordDelay, 0))
		LDA.b #!PlayerHP_BarRecordDelay
		STA !Freeram_PlayerHP_BarRecordDelayTmr
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