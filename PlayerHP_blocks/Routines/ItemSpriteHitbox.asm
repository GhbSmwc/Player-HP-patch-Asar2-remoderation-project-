;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Obtain the hitbox used by most item sprites.
;;
;;Output: Hitbox A settings. Please refer to $03B72B (labeled
;;"CheckForContact") for more info.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;.MishroomCollision ;>Hitbox A settings
	;;Hitbox notes for mushroom clipping (tested via debugger to find the info):
	;; HitboxXpos = MushroomXPos + $02
	;; HitboxYPos = MushroomYPos + $03
	;; Width = $0C
	;; Height = $0A
	LDA $9A						;\X position
	AND #$F0					;|
	CLC						;|
	ADC #$02					;|
	STA $04						;|
	LDA $9B						;|
	ADC #$00					;|
	STA $0A						;/
	LDA $98						;\Y position
	AND #$F0					;|
	CLC						;|
	ADC #$03					;|
	STA $05						;|
	LDA $99						;|
	ADC #$00					;|
	STA $0B						;/
	LDA #$0C					;\Width
	STA $06						;/
	LDA #$0A					;\Height
	STA $07						;/
	RTL