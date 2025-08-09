incsrc "../GraphicalBarDefines/GraphicalBarDefines.asm"
		?FindNFreeOAMSlot:
			;Input: $04 = Number of slots open to search for
			;Output: Carry = Set if not enough slots found, Clear if enough slots found
			;NOTE: XY registers must be 16-bit (because Y goes up to 508 ($01FC)). XY remains 16-bit after this is done.
			PHY
			LDY.w #$0000					;>Open slot counter
			LDX.w #!GraphicalBar_OAMSlot*4			;>skip the first four slots (Index_Increment4 = Slot*4)
			?.loop:						;>to avoid message box conflicts
				CPX.w #(128*4)				;\If all slots searched, there is not enough (There are 128 slots, that means 128*4 = 512 Index_Increment4)
				BEQ ?.notEnoughFound			;/open slots being found
		
				LDA $0201|!addr,x			;\If slot used, that isn't empty
				CMP #$F0				;|
				BNE ?..notFree				;/
				INY					;>Otherwise if it is unused, count it
				CPY $04					;\If we find n slots that are free, break
				BEQ ?.enoughFound			;/
				?..notFree:
					INX #4				;\Check another slot
					BRA ?.loop			;/
			?.notEnoughFound:
				SEC
				BRA ?.Done
			?.enoughFound:
				CLC
			?.Done
				PLY
				RTL