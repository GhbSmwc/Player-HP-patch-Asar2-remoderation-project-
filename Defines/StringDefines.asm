;This define file is for handling strings (text), mainly for left-aligned or right-aligned
;display for routines.

		if !sa1 == 0
			!Scratchram_CharacterTileTable = $7F8458
		else
			!Scratchram_CharacterTileTable = $40414A
		endif
			;^[X bytes] A string buffer, each byte here is a character
			; (often digits used by left or right aligned number display).
			; The number of bytes used is the most number of characters
			; you would write in your entire game.
			; For example:
			; - If you want to display a 5-digit 16-bit number 65535,
			;   that will be 5 bytes.
			; - If you want to display [10000/10000], that will be
			;   11 bytes (2 numbers up to 5 digits, plus 1 because
			;   "/"; 5 + 5 + 1 = 11)
			; - For 32-bit hexdec:
			; -- For displaying a left-aligned number will be !Setting_32bitHexDec_MaxNumberOfDigits
			; -- For X/Y display: (!Setting_32bitHexDec_MaxNumberOfDigits*2)+1
			; This then can get transferred to the status bar/stripe/sprite tile via calling
			; - WriteStringDigitsToHUD (including the Format2 variant)
			; - WriteStringAsSpriteOAM (including the OAMOnly variant)