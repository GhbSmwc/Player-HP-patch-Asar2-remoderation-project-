if defined("sa1") == 0
	incsrc "SA1StuffDefines.asm"
endif
incsrc "StatusBarDefines.asm"
;This is the main defines file.
;Be sure to check out the others defines for customizations.
;
;Only use valid numbers, if it is a setting, only use the numbers shown
;on its description. This applies to all defines and settings.
;
;Note(s):
;-If you plan on not having the overworld or barely use it (such as 1 level hacks),
; you can simply set "!Setting_PlayerHP_OverworldDisplay" to 0 and it won't write any
; display data onto RAM relating to the overworld border.
;
;-By default, this patch doesn't expect you're using custom sprites. This is due to
; untouched RAM being randomized values. To allow custom sprites to deal proper damage
; to the player, set !Setting_PlayerHP_UsingCustomSprites to 1.
;
;-For status bar-related defines for other status bar patches: The defines relating
; to the positions of the display are actually RAM address table for status bar patches.
; For example and by default: $7FA000 for !PlayerHP_Digit_StatBarPos is the top-left
; corner-most tile of the super status bar patch. You may also need to change
; !StatusbarFormat as other patches might have a different table format. Make sure you
; read the information of such patches to figure out what number goes there.
;=====================================================================================

;Freeram stuff
;Remember that during SA-1 mode, wram address banks $7E/$7F are not accessible.
;Banks $40/$41 to be used instead. Another note to check other files as they
;too contain freeram defines to modify.
;RAM address info for in case if the default address was used by ASM codes not
;relating to the player's HP.
;Ordered in increasing address order
;
;Normal ROM:
; 60 Scratchram_GraphicalBar_LeftEndPiece
; 61 Scratchram_GraphicalBar_MiddlePiece
; 62 Scratchram_GraphicalBar_RightEndPiece
; 7F8449 Scratchram_GraphicalBar_TempLength
; 7F844A Scratchram_GraphicalBar_FillByteTbl Scratchram_CharacterTileTable
; 7FAD49-7FAD4A Freeram_PlayerCurrHP
; 7FAD4B-7FAD4C Freeram_PlayerMaxHP
; 7FAD4D Freeram_PlayerHP_BarRecord
; 7FAD4E Freeram_PlayerHP_BarRecordDelayTmr
; 7FAD4F Freeram_PlayerHP_Knockback
; 7FAD50 Freeram_PlayerHP_GradualHPChange
; 7FAD51-?????? Freeram_PlayerHP_MaxHPUpgradePickupFlag
; 7FAD61 Freeram_PlayerHP_MotherHPDirection
; 7FAD62-7FAD63 Freeram_PlayerHP_MotherHPChanger
; 7FAD64 Freeram_PlayerHP_MotherHPDelayFrameTimer
; 7FAD65 Freeram_PlayerHP_MotherHPDelayDamageLast
; 
;SA-1 ROM:
; 400195 Scratchram_GraphicalBar_LeftEndPiece
; 400196 Scratchram_GraphicalBar_MiddlePiece
; 400197 Scratchram_GraphicalBar_RightEndPiece
; 40019D Scratchram_GraphicalBar_FillByteTbl Scratchram_CharacterTileTable
; 4001B8 Scratchram_GraphicalBar_TempLength
; 4001B9-4001BA Freeram_PlayerCurrHP
; 4001BB-4001BC Freeram_PlayerMaxHP
; 4001BD Freeram_PlayerHP_BarRecord
; 4001BE Freeram_PlayerHP_BarRecordDelayTmr
; 4001BF Freeram_PlayerHP_Knockback
; 4001C0 Freeram_PlayerHP_GradualHPChange
; 4001C1-?????? Freeram_PlayerHP_MaxHPUpgradePickupFlag
; 4001D1 Freeram_PlayerHP_MotherHPDirection
; 4001D2-4001D3 Freeram_PlayerHP_MotherHPChanger
; 4001D4 Freeram_PlayerHP_MotherHPDelayFrameTimer
; 4001D5 Freeram_PlayerHP_MotherHPDelayDamageLast
; 

;[BytesUsed = 1 + !Setting_PlayerHP_TwoByte]
;Player current HP.
	if !sa1 == 0
		!Freeram_PlayerCurrHP		= $7FAD49 ;>Normal ROM version
	else
		!Freeram_PlayerCurrHP		= $4001B9 ;>SA-1 Version
	endif
;[BytesUsed = 1 + !Setting_PlayerHP_TwoByte]
;Player max HP.
	if !sa1 == 0
		!Freeram_PlayerMaxHP		= $7FAD4B
	else
		!Freeram_PlayerMaxHP		= $4001BB
	endif
;[BytesUsed = !Setting_PlayerHP_BarAnimation]
;A display that shows the amount of HP as a bar prior to taking damage
;or healing. This shows how much HP lost or recovered only on levels and
;never used on the overworld map (the player never takes damage or heal
;during that game state).
	if !sa1 == 0
		!Freeram_PlayerHP_BarRecord	= $7FAD4D
	else
		!Freeram_PlayerHP_BarRecord	= $4001BD
	endif
;[BytesUsed = RecordTimerEnabled]
;A timer that indicates how long the bar shows the previous HP prior
;heal or damage before it moves towards the player's current HP.
;RecordTimerEnabled = 1 if both !Setting_PlayerHP_BarAnimation
;and !PlayerHP_BarRecordDelay are non-zero values and 0 otherwise.
	if !sa1 == 0
		!Freeram_PlayerHP_BarRecordDelayTmr	= $7FAD4E
	else
		!Freeram_PlayerHP_BarRecordDelayTmr	= $4001BE
	endif
;[BytesUsed = KnockbackEnabled]
;Stun flag of the player getting knocked back. When nonzero, the
;player is unable to move.
; - If !Setting_PlayerHP_Knockback is set to 1, this acts as a frame
;   timer that goes down by 1 each frame.
; - If !Setting_PlayerHP_Knockback is set to 2, this stays at a
;   nonzero value until the player touches the ground
;KnockbackEnabled = 1 if !Setting_PlayerHP_Knockback is nonzero
;and 0 otherwise.
	if !sa1 == 0
		!Freeram_PlayerHP_Knockback	= $7FAD4F
	else
		!Freeram_PlayerHP_Knockback	= $4001BF
	endif
;[BytesUsed = !Setting_PlayerHP_GradualHPChange]
; RAM value that slowly increments and decrements
; the player's HP by that amount per frame. Positive
; values (1 to 127 heals the player, while negative
; values (-128 to -1 drains the player's HP)). Note
; that you have to periodically  (at your own frequency)
; set this to a nonzero for this to work. This exist
; because custom blocks can have codes executed multiple
; times a frame when multiple player collision points
; touches the block. After changing the player's HP,
; this reset itself to 0. Not to be confused with the
; rolling HP that damage and healing will keep going
; despite the player not taking hits or healing.
	if !sa1 == 0
		!Freeram_PlayerHP_GradualHPChange = $7FAD50
	else
		!Freeram_PlayerHP_GradualHPChange = $4001C0
	endif
;[BytesUsed = NumberOfLevelsThatUsesMaxHPUpgradeBlocks]
;A RAM table containing pickup flags to prevent the
;HP upgrade blocks from re-spawning after they are picked up.
;
;Format: each level that do uses the HP upgrade takes a
;single byte (8-bit). Each bit corresponds what block writes
;a set bit to (so "MaxHP_UpgradeBit0.asm" writes to bit 0).
;Therefore you can only have up to 8 upgrade blocks per
;level, and you cannot have duplicates in a level (both will
;disappear). They will switch what byte based on what level
;listed the player is in.
	if !sa1 == 0
		!Freeram_PlayerHP_MaxHPUpgradePickupFlag = $7FAD51
	else
		!Freeram_PlayerHP_MaxHPUpgradePickupFlag = $4001C1
	endif

;Settings:
	!Setting_PlayerHP_OverworldDisplay		= 1
		;0 = Disable. (Prevents writing any display data to RAM relating to the overworld border
		;    plus (will entirely disable any overworld display)).
		;1 = Enable displaying HP on the overworld border (this uses the overworld border plus).

	!Setting_PlayerHP_DisplayNumericalLevel	= 2
		;^0 = display no numbers.
		; 1 = display only current HP.
		; 2 = display Current/Max.
	!Setting_PlayerHP_DisplayBarLevel = 1
		;^0 = don't display percentage bar
		; 1 = display a percentage bar

	!Setting_PlayerHP_DisplayNumericalOverworld	= 2
		;^Same as above, but for overworld

	!Setting_PlayerHP_DigitsAlignLevel		= 1
		;^How digits are displayed in levels.
		; 0 = allow leading spaces (digit place values are fixed)
		; 1 = left align (positions the character (numbers and "/") to the left as much
		;     as possible), no leading spaces before digits.
		; 2 = right align (to the right as possible). No leading spaces before digits.
		;
		;Notes:
		;-The number of digits extends the 8x8 area RIGHTWARDS, therefore setting
		; !Setting_PlayerHP_MaxDigits does not move the left part of the
		; character table.
		;-If you set the number display to only show current HP (and not max HP)
		; and have it set to right-aligned, this patch treats this as having it
		; set to 0 since numbers at fixed position are automatically right-aligned.

	!Setting_PlayerHP_DigitsAlignOverworld	= 1
		;^Same as above, but for overworld maps.
	;Position (units of tiles, not pixels). XY must be integers with X ranging from 0-31.
	;Y ranges depending on status bar type you using:
	; - For vanilla SMW: Y can only be 2-3. And...
	; -- When Y=2, X ranges 2-29.
	; -- When Y=3, X ranges 3-29.
	; - Super super status bar patch, Y ranges 0-4.
	; - For Minimalist status bar patches:
	; -- Top or Bottom: Y is always 0 as there is only a single row
	; -- For double, then Y is either 0 for top or 1 for bottom.
	; - For SMB3 status bar, Y is 0-3.
	;
	;Note that if tiles extend past the right edge of the screen, it will wrap to X=0 and Y+1 like text.
	
		;Position of the HP display string (which display the numbers). This is where:
		; - If not aligned or right-aligned (digits at fixed locations), it is where
		;   the leading zero/space would be at.
		; - If left-aligned, it is where the leftmost visible digit would be located
			!PlayerHP_StringPos_Lvl_x = 0
			!PlayerHP_StringPos_Lvl_y = 0
		;Same as above but for overworld border
			!PlayerHP_StringPos_Owb_x = 7
			!PlayerHP_StringPos_Owb_y = 1
			
	;Tile properties of the digits and slash (only used when !StatusBar_UsingCustomProperties == 1 in StatusBarDefines.asm)
		!PlayerHP_TileProp_Level_Text_Page = 0		;>Valid values: 0-3
		!PlayerHP_TileProp_Level_Text_Palette = 6	;>Valid values: 0-7
		
		!PlayerHP_TileProp_Ow_Text_Page = 0		;>Valid values: 0-3
		!PlayerHP_TileProp_Ow_Text_Palette = 6		;>Valid values: 0-7

	;small and Large HP settings:
		;Size of the player's HP:
		; - 0 = 8-bit HP (HP up to 255)
		; - 1 = 16-bit (HP up to 65535).
			!Setting_PlayerHP_TwoByte	= 1
		;The maximum number of digits to be displayed. Obviously you
		;wouldn't set this above 3 for 8-bit HP and above 5 or 16-bit.
			!Setting_PlayerHP_MaxDigits	= 3
	;Failsafe when the string of the HP text exceeds a certain number of characters
	; 0 = allow displaying digits despite exceeding how many digits can be displayed
	;     (recommended if you 100% sure it is completely impossible to have that much
	;     HP).
	; 1 = avoid using number display routines and simply display a line of "-"s to avoid
	;     glitches.
	;^This setting was present due to the fact that when too much digits are written, glitches
	; can happen:
	;-With aligned digits, random tiles appear in odd places on the status bar (or write in places
	; that isn't status bar data; corrupting other things).
	;-With fixed position digits, it simply displays incorrect values.
	;This works as an indicator to prevent such glitches.
		!Setting_PlayerHP_ExcessDigitProt	= 1

	;Bar animation stuff
		!Setting_PlayerHP_BarAnimation			= 1
			;^0 = HP bar instantly updates when the player heals or take damage
			;     (!Freeram_PlayerHP_BarRecord is no longer used).
			; 1 = HP bar displays a changing animation (transparent segment to
			;     indicate the amount of damage)

		!PlayerHP_BarFillUpSpeed				= $00
			;^Speed that the bar fills up. Only use these values:
			; $00,$01,$03,$07$,$0F,$1F,$3F or $7F. Lower values = faster

		!PlayerHP_BarFillUpSpeedPerFrame			= 0
			;^How many pieces in the bar filled per frame. This overrides
			; !PlayerHP_BarFillUpSpeed when 2+. Higher = faster filling animation.

		!PlayerHP_BarFillDrainSpeed				= $01
			;^Speed that the bar drains after damage. Only use these values:
			; $00,$01,$03,$07$,$0F,$1F,$3F or $7F. Lower values = faster

		!PlayerHP_BarFillEmptyingSpeedPerFrame		= 2
			;^How many pieces in the bar drained per frame. This overrides
			; !PlayerHP_BarFillDrainSpeed when 2+. Higher = faster draining
			; animation.

		!PlayerHP_BarRecordDelay				= 30
			;^How many frames the record effect (transparent effect) hangs
			; before shrinking down to current HP, up to 255 is allowed.
			; Set to 0 to disable (will also disable !Freeram_PlayerHP_BarRecordDelayTmr
			; from being used,). Remember, the game runs 60 FPS. This also applies
			; to healing should !Setting_PlayerHP_ShowHealedTransparent be enabled.

		!Setting_PlayerHP_ShowHealedTransparent		= 1
			;^0 = show sliding upwards animation
			; 1 = show amount healed as transparent segment.

		!Setting_PlayerHP_ShowDamageTransperent		= 1
			;^0 = show no transparent (if !Setting_PlayerHP_BarAnimation is
			;     enabled, would perform a sliding down animation as opaque)
			; 1 = show transparent.
			; This applies when the player takes damage.

	;HP recovery settings:
		;Midway point
			!Setting_playerHP_MidwayRecoveryType		= 1
				;^0 = Recover by a fixed amount.
				; 1 = recover by a fraction of max HP.

			!Setting_playerHP_MidwayRecoveryFixedAmt	= 5
				;^Fixed amount of HP to recover.

			!Setting_playerHP_MidwayRecoveryDividend	= 2
			!Setting_playerHP_MidwayRecoveryDivisor	= 5
				;^Recover HP by Dividend/Divisor of max HP (rounded
				; to nearest integer but not to zero).


		;Super Mushroom
			!Setting_PlayerHP_MushroomToItemBox		= 1
				;^0 = disable (mushroom does nothing but disappears).
				; 1 = Add mushroom to item box when full HP.
				;This option is useful if you disabled it item box.

			!Setting_playerHP_GrowFromSmallFailsafe	= 1
				;^0 = disable.
				; 1 = enable code that would turn small mario to super
				;     (if your hack expects to have small mario).

			!Setting_playerHP_MushroomRecoveryType	= 1
				;^0 = Recover by a fixed amount.
				; 1 = recover by a fraction of max HP.

			!Setting_playerHP_MushroomRecoveryFixedAmt	= 5
				;^Fixed amount of HP to recover.

			!Setting_playerHP_MushroomRecoveryDividend	= 2
			!Setting_playerHP_MushroomRecoveryDivisor 	= 5
				;^Recover HP by Dividend/Divisor of max HP (rounded
				; to nearest integer but not to zero).

	;Damage-related stuff
		!Setting_PlayerHP_LosePowerupOnDamage		= 1
			;^0 = don't lose powerup
			; 1 = lose powerup (becomes super mario).

		!Setting_PlayerHP_UsingCustomSprites		= 0
			;^0 = not using custom sprites
			; 1 = using custom sprites
			; If you're not using custom sprites in your hack, set this
			; to 0 because in some emulators, untouched RAM addresses 
			; have random values, and can cause glitches in the code that1
			; check if the sprite is custom.

		!Setting_PlayerHP_VaryingDamage = 1
			;^0 = always deal 1 HP damage from all hits.
			; 1 = deal varying damage.
			;
			;This only applies to all sprites damages (except the reflecting boo stream)
			;since this is table-focused. For other things like blocks, they're defined.
			;misc damage are located at the "Other" section.

	;Knockback stuff
		!Setting_PlayerHP_Knockback	= 2
			;^0 = no knockback
			; 1 = knockback (stun until timer runs out), regardless if the player is on
			;     the ground or not.
			; 2 = Same as above, but also cancels the stun when landing back on ground.
			; 3 = remain stunned (remains indefinitely) until touching the ground.

		!PlayerHP_KnockbackLength	= 30
			;^Number of frames the player is stunned after knocked. Regardless
			; if you set "!Setting_PlayerHP_Knockback" to 1 or 2, don't set this to 0.

		!PlayerHP_KnockbackHorizSpd		= $29
			;^How fast Mario gets flung horizontally after taking damage. Use values
			;$01-$7F only (Negative speeds already calculated).

		!PlayerHP_KnockbackUpwardsSpd	= $D7
			;^How fast Mario flies upward after taking damage. Use values $80-$FF only
			; ($80 is the fastest upwards speed).

		!PlayerHP_StunPose			= $24
			;^Pose to display when the player takes a knockback.
			; This is needed when the player is stunned on
			; the ground (see RAM $13E0 - https://smwc.me/m/smw/ram/7E13E0 ).

		!PlayerHP_InvulnerabilityTmr			= $7F
			;^How long the player remains invulnerable after taking
			; damage in frames (60 FPS). Remove the "$" to decimal
			; input. $7F was originally what SMW had.

		!PlayerHP_InvulnerabilityTmrCape		= $30
			;^Same as above, but when taking a hit while cape flying.
			; SMW originally had it at $30.

;Graphical bar stuff (these are arguments, which are specific values to set the bar's value).
;For modifying the scratch RAM used, see "GraphicalBarDef.asm".
	;Redefineable stuff (often preset settings, but some of them are intended for player HP only):
		!Default_MiddleLengthLevel           = 7             ;>30 = screen-wide (30 + 2 end tiles = 32, all 8x8 tile row in the screen's width)
		!Default_MiddleLengthOverworld       = 7             ;>Same as above but for overworld.
	;Level Position (same rule as before, units of tiles, must be at certain range)
		!PlayerHP_GraphicalBarPos_Lvl_x = 0
		!PlayerHP_GraphicalBarPos_Lvl_y = 1
	;Overworld position. Works similarly to the status bar, but the Y position "skips" the intermediate rows of tiles
	;between the top and bottom. This means that going downwards on the last row of "top lines" will immediately
	;end up being on "bottom lines" on the first row. For example, with !Top_Lines set to 5 rows (Y ranges from 0-4),
	;going from Y=4 to Y=5 would now be at the first row of the bottom lines (which the true Y position would be Y=26).
	;
	;You can convert TrueYPosition (this counts all rows of the layer 3, and must be 26-27) into EditableYPosition
	;(numbering only rows the OWB+ can edit) when using the bottom lines:
	;
	; EditableYPosition = TrueYPosition - 26 + !Top_Lines
	;
	;For example (having !Top_Lines set to 5), I want a counter on the top row of bottom lines. I can literally just do this:
	;
	;!YPos = 26-26+5, which is row 5 (rows 0-4 are top lines, 5-6 are bottom lines)
	;
	;Conversion is not needed if you are having your stuff on the top-lines.
		!PlayerHP_GraphicalBarPos_Owb_x = 7
		!PlayerHP_GraphicalBarPos_Owb_y = 2
	;Number of pieces in each part of the graphical bar
		!Default_LeftPieces                  = 3             ;\These will by default, set the RAM for the pieces for each section
		!Default_MiddlePieces                = 8             ;|(note that these apply for both levels and overworlds)
		!Default_RightPieces                 = 3             ;/


	;Don't touch, these are used for loops to write to the status bar.
		!GraphiBar_LeftTileExist = 0
		!GraphiBar_MiddleTileExistLevel = 0
		!GraphiBar_MiddleTileExistOverworld = 0
		!GraphiBar_RightTileExist = 0

		if !Default_LeftPieces != 0
			!GraphiBar_LeftTileExist = 1
		endif
		if and(notequal(!Default_MiddlePieces, 0), notequal(!Default_MiddleLengthLevel, 0))
			!GraphiBar_MiddleTileExistLevel = 1
		endif
		if and(notequal(!Default_MiddlePieces, 0), notequal(!Default_MiddleLengthOverworld, 0))
			!GraphiBar_MiddleTileExistOverworld = 1
		endif
		if !Default_RightPieces != 0
			!GraphiBar_RightTileExist = 1
		endif

	;Bar direction for level and overworld.
		!Setting_PlayerHP_LeftwardsBarLevel     = 0             ;>Have the bar fill leftwards. Note that end tiles are also mirrored.
		!Setting_PlayerHP_LeftwardsBarOverworld = 0             ;>Same as above but overworld.
	;Tile props
		!Setting_PlayerHP_BarProps_Lvl_Page = 0                 ;>Use only values 0-3
		!Setting_PlayerHP_BarProps_Lvl_Palette = 6              ;>Use only values 0-7

	;Display empty bar when there is very low HP but not zero:
		!Setting_PlayerHP_BarAvoidRoundToZero	= 1
			;^0 = allow bar to display 0% when HP is very close to zero
			; 1 = display 1 pixel or piece filled when low on HP and only 0 if HP is 0.

	;Other
		!Damage_PlayerHP_ReflectBooStream	= 3
			;^Due to only the boo stream itself (not the head) being the only
			; damageable minor extended sprite to the player, damage table for
			; minor extended sprites are not necessary.

		!Damage_PlayerHP_SmwBlocks		= 4
			;^Damage taken from Munchers and spikes (castle and ghost houses).
			; Note that this does not have a knockback due to all offsets of
			; the block shares the same code.

	!Setting_PlayerHP_OverworldRecovery	= 3
		;^Settings to restore some or all HP when
		; going to the overworld map.
		; 0 = Fully restore HP only after dying
		; 1 = Always fully restore HP anytime the player goes to the
		;     overworld in any shape or form (dying, start+select,
		;     completing the level, etc)
		; 2 = Set the player's HP to !Setting_PlayerHP_HPSetAfterDeath
		;     after dying.
		; 3 = Restore 1/2 HP (rounded to nearest integer) after dying.

	!Setting_PlayerHP_HPSetAfterDeath	= 1
		;^HP amount to set to after the player dies.

	!Setting_PlayerHP_GradualHPChange	= 1
		; 0 = disable.
		; 1 = enable status ailment involving HP draining
		;     or gradual healing (not to be confused with rolling HP).

	if !sa1 == 0
		!Ram_PickupBlockExistFlag = $7FC060
	else
		!Ram_PickupBlockExistFlag = $7FC060
	endif
		;^[1 byte] Not necessary freeram, but reuses a RAM that determines should
		; the block appear in the level. Currently, it uses LM's conditional map16
		;($7FC060 to $7FC06F).

;Don't touch these
	;(these are for aligning digits):
		!PlayerHP_NumberOfCharactersForMaxHPLevel = 0
		if !Setting_PlayerHP_DisplayNumericalLevel == 2
			!PlayerHP_NumberOfCharactersForMaxHPLevel = !Setting_PlayerHP_MaxDigits+1 ;>"/" and max HP digits
		endif
		!PlayerHP_NumericalMaxCharactersTotalLevel = !Setting_PlayerHP_MaxDigits+!PlayerHP_NumberOfCharactersForMaxHPLevel

		!PlayerHP_NumberOfCharactersForMaxHPOverworld = 0
		if !Setting_PlayerHP_DisplayNumericalOverworld == 2
			!PlayerHP_NumberOfCharactersForMaxHPOverworld = !Setting_PlayerHP_MaxDigits+1 ;>"/" and max HP digits
		endif
		!PlayerHP_NumericalMaxCharactersTotalOverworld = !Setting_PlayerHP_MaxDigits+!PlayerHP_NumberOfCharactersForMaxHPOverworld

	;this is to determine if a table is 8 or 16-bit HP
		!PlayerHPDataTableSize = "db"
		if !Setting_PlayerHP_TwoByte != 0
			!PlayerHPDataTableSize = "dw"
		endif
	;These calculate various user inputs into address or value
		;Calculate status bar position
			!PlayerHP_Digit_StatBarPos = VanillaStatusBarXYToAddress(!PlayerHP_StringPos_Lvl_x, !PlayerHP_StringPos_Lvl_y, !RAM_0EF9)
			!PlayerHP_Digit_OverworldBorderPos = PatchedStatusBarXYToAddress(!PlayerHP_StringPos_Owb_x, !PlayerHP_StringPos_Owb_y, !OverworldBorderPatchAddr_Tile, $02)
			!Setting_PlayerHP_BarPosOverworld = PatchedStatusBarXYToAddress(!PlayerHP_GraphicalBarPos_Owb_x, !PlayerHP_GraphicalBarPos_Owb_y, !OverworldBorderPatchAddr_Tile, $02)
			!Setting_PlayerHP_BarPosLevel = VanillaStatusBarXYToAddress(!PlayerHP_GraphicalBarPos_Lvl_x, !PlayerHP_GraphicalBarPos_Lvl_y, !RAM_0EF9)
			if !UsingCustomStatusBar != 0
				!PlayerHP_Digit_StatBarPos = PatchedStatusBarXYToAddress(!PlayerHP_StringPos_Lvl_x, !PlayerHP_StringPos_Lvl_y, !StatusBarPatchAddr_Tile, !StatusbarFormat)
				!PlayerHP_Digit_StatBarPosProp = PatchedStatusBarXYToAddress(!PlayerHP_StringPos_Lvl_x, !PlayerHP_StringPos_Lvl_y, !StatusBarPatchAddr_Prop, !StatusbarFormat)
				!Setting_PlayerHP_BarPosLevel = PatchedStatusBarXYToAddress(!PlayerHP_GraphicalBarPos_Lvl_x, !PlayerHP_GraphicalBarPos_Lvl_y, !StatusBarPatchAddr_Tile, !StatusbarFormat)
				!Setting_PlayerHP_BarPosLevelProp = PatchedStatusBarXYToAddress(!PlayerHP_GraphicalBarPos_Lvl_x, !PlayerHP_GraphicalBarPos_Lvl_y, !StatusBarPatchAddr_Prop, !StatusbarFormat)
			endif
		;Calculate tile properties
			!PlayerHP_TileProp_Level_Text = GetLayer3YXPCCCTT(0, 0, 1, !PlayerHP_TileProp_Level_Text_Palette, !PlayerHP_TileProp_Level_Text_Page)
			!PlayerHP_TileProp_Ow_Text = GetLayer3YXPCCCTT(0, 0, 1, !PlayerHP_TileProp_Ow_Text_Palette, !PlayerHP_TileProp_Ow_Text_Page)
			!PlayerHP_BarProps_Lvl = GetLayer3YXPCCCTT(0, 0, 1, !Setting_PlayerHP_BarProps_Lvl_Palette, !Setting_PlayerHP_BarProps_Lvl_Page)

	;Failsafe
		assert !Setting_playerHP_MidwayRecoveryDividend != 0, "Invalid Dividend"
		assert !Setting_playerHP_MidwayRecoveryDivisor > 1, "Invalid Divisor"
		assert !PlayerHP_KnockbackHorizSpd < $80, "Use only $01-$7F, negative values automatically calculated."


