;This ASM file prevents max HP upgrade blocks from respawning after the player picks them
;up and re-enters the level.
load:
	%UberRoutine(PlayerHPSearchUpgradeIndex)
	%UberRoutine(PlayerHPDisableUpgradeRespawn)
	RTL