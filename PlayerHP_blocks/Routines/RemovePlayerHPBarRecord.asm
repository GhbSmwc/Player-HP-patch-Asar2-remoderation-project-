incsrc "../PlayerHPDefines.asm"
incsrc "../MotherHPDefines.asm"
incsrc "../GraphicalBarDefines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Remove record effect.
;;
;;Be aware at the time of writing, asar had a bug where labels leak out
;;of %Macros():
;;
;; MainLabel:
;;  %CallSubroutine() ;>labels inside here are treated as if it is here outside.
;; .Sublabel ;>it is supposed to attach to "MainLabel:", but instead attaches to the last parent label in the macro.
;;
;; This causes error saying "MainLabel_Sublabel" not being found.
;;
;; I really hope this f*cked up glitch is fixed soon.
;;
;; Also, to warn you, using sublabels are just treated as main labels,
;; but with sublabels appended to the parent label separated with "_"
;; so for an example:
;;
;; Label                ; treated as main label
;; -----                ------------------------
;; Main:                ;>"Main:"
;; .Sub1                ;>"Main_Sub1:"
;; ..Sub2               ;>"Main_Sub1_Sub2:"
;;
;; so if you use "Main_Sub1:" while the "Main:" and ".Sub1" exist, it will
;; error out.
;;
;; This leaking issue also happens with +/- as well, treating them as if
;; they're outside the macro.
;;
;; Also, at the time of writing, you cannot call a subroutine via %CallRoutine()
;; inside a subroutine. If you're running low on space, I HIGHLY recommend
;; using the shared subroutine patch to alleviate the limitations of trying
;; to have subroutines used in multiple tools and patches.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA !Freeram_PlayerCurrHP			;\Current HP
	STA !Scratchram_GraphicalBar_FillByteTbl	;|
	if !Setting_PlayerHP_TwoByte == 0		;|
		LDA #$00				;|
	else						;|
		LDA !Freeram_PlayerCurrHP+1		;|
	endif						;|
	STA !Scratchram_GraphicalBar_FillByteTbl+1	;/
	LDA !Freeram_PlayerMaxHP			;\Max HP
	STA !Scratchram_GraphicalBar_FillByteTbl+2	;|
	if !Setting_PlayerHP_TwoByte == 0		;|
		LDA #$00				;|
	else						;|
		LDA !Freeram_PlayerMaxHP+1		;|
	endif						;|
	STA !Scratchram_GraphicalBar_FillByteTbl+3	;/
	if !Default_LeftPieces == !Default_RightPieces		;\Number of pieces in each 8x8.
		LDA.b #!Default_LeftPieces			;|
		STA !Scratchram_GraphicalBar_LeftEndPiece	;|
		STA !Scratchram_GraphicalBar_RightEndPiece	;|
	else							;|
		LDA.b #!Default_LeftPieces			;|
		STA !Scratchram_GraphicalBar_LeftEndPiece	;|
		LDA.b #!Default_RightPieces			;|
		STA !Scratchram_GraphicalBar_RightEndPiece	;|
	endif							;|
	LDA.b #!Default_MiddlePieces				;|
	STA !Scratchram_GraphicalBar_MiddlePiece		;/
	LDA.b #!Default_MiddleLengthLevel			;\number of middle 8x8s
	STA !Scratchram_GraphicalBar_TempLength			;/
	;JSR CalculateGraphicalBarPercentage
	;RTL

?CalculateGraphicalBarPercentage:
?.FindTotalPieces
?..FindTotalMiddle
	LDA !Scratchram_GraphicalBar_MiddlePiece
	STA $00
	STZ $01
	LDA !Scratchram_GraphicalBar_TempLength
	STA $02
	STZ $03
	%MathMul16_16()				;MiddlePieceper8x8 * NumberOfMiddle8x8. Stored into $04-$07 (will read $04-$05 since number of pieces are 16bit, not 32)
