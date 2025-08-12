;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Knock player left or right when touching the side
;of the block.
;To be used after %SideContactCheck()
;
;Input:
; A = #$00:      No knockback
; A = #$01:      Knock leftwards
; A = #$02-#$FF: Knock rightwards
;
; $00:           Knock X speed (only use #$01-#$7F)
;                 this will automatically calculate
;                 both left and right speeds, should
;                 it be negative, automatically treats
;                 as if the value is #$7F for failsafe.
;
; $01            Knock Y speed (player actually flings
;                 diagonally upwards). Will be ignored
;                 if the player dones a death animation
;                 as to prevent alterations of his Y
;                 speed. Notet that this itself doesn't
;                 have a failsafe.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;ValidSpeedCheck
	LDX $00				;\Failsafe if a user made a routine that calculates in-game the X speed to be over #$7F
	BPL ?+				;|
	LDX #$7F			;|
	STX $00				;/
	
	;CheckDirection
	?+
	CMP #$00			;>CMP is needed if LDX/LDY was used prior to this subroutine to affect the branch below
	BEQ ?+				;>If #$00, no knockback
	CMP #$01			;\If #$01, knock leftwards
	BEQ ?++				;/
	
	;KnockRightwards
	LDA $00
	BRA ?+++
	
	;KnockLeftwards
	?++
	LDA $00				;\Invert X speed
	EOR #$FF			;|
	INC				;/
	
	?+++
	STA $7B
	
	;Yspeed
	LDA $71				;\Prevent altering dying mario's Y speed.
	CMP #$09			;|
	BEQ ?+				;/
	LDA $01
	STA $7D
	
	?+
	RTL