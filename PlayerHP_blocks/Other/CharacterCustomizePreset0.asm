;Act as $130

;In its basic form, sets the player's max HP to a specified value.
;This block is meant for further edits for other stat change for character
;customizations (like one with high HP but weak attacks, vice versa, etc).
!MaxHealthSetTo		= 15

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

incsrc "../../../StatusBarDefines.asm"
incsrc "../../../PlayerHPDefines.asm"
incsrc "../../../MotherHPDefines.asm"

	MarioBelow:
	LDA #$20		;\Bounce player down to prevent multiple activations
	STA $7D			;/
	
	if !Setting_PlayerHP_TwoByte == 0
		LDA.b #!MaxHealthSetTo			;\Change max HP
		STA !Freeram_PlayerMaxHP		;/
		CMP !Freeram_PlayerCurrHP		;\If new max HP falls below current HP, set current HP
		BCS +					;|to the new max HP (prevent current HP over the max).
		STA !Freeram_PlayerCurrHP		;/
	else
		REP #$20
		LDA.w #!MaxHealthSetTo			;\Change max HP
		STA !Freeram_PlayerMaxHP		;/
		CMP !Freeram_PlayerCurrHP		;\If new max HP falls below current HP, set current HP
		BCS +					;|to the new max HP (prevent current HP over the max).
		STA !Freeram_PlayerCurrHP		;/
		+
		SEP #$20
	endif
	LDA #$10				;\SFX
	STA $1DF9|!addr				;/

	if !Setting_PlayerHP_BarAnimation != 0
		%RemovePlayerHPBarRecord()
	endif

	MarioAbove:
	MarioSide:
	TopCorner:
	BodyInside:
	HeadInside:
	WallFeet:
	WallBody:
	SpriteV:
	SpriteH:
	MarioCape:
	MarioFireball:
	RTL

print "Character customizations preset 0"