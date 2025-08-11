;Act as $00 or $25.

;This block slowly damage the player while touching.

;Make sure you have !Setting_PlayerHP_GradualHPChange set to 1.

;Note: Hitbox wonky if riding yoshi when the block
;is 1 block high and the player touches at certain
;x positions.


;Only use these values:
;$00, $01, $03, $07, $0F, $1F, $3F, $7F, or $FF.
;Other values would cause erratic damage rate. The
;lower, the faster. A side note is that the head
;offset does not run every frame when only the
;head offset is running and nothing else,
;therefore takes longer to subtract HP.
	!DamageSpeed		= $03

;Amount of HP per period (after a
;certain frames based on above). Not to
;exceed 128.
	!DamagePerPeriod		= 1

;sound number
	!HPSlowDamageSFXNumb	= $06

;RAM for sfx. Automatically SA-1 Address converted.
	!HPSlowDamageSFXPort =		$1DFC|!addr

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

incsrc "../../../PlayerHPDefines.asm"


assert !DamagePerPeriod <= 128, "Must be less than or equal to 128."

MarioSide:
HeadInside:			;>When mario's head touches side.
	%SideContactCheck()	;>this code does not run every frame with mario's head due to non-double sided left and right collision points
	BEQ Return

MarioBelow:
MarioAbove:
TopCorner:
BodyInside:
	LDA $1490|!addr					;\Don't damage the player on certain situations.
	ORA $1493|!addr					;|
	ORA $71						;|
	;ORA <address>					;|
	BNE Return					;/

	if !DamageSpeed != $00
	;^If you play SFX every single frame, it overwrites port of the same channel and causes glitches (other sound uses this channel get replaced with this sfx).
		LDA $14					;\Certain frames damage.
		AND #!DamageSpeed			;|
		BNE Return				;/
		LDA #!HPSlowDamageSFXNumb		;\Play SFX
		STA !HPSlowDamageSFXPort		;/
		LDA.b #($100-!DamagePerPeriod)		;\Set damage
		STA !Freeram_PlayerHP_GradualHPChange	;/
		if and(notequal(!PlayerHP_BarRecordDelay, 0), notequal(!Setting_PlayerHP_BarAnimation, 0))
			LDA.b #!PlayerHP_BarRecordDelay
			STA !Freeram_PlayerHP_BarRecordDelayTmr
		endif
	else
		LDA $14					;\Leave a 1 frame gap of the two
		AND #$01				;|with no sound to prevent audio glitch
		BNE NoRapidSound			;/with overwriting port.
		LDA #!HPSlowDamageSFXNumb		;\Play SFX
		STA !HPSlowDamageSFXPort		;/

		NoRapidSound:
		LDA.b #($100-!DamagePerPeriod)		;\Set damage
		STA !Freeram_PlayerHP_GradualHPChange	;/
		if and(notequal(!PlayerHP_BarRecordDelay, 0), notequal(!Setting_PlayerHP_BarAnimation, 0))
			LDA.b #!PlayerHP_BarRecordDelay
			STA !Freeram_PlayerHP_BarRecordDelayTmr
		endif
	endif
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	SEP #$20
	RTL

print "Slowly damages the player while touching."