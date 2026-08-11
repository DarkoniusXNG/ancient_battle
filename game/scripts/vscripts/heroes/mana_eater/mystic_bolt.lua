-- Called OnSpellStart
function MysticBoltSpendMana(event)
	local caster = event.caster
	local ability = event.ability

	-- Storing current mana into a local variable
	local current_caster_mana = caster:GetMana()

	-- If the table is nil or empty, create a new one with same name and insert one element into it
	if caster.mana_spent_at_cast_time == nil or next(caster.mana_spent_at_cast_time) == nil then
		-- Create or reset the table
		caster.mana_spent_at_cast_time = {}
		-- Create or reset the counter
		caster.mystic_bolt_counter = 1
		-- Store the current mana at the moment of cast in the table
		caster.mana_spent_at_cast_time[1] = current_caster_mana
	else
		-- Increment the counter
		caster.mystic_bolt_counter = caster.mystic_bolt_counter + 1
		-- Store the current mana at the moment of cast in the table
		caster.mana_spent_at_cast_time[caster.mystic_bolt_counter] = current_caster_mana
	end

	-- Spending current mana
	caster:SpendMana(current_caster_mana, ability)
end

-- Called OnProjectileHitUnit
function MysticBoltHit(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Find correct mana_at_that_time
	local mana_at_that_time = 0
	for i, mana in pairs(caster.mana_spent_at_cast_time) do
		if mana then
			mana_at_that_time = mana
			caster.mana_spent_at_cast_time[i] = nil
			break
		end
	end

	-- Check for spell block and spell immunity (latter because of lotus)
	if not target:TriggerSpellAbsorb(ability) and not target:IsMagicImmune() then
		local ability_level = ability:GetLevel() - 1
		local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
		local damage_per_mana = ability:GetLevelSpecialValueFor("damage_per_mana", ability_level)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
		damage_table.victim = target
		damage_table.damage = base_damage + mana_at_that_time*damage_per_mana

		if target:HasModifier("modifier_anti_magic_field_buff") then
			damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
			damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
		end

		-- Applying the damage
		ApplyDamage(damage_table)
	end

	-- Stop Sounds
	StopSoundOn("Hero_SkywrathMage.ArcaneBolt.Cast", caster)
	StopSoundOn("Hero_SkywrathMage.ArcaneBolt.Impact", target)
end
