;Act as $00 or $25.

;This blocks slowly heals the player while touching.

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
	!RecoverySpeed		= $03

;Amount of HP per period (after a
;certain frames based on above). Not to
;exceed 127.
	!RecovPerPeriod		= 1

;Sound effects
	!HPSlowHealSFXNumb	= $1C
	!HPSlowHealSFXPort	= $1DF9|!addr

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

incsrc "../../../PlayerHPDefines.asm"

assert !RecovPerPeriod <= 127, "Must be less than or equal to 127."

MarioSide:
HeadInside:			;>When mario's head touches side.
	%SideContactCheck()	;>this code does not run every frame with mario's head due to non-double sided left and right collision points
	BEQ Return

MarioBelow:
MarioAbove:
TopCorner:
BodyInside:
	LDA $71					;\Don't heal the player on certain situations.
	;ORA <address>				;|
	BNE Return				;/
	if !Setting_PlayerHP_TwoByte == 0
		LDA !Freeram_PlayerCurrHP
		CMP !Freeram_PlayerMaxHP
	else
		REP #$20
		LDA !Freeram_PlayerCurrHP
		CMP !Freeram_PlayerMaxHP
		SEP #$20
	endif
	BCS Return				;>No SFX at full HP.
	if !RecoverySpeed != $00
	;^If you play SFX every frame, it overwrites port of the same channel.
		LDA $14				;\Certain frames recovers HP.
		AND #!RecoverySpeed		;|
		BNE Return			;/
		LDA #!HPSlowHealSFXNumb		;\Play SFX
		STA !HPSlowHealSFXPort		;/
		LDA.b #!RecovPerPeriod		;\Set heal
		STA !Freeram_PlayerHP_GradualHPChange	;/
		if and(notequal(!PlayerHP_BarRecordDelay, 0), notequal(!Setting_PlayerHP_BarAnimation, 0))
			LDA.b #!PlayerHP_BarRecordDelay
			STA !Freeram_PlayerHP_BarRecordDelayTmr
		endif
	else
		LDA $14				;\Leave a 1 frame gap of the two
		AND #$01			;|with no sound to prevent audio glitch
		BNE NoRapidSound		;/with overwriting port.
		LDA #!HPSlowHealSFXNumb		;\Play SFX
		STA !HPSlowHealSFXPort		;/

		NoRapidSound:
		LDA.b #!RecovPerPeriod			;\Set heal
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

print "Slowly heals the player while touching."