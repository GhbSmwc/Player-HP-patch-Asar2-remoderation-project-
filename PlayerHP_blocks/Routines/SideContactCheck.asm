;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Like the muncher and spikes in SMW, merely touching the sides of them
;without moving against them doesn't harm the player, unless the player
;is 1 pixel more than what the game allows. If you're using custom player
;hitboxes, you might want to fiddle around the x position boundaries here
;so that it works as intended.
;
;Output:
; A:
;  #$00 if the player is touching without moving in towards the block.
;  #$01 if the player is moving into towards the left side of the block.
;  #$02 if the player is moving into towards the right side of the block.

!BlockHitboxPos		= $000E ;>X position displacement of the hitbox relative to block. This is the leftmost boundary.
!BlockHitboxWidth	= $001A ;>The width of the box.
;^Increasing !BlockHitboxWidth would extend the box rightwards, while changing !BlockHitboxPos would move the entire box.

!CollisionMode		= 0	;>0 = use the position-related collision detection, 1 = use actual hitbox detection
;^In case if you're too lazy with fiddling with the routine, assuming that the hitbox patches modifies the player's
; hitbox size.

	if !CollisionMode == 0
		REP #$20		;\Block X position
		LDA $9A			;|
		AND #$FFF0		;/
		SEC			;\The x position the player would be if he's
		SBC.w #!BlockHitboxPos	;|to the left of it touching with 1+ pixel
		CMP $94			;|deeper (this is the x position of the "hitbox area" of the left boundary)
		BPL NoTouch		;/
		CLC				;\Move to the right side of the block that
		ADC.w #!BlockHitboxWidth	;|the player would've been when he's touching
		CMP $94				;|the right side 1+ pixel deeper (this is the width
		BMI NoTouch			;/of the range that's consitered touching)
	else
		JSL $03B664			;>Get player hitbox (clipping B)
		LDA $9A				;\Get block's hitbox x position
		AND #$F0			;|
		INC				;|
		STA $04				;|
		LDA $9B				;|
		ADC #$00			;|
		STA $0A				;/
		LDA $98				;\Get Y position 
		AND #$F0			;|
		CLC				;|
		ADC #$08			;|
		STA $05				;|
		LDA $99				;|
		ADC #$00			;|
		STA $0B				;/
		LDA #$0D			;\Width
		STA $06				;/
		LDA #$10			;\Height
		STA $07				;/
		JSL $03B72B			;>Check contact
		BCC NoTouch			;>If not, return.
		
		REP #$20
	endif
	
	;SideCheck
	LDA $9A			;\Block position compares with player
	AND #$FFF0		;|
	CMP $94			;|
	SEP #$20		;|
	BPL LeftTouch		;/
	
	;RightTouch
	LDA #$02
	RTL
	
	LeftTouch:
	LDA #$01
	RTL

	NoTouch:
	SEP #$20
	LDA #$00
	RTL