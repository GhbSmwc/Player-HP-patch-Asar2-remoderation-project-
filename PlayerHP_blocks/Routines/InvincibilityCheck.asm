;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Invincibility check.
;
;Output: A = nonzero if the player is invincible.
;
;Separate from DamagePlayer subroutine so that in case if the user decides to
;enable knockback, if the player is invincible, won't knockback him despite no
;damage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $1497|!addr			;\Don't hurt mario when he's invincible
	ORA $1490|!addr			;|
	ORA $1493|!addr			;/
	ORA $71				;>SMW had the hitbox & damage code run every frame from some sprites.
	RTL