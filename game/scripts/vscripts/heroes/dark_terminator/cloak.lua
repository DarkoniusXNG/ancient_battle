-- "OnSpellStart"
-- {
	-- "FireEffect"
	-- {
		-- "Target"			"CASTER"
		-- "EffectName"		"particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf"
		-- "EffectAttachType"	"attach_origin"
	-- }

	-- "FireSound"
	-- {
		-- "Target"			"CASTER"
		-- "EffectName"		"Hero_BountyHunter.WindWalk"
	-- }

	-- "ApplyModifier" // this modifier only applies transparency, not actual invisibility
	-- {
		-- "ModifierName" 		"modifier_invisible"
		-- "Target"			"CASTER"
		-- "Duration"			"%duration"
	-- }

	-- "ApplyModifier"
	-- {
		-- "ModifierName" 		"modifier_custom_wind_walk_buff"
		-- "Target"			"CASTER"
		-- "Duration"			"%duration"
	-- }
-- }

-- "Modifiers"
-- {
	-- "modifier_custom_wind_walk_buff" // needs tooltip
	-- {
		-- "IsHidden"			"0"
		-- "IsBuff"			"1"
		-- "IsPurgable"		"1"
		
		-- "Duration"          "%duration"
		
		-- "Properties"
		-- {
			-- "MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE"      "%bonus_move_speed"
		-- }
		
		-- "States"
		-- {
			-- "MODIFIER_STATE_INVISIBLE"			"MODIFIER_STATE_VALUE_ENABLED"
			-- "MODIFIER_STATE_NO_UNIT_COLLISION"	"MODIFIER_STATE_VALUE_ENABLED"
		-- }
		
		-- "OnAttackLanded"
		-- {
			-- "RemoveModifier"
			-- {
				-- "ModifierName" 	"modifier_custom_wind_walk_buff"
				-- "Target"		"CASTER"
			-- }

			-- "Damage"
			-- {
				-- "Target"
				-- {
					-- "Center"	"TARGET"
					-- "Flags"     "DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES"
				-- }
				-- "Type"			"DAMAGE_TYPE_PHYSICAL"
				-- "Damage"		"%bonus_damage"
			-- }

			-- "FireEffect"
			-- {
				-- "EffectName"		"particles/msg_fx/msg_crit.vpcf"
				-- "EffectAttachType"	"follow_overhead"
				-- "Target"
				-- {
					-- "Center"	"TARGET"
					-- "Flags"     "DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES"
				-- }
				-- "ControlPoints"
				-- {
					-- "01"		"9 %bonus_damage 4"		//pre number post
					-- "02"		"1 4 0"					//lifetime digits
					-- "03"		"255 0 0"				//color
				-- }
			-- }
		-- }

		-- "OnAbilityExecuted"
		-- {
			-- "RemoveModifier"
			-- {
				-- "ModifierName" 	"modifier_custom_wind_walk_buff"
				-- "Target"		"CASTER"
			-- }
		-- }
		
		-- "OnDestroy"
		-- {
			-- "RemoveModifier"
			-- {
				-- "ModifierName" 	"modifier_invisible"
				-- "Target"		"CASTER"
			-- }
		-- }
	-- }
-- }