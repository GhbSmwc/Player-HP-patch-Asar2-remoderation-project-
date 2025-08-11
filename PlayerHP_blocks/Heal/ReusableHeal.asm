;Act as $025 (best to have all sides to heal the player for a passable block) or $130.

;Note: Will instantly recovers the player's HP, regardless
;if you enabled rolling HP or not.

;Fully recover HP on specific side
;^0 = disable
; 1 = enable
	!FullRecoverTop		= 1
	!FullRecoverBottom	= 1
	!FullRecoverLeft	= 1
	!FullRecoverRight	= 1

;Sound effects
	!FullRecover_SFXNum		= $2A
	!FullRecover_SFXRamPort		= $1DF9|!addr


db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

;Don't touch these:
 !SideEnabled = 0
 if or(notequal(!FullRecoverLeft, 0), notequal(!FullRecoverRight, 0))
  !SideEnabled = 1
 endif
 assert or(!FullRecoverTop, or(!FullRecoverBottom, or(!FullRecoverLeft, !FullRecoverRight))) == 1, "Usless block, this doesn't heal the player at all."

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

	if !FullRecoverTop != 0
		MarioAbove:
		TopCorner:
	endif
	if !FullRecoverBottom != 0
		MarioBelow:
	endif
	if or(notequal(!FullRecoverTop, 0), notequal(!FullRecoverBottom, 0))
		BRA FullHeal
	endif
	if !SideEnabled != 0
		MarioSide:
		BodyInside:
		HeadInside:
		
		%SideContactCheck()
		BEQ Return
		
		if !FullRecoverLeft == 0
			CMP #$01
			BEQ Return
		endif
		if !FullRecoverRight == 0
			CMP #$02
			BEQ Return
		endif
	endif
	FullHeal:
	if !Setting_PlayerHP_TwoByte == 0
		LDA !Freeram_PlayerHP_MaxHP
		CMP !Freeram_PlayerHP_CurrentHP
		BEQ Return
		BCC Return
		STA !Freeram_PlayerHP_CurrentHP
	else
		REP #$20
		LDA !Freeram_PlayerHP_MaxHP
		CMP !Freeram_PlayerHP_CurrentHP
		BEQ Return
		BCC Return
		STA !Freeram_PlayerHP_CurrentHP
		SEP #$20
	endif
	if !FullRecover_SFXNum != 0
		LDA.b #!FullRecover_SFXNum
		STA !FullRecover_SFXRamPort
	endif
	if and(notequal(!Setting_PlayerHP_BarAnimation, 0), notequal(!Setting_PlayerHP_ShowHealedTransparent, 0))
		if !Setting_PlayerHP_BarChangeDelay != 0
			LDA.b #!Setting_PlayerHP_BarChangeDelay
			STA !Freeram_Setting_PlayerHP_BarChangeDelayTmr
		endif
	endif
	if !Setting_PlayerHP_RollingHP != 0
		if !Setting_PlayerHP_TwoByte == 0
			LDA #$00
			STA !Freeram_PlayerHP_MotherHPChanger
		else
			REP #$20
			LDA #$0000
			STA !Freeram_PlayerHP_MotherHPChanger
			SEP #$20
		endif
	endif

	if !FullRecoverTop == 0
		MarioAbove:
		TopCorner:
	endif
	if !FullRecoverBottom == 0
		MarioBelow:
	endif
	if !SideEnabled == 0
		MarioSide:
	endif
	WallFeet:
	WallBody:
	SpriteV:
	SpriteH:
	MarioCape:
	MarioFireball:
	Return:
	SEP #$20
	RTL

print "Fully recovers HP and can be used multiple times."