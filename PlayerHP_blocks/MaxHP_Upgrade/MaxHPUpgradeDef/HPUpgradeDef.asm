;The defines for all max HP upgrade blocks.
;
;NOTE: not all defines are on here, for example, some defines are specific to what
;healing blocks to allow different settings, like how much max HP have been increased.

;Spawn score sprite:
; $00 = none
; $01 = 10
; $02 = 20
; $03 = 40
; $04 = 80
; $05 = 100
; $06 = 200
; $07 = 400
; $08 = 800
; $09 = 1000
; $0A = 2000
; $0B = 4000
; $0C = 8000
; $0D = 1up
; $0E = 2up
; $0F = 3up
; $10 = 5up (may glitch)
	!GiveScore		= $00
;Display message:
; $00 = none
; $01 = message 1
; $02 = message 2
; $03 = Yoshi thanks message.
	!MessageBox		= $01


;SFX. Check here: https://www.smwcentral.net/?p=viewthread&t=6665
	!HPUpgrade_SFXNum	= $2A
	!HPUpgrade_SFXRAM	= $1DF9|!addr

;0 = all HP upgrades increases max HP by the same amount
;1 = each HP upgrade increases depending on the level and block bit number.
;
;When set to 1, be aware that you must edit the tables at the bottom of the text
;of each of the 8 block bits in order to properly include how much max HP to add.
;Else you end up increasing by a garbage value (stuff beyond the table not meant for
;increasing max HP).
	!HPUpgrade_VaryingIncrease	= 1

;How many HP the max HP was increased by. This only applies if 
;!HPUpgrade_VaryingIncrease = 0.
!HPUpgrade_MaxIncreaseBy	= 10