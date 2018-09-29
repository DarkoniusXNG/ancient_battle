if modifier_custom_curse_of_the_silent == nil then
	modifier_custom_curse_of_the_silent = class({})
end

function modifier_custom_curse_of_the_silent:IsHidden()
	return false
end

function modifier_custom_curse_of_the_silent:IsPurgable()
	return true
end

function modifier_custom_curse_of_the_silent:IsDebuff()
	return true
end

function modifier_custom_curse_of_the_silent:DestroyOnExpire()
	return true
end

function modifier_custom_curse_of_the_silent:OnCreated()
	local parent = self:GetParent()
	self.ability = self:GetAbility()
	parent.spell_not_cast = true

	local tick_interval = self.ability:GetSpecialValueFor("tick_interval")
	self:StartIntervalThink(tick_interval)

	if IsServer() then
		local mana_loss_per_second = self.ability:GetSpecialValueFor("mana_loss_per_second")
		local tick_interval = self.ability:GetSpecialValueFor("tick_interval")
		local mana_loss_per_tick = mana_loss_per_second*tick_interval

		-- Reduce mana if the unit (parent) has mana
		if parent:GetMana() > 0 then
			parent:ReduceMana(mana_loss_per_tick)
		end
	end
end

function modifier_custom_curse_of_the_silent:OnRefresh()
	local parent = self:GetParent()
	self.ability = self:GetAbility()

	if parent.spell_not_cast == nil then
		parent.spell_not_cast = true
	end
end

function modifier_custom_curse_of_the_silent:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()
		local mana_loss_per_second = self.ability:GetSpecialValueFor("mana_loss_per_second")
		local tick_interval = self.ability:GetSpecialValueFor("tick_interval")
		local mana_loss_per_tick = mana_loss_per_second*tick_interval

		-- Reduce mana if the unit (parent) has mana
		if parent:GetMana() > 0 then
			parent:ReduceMana(mana_loss_per_tick)
		end
	end
end

function modifier_custom_curse_of_the_silent:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()

		-- Check if unit (parent) didn't cast a spell
		if parent.spell_not_cast then
			local ability = self:GetAbility() or self.ability
			local caster = self:GetCaster() or ability:GetCaster()
			local damage_type = ability:GetAbilityDamageType()
			local damage = ability:GetSpecialValueFor("damage_if_no_spell_casted")

			-- Particle on parent
			local particle = ParticleManager:CreateParticle("particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
			ParticleManager:ReleaseParticleIndex(particle)

			-- Sound on parent
			parent:EmitSound("Hero_Mirana.Starstorm.Impact")

			-- Damage
			local damage_table = {}
			damage_table.victim = parent
			damage_table.attacker = caster
			damage_table.damage = damage
			damage_table.ability = ability
			damage_table.damage_type = damage_type

			ApplyDamage(damage_table)
		end
	end
end

function modifier_custom_curse_of_the_silent:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_SPENT_MANA,
	}

	return funcs
end

function modifier_custom_curse_of_the_silent:OnSpentMana(event)
	local parent = self:GetParent()
	if IsServer() and event.unit == parent then
		local cast_ability = event.ability
		local cast_ability_behavior
		local forbidden_ability_behavior = bit.bor(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, DOTA_ABILITY_BEHAVIOR_AUTOCAST, DOTA_ABILITY_BEHAVIOR_ATTACK)

		-- If there isn't a cast ability, or if its mana cost was zero, do nothing
		if not cast_ability or cast_ability:GetManaCost(cast_ability:GetLevel() - 1) == 0 then
			return nil
		else
			cast_ability_behavior = cast_ability:GetBehavior()
		end

		-- If casted_ability is autocasted and an attack ability then do nothing
		if cast_ability_behavior == forbidden_ability_behavior then
			return nil
		end

		-- If casted_ability is an item then do nothing
		if cast_ability:IsItem() then
			return nil
		end

		-- Stop interval think
		self:StartIntervalThink(-1)

		-- Spell (with mana cost) was cast
		parent.spell_not_cast = false

		-- Setting duration is safer instead of removing the modifier
		self:SetDuration(0.1, false)
	end
end

function modifier_custom_curse_of_the_silent:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_curse.vpcf"
end

function modifier_custom_curse_of_the_silent:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
