incsrc "../GraphicalBarDefines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This writes a given tile to sprite OAM.
;
;Note: Not to be used for “normal sprites” (the generally
;interactable sprites such as SMW or pixi sprites using 12 (22 for
;SA-1) slots). This writes OAM directly like most sprite status bar
;patches.
;
;Input
; - $00 to $01: X position, relative to screen border.
; - $02 to $03: Y position, same as above but Y position
; - $04: Tile number
; - $05: Properties (YXPPCCCT).
; - $06: Size: $00 = 8x8, $02 = 16x16, don't use other values.
;Output
; - Carry: Set if no available slots found, otherwise clear.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?WriteOAMTile:
	?.SearchOpenSlot
		PHB
		PHK
		PLB
		REP #$10
		LDY.w #!GraphicalBar_OAMSlot*4			;>skip the first four slots (Index_Increment4 = Slot*4)
		?..Loop
			CPY.w #(128*4)
			BEQ ?.NoAvailableSlotFound
			
			LDA $0201|!addr,y
			CMP #$F0
			BNE ?...NotFree
			?...EmptySlotFound
				LDA $06
				TAX
				REP #$20			;\If offscreen, go to next tile of the graphical bar, and reuse the same OAM index (don't hog the slots for nothing)
				LDA $00				;|\X position
				CMP ?TopAndLeftBorder,x		;||
				SEP #$20			;||
				BMI ?....OffScreen		;||
				REP #$20			;||
				CMP #$0100			;||
				SEP #$20			;||
				BPL ?....OffScreen		;|/
				REP #$20			;|
				LDA $02				;|\Y position
				CMP ?TopAndLeftBorder,x		;||
				SEP #$20			;||
				BMI ?....OffScreen		;||
				REP #$20			;||
				CMP #$00E0			;||
				SEP #$20			;||
				BPL ?....OffScreen		;//
				LDA $00				;\Low 8 bits of X position
				STA $0200|!addr,y		;/
				
				REP #$30		;>Because we are transferring Y (16-bit) to A (8-bit), it's best to have both registers 16-bit.
				TYA			;>TYA : LSR #4 TAY converts the Y slot index (increments of 4) into slot number (increments of 1)
				LSR #2			;\Handle 9th bit X position
				PHY			;|
				TAY			;|
				LDA $01			;|
				SEP #$20		;|
				AND.b #%00000001	;|
				ORA $06			;|>And handle the size bit
				STA $0420|!addr,y	;/
				PLY
				
				LDA $02						;\Y pos
				STA $0201|!addr,y				;/
				
				LDA $04						;\Tile number
				STA $0202|!addr,y				;/
				
				LDA $05						;\Properties
				STA $0203|!addr,y				;/

				?....OffScreen
				SEP #$30
				CLC
				PLB
				RTL
			
			?...NotFree
				INY #4
				BRA ?..Loop
	?.NoAvailableSlotFound
		SEC
		PLB
		RTL
?TopAndLeftBorder:
	dw $FFF8+1
	dw $FFF0+1