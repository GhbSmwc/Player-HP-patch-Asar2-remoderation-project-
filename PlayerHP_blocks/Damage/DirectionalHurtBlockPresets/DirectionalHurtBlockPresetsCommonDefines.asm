;This is a defines file for all 4 directional hurt block preset defines, needed if the user wanted all 4 of them to have
;consistency with the damage, rather to hurt the player or instant kill, etc.

;Damage or instant kill:
; *0 = hurt
; *1 = instant kill (regardless of invincibility frames)
	!HurtKill		= 0

;How much HP loss from touching this block on harmful side (only when above setting set to hurt).
	!DamageAmount		= 5

;Knockback speeds. For left and up speeds, use only values #$80-#$FF with #$80 being the fastest, for
; right/down speeds, use only values #$01-#$7F with #$7F being the fastest speed.
	!MuncherKnockbackUp		= $C0
	!MuncherKnockbackDown		= $70
	!MuncherKnockbackHorizSpd	= !Setting_PlayerHP_KnockbackHorizSpd
	!MuncherKnockbackHorizUpSpd	= !Setting_PlayerHP_KnockbackUpwardsSpd ;>horizontal upwards speed.