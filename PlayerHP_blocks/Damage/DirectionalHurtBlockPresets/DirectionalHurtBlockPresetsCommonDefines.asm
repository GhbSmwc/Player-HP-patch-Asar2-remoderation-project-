;This is a defines file for all 4 directional hurt block preset defines, needed if the user wanted all 4 of them to have
;consistency with the damage, rather to hurt the player or instant kill, etc.

;Damage type:
; - 0 = fixed damage amount.
; - 1 = damage amount equal to proportion of max HP.
; - 2 = instant kill (regardless of invincibility frames).
	!DamageType		= 0

;How much HP loss from touching this block on the harmful side (when !DamageType == 0).
	!FixedDamageAmount		= 5
;Proportion of max HP damage when touching the block, only used when
;!Sm64DamageType == 1
	!DamageDividend	= 2
	!DamageDivisor	= 5

;Knockback speeds. For left and up speeds, use only values #$80-#$FF with #$80 being the fastest, for
; right/down speeds, use only values #$01-#$7F with #$7F being the fastest speed.
	!MuncherKnockbackUp		= $C0
	!MuncherKnockbackDown		= $70
	!MuncherKnockbackHorizSpd	= !Setting_PlayerHP_KnockbackHorizSpd
	!MuncherKnockbackHorizUpSpd	= !Setting_PlayerHP_KnockbackUpwardsSpd ;>horizontal upwards speed.