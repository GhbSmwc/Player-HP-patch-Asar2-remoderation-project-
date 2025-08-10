;This prevents Mario from being small mario whenever the player boots up the game
;and when continuing after a game over.
init:
	.NoSmallMario
	LDA #$01				;\If #$01 < $19 ($19 is >= to #$01; at least super),
	CMP $19					;|don't set powerup state to super.
	BCC ..DontSetPowerup			;|
	STA $19					;/
	STA $0DB8|!addr				;\That was setting the player's powerup to #$00
	STA $0DB9|!addr				;/during load.
	..DontSetPowerup
	RTL