?..FindTotalEnds ;>2 8-bit pieces added together, should result a 16-bit number not exceeding $01FE (if $200 or higher, can cause overflow since carry is only 0 or 1, highest highbyte increase is 1).
	STZ $01						;>Clear highbyte
	LDA !Scratchram_GraphicalBar_LeftEndPiece	;\Lowbyte total
	CLC						;|
	ADC !Scratchram_GraphicalBar_RightEndPiece	;|
	STA $00						;/
	LDA $01						;\Handle high byte (if an 8-bit low byte number exceeds #$FF, the high byte will be #$01.
	ADC #$00					;|$00-$01 should now hold the total fill pieces in the end bytes/8x8 tiles.
	STA $01						;/
?..FindGrandTotal
	REP #$20
	LDA $04						;>Total middle pieces
	CLC
	ADC $00						;>Plus total end
?.TotalPiecesTimesQuantity
	STA $00						;>Store grand total in input A of 32x32bit multiplication
	STZ $02						;>Rid the highword (#$0000XXXX)
	LDA !Scratchram_GraphicalBar_FillByteTbl	;\Store quantity
	STA $04						;/
	STZ $06						;>Rid the highword (#$0000XXXX)
	SEP #$20
	%MathMul32_32()					;>Multiply together. Results in $08-$0F (8 bytes; 64 bit).

	;Okay, the reason why I use the 32x32 bit multiplication is because
	;it is very easy to exceed the value of #$FFFF (65535) should you
	;have a number of pieces in the bar (long bar, or large number per
	;byte).
	
	;Also, you may see "duplicate" routines with the only difference is
	;that they are different number of bytes for the size of values to
	;handle, they are included and used because some of my code preserves
	;them and are not to be overwritten by those routines, so a smaller
	;version is needed, and plus, its faster to avoid using unnecessarily
	;large values when they normally can't reach that far.
	
	;And finally, I don't directly use SA-1's multiplication and division
	;registers outside of routines here, because they are signed. The
	;amount of fill are unsigned.

?.DivideByMaxQuantity
	REP #$20
	LDA $08						;\Store result into dividend (32 bit only, its never to exceed #$FFFFFFFF), highest it can go is #$FFFE0001
	STA $00						;|
	LDA $0A						;|
	STA $02						;/
	LDA !Scratchram_GraphicalBar_FillByteTbl+2	;\Store MaxQuantity into divisor.
	STA $04						;/
	SEP #$20
	%MathDiv32_16()					;>;[$00-$03 : Quotient, $04-$05 : Remainder], After this division, its impossible to be over #$FFFF.
?..Rounding
	REP #$20
	LDA !Scratchram_GraphicalBar_FillByteTbl+2	;>Max Quantity
	LSR						;>Divide by 2 (halfway point of max)..
	BCC ?...ExactHalfPoint				;>Should a remainder in the carry is 0 (no remainder), don't round the 1/2 point
	INC						;>Round the 1/2 point

	?...ExactHalfPoint
	CMP $04						;>Half of max compares with remainder
	BEQ ?...RoundDivQuotient			;>If HalfPoint = Remainder, round upwards
	BCS ?...NoRoundDivQuotient			;>If HalfPoint > remainder (or remainder is smaller), round down (if exactly full, this branch is taken).

	?...RoundDivQuotient
	;^this also gets branched to if the value is already an exact integer number of pieces (so if the
	;quantity is 50 out of 100, and a bar of 62, it would be perfectly at 31 [(50*62)/100 = 31]
	LDA $00						;\Round up an integer
	INC						;/
	STA $08						;>move towards $08 because 16bit*16bit multiplication uses $00 to $07

	;check should this rounded value made a full bar when it is actually not:
	
	?....RoundingUpTowardsFullCheck
	;Just as a side note, should the bar be EXACTLY full (so 62/62 and NOT 61.9/62, it guarantees
	;that the remainder is 0, so thus, no rounding is needed.) This is due to the fact that
	;[Quantity * FullAmount / MaxQuantity] when Quantity and MaxQuantity are the same number,
	;thus, canceling each other out (so 62 divide by 62 = 1) and left with FullAmount (the
	;number of pieces in the bar)
	
	;Get the full number of pieces
	LDA !Scratchram_GraphicalBar_MiddlePiece	;\Get amount of pieces in middle
	AND #$00FF					;|
	STA $00						;|
	LDA !Scratchram_GraphicalBar_TempLength		;|
	AND #$00FF					;|
	STA $02						;/
	SEP #$20
	%MathMul16_16()					;>[$04-$07: Product]
	LDY #$00					;>Default that the meter didn't round towards empty/full (cannot be before the above subroutine since it overwrites Y).

	;add the 2 ends tiles amount (both are 8-bit, but results 16-bit)
	
	;NOTE: should the fill amount be exactly full OR greater, Y will be #$00.
	;This is so that greater than full is 100% treated as exactly full.
	LDA #$00					;\A = $YYXX, (initially YY is $00)
	XBA						;/
	LDA !Scratchram_GraphicalBar_LeftEndPiece	;\get total pieces
	CLC						;|\carry is set should overflow happens (#$FF -> #$00)
	ADC !Scratchram_GraphicalBar_RightEndPiece	;//
	XBA						;>A = $XXYY
	ADC #$00					;>should that overflow happen, increase the A's upper byte (the YY) by 1 ($01XX)
	XBA						;>A = $YYXX, addition maximum shouldn't go higher than $01FE. A = 16-bit total ends pieces
	REP #$20
	CLC						;\plus middle pieces = full amount
	ADC $04						;/
	CMP $08						;>compare with rounded fill amount
	BNE ?.....TransferFillAmtBack			;\should the rounded up fill matches with the full value, flag that
	LDY #$02					;/it had rounded to full.

	?.....TransferFillAmtBack
	LDA $08						;\move the fill amount back to $00.
	STA $00						;/
	BRA ?.Done
	
	?...NoRoundDivQuotient
	?....RoundingDownTowardsEmptyCheck
	LDY #$00					;>Default that the meter didn't round towards empty/full.
	LDA $00						;\if the rounded down (result from fraction part is less than .5) quotient value ISN't zero,
	BNE ?.Done					;/(exactly 1 piece filled or more) don't even consider setting Y to #$01.
	LDA $04						;\if BOTH rounded down quotient and the remainder are zero, the bar is TRUELY completely empty
	BEQ ?.Done					;/and don't set Y to #$01.
	
	LDY #$01					;>indicate that the value was rounded down towards empty
	
	?.Done
	SEP #$20
	;RTL
	
	if !Setting_PlayerHP_BarAvoidRoundToZero != 0
		CPY #$01
		BNE ?.NotRoundedToEmpty
		
		LDA #$01		;\round towards 1 pixel when near-empty.
		STA $00			;|
		STZ $01			;/
		
		?.NotRoundedToEmpty
	endif
	
	;Set record to current HP percentage
	LDA $00
	STA !Freeram_PlayerHP_BarRecord
	RTL