;This define file contains settings for the "rolling HP" (non-instant damage, HP ticks upwards
;or downwards in real time until it stops) from the game Mother (japan) or Earthbound. All these
;freerams are not used should !Setting_PlayerHP_RollingHP set to 0. And yes, you can interrupt
;the decrementing HP by healing (and vice versa).
;
;Although this isn't the only patch that uses the rolling HP mechanic, it was used on Metroid HP
;Patch (but only 1HP increment or decrements per frame). Other methods to have the (actual) counter
;add/subtracted instantly but having merely the displayed value gradually counts up/down have a
;downside that when it hits a certain value, say 0 to die, the player can die before the displayed
;number hits zero, which can look weird. The Metroid HP and this patch would wait till the counter
;hits 0 before doing so.
;
;When using this system, there are some specialtie(s):
;-The transparent animation will continue hanging until all the remaining HP to increment or
; decrement are done, this allow showing the total amount of HP have been changed.

;Setting
	!Setting_PlayerHP_RollingHP	= 1
		;^0 = instant damage (normal)
		; 1 = rolling HP.
		;
		;Special notes when using rolling HP:
		;
		;-Obviously the HP to change freezes like all other things (so pausing, setting $9D, etc)
		; freezes to avoid weirdness with the timing of things.
		;
		;-If you hit the goal tape or head to the overworld map while your HP is counting down,
		; the amount of HP to be subtracted will be canceled, this is equivalent to winning a battle
		; while HP is draining. However if the player heals and goes to the overworld while the HP
		; is incrementing, it will be retained (to avoid unfair situations that the player must wait
		; till the HP stops counting).
		;
		;-The "damage" sound effect ALWAYS plays, even when the player dies when taking large damage.
		; this is because it is impossible to predict if the player is going to die or use a healing
		; item.


	!Setting_PlayerHP_MotherHPDelayRecoverLast	= 1
		;^Number of frames between each increment of HP when the player heals. I highly recommend
		; having this a low value (meaning have HP recover fast) to prevent player's frustration that
		; the player's recover can be interrupted easily.

;Freeram stuff
	if !sa1 == 0
		!Freeram_PlayerHP_MotherHPDirection	= $7FAD61
	else
		!Freeram_PlayerHP_MotherHPDirection	= $4001D1
	endif
		;^[1 byte] Direction to change HP:
		; 0 = damage (decrements HP when !Freeram_PlayerHP_MotherHPChanger is nonzero)
		; 1 = heal (increments HP when !Freeram_PlayerHP_MotherHPChanger is nonzero).
		;
		; Note that using this healing can also get canceled when taking damage when
		; HP is counting upwards, not just damage.

	if !sa1 == 0
		!Freeram_PlayerHP_MotherHPChanger	= $7FAD62
	else
		!Freeram_PlayerHP_MotherHPChanger	= $4001D2
	endif
		;^[BytesUsed = 1 + !Setting_PlayerHP_TwoByte] This is the amount of damage
		; or how much to recover 1HP every nth frames, as well as the remaining change
		; amount left to add or subtract HP. When set to nonzero value, on the frame
		; it change HP, this also subtract itself by 1 every 1HP of change to know when
		; to stop incrementing or decrementing HP.

	if !sa1 == 0
		!Freeram_PlayerHP_MotherHPDelayFrameTimer	= $7FAD64
	else
		!Freeram_PlayerHP_MotherHPDelayFrameTimer	= $4001D4
	endif
		;^[1 byte] Frame counter timer representing the number of frames left before 1HP
		; is decremented or incremented. When !Freeram_PlayerHP_MotherHPChanger is zero,
		; this is also zero so 1HP is subtracted instantly on damage. This also applies to
		; healing as well. After hitting zero and +/- 1HP, this number then resets back to
		; whatever value is in !Freeram_PlayerHP_MotherHPDelayDamageLast (for damage) or
		; to the value !Setting_PlayerHP_MotherHPDelayRecoverLast before +/- 1HP again.

	if !sa1 == 0
		!Freeram_PlayerHP_MotherHPDelayDamageLast	= $7FAD65
	else
		!Freeram_PlayerHP_MotherHPDelayDamageLast	= $4001D5
	endif
		;^[1 byte] How many frames between each loss of 1HP when damaged. This is stored
		; in RAM to enable in-game change of this number to enable different decrement
		; speeds. The higher this value, the slower the HP decrements.