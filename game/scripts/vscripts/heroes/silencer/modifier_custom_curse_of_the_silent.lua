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

function modifier_custom_curse_of_the_silent:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_custom_curse_of_the_silent:OnCreated()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	parent.spell_not_cast = true
	self.ability = ability

	local think_interval = ability:GetSpecialValueFor("tick_interval")

	self:StartIntervalThink(think_interval)
	self:OnIntervalThink()
end

function modifier_custom_curse_of_the_silent:OnIntervalThink()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		ability = self.ability
	end
	local mana_loss_per_second = ability:GetSpecialValueFor("mana_loss_per_second")
	local think_interval = ability:GetSpecialValueFor("tick_interval")
	local mana_loss_per_interval = mana_loss_per_second*think_interval

	-- Reduce mana if the unit (parent) has mana
	if parent:GetMana() > 0 then
		parent:ReduceMana(mana_loss_per_interval)
	end
end

function modifier_custom_curse_of_the_silent:OnDestroy()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	if not parent or parent:IsNull() then
		return
	end
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		ability = self.ability
	end

	-- Check if unit (parent) didn't cast a spell
	if parent.spell_not_cast then
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

function modifier_custom_curse_of_the_silent:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_SPENT_MANA,
	}
end

if IsServer() then
	function modifier_custom_curse_of_the_silent:OnSpentMana(event)
		local parent = self:GetParent()
		local cast_ability = event.ability

		-- Check if unit that spent mana has this modifier
		if event.unit ~= parent then
			return
		end

		local cast_ability_behavior
		-- If there isn't a cast ability, or if its mana cost was zero, do nothing
		if not cast_ability or cast_ability:GetManaCost(cast_ability:GetLevel() - 1) == 0 then
			return
		else
			cast_ability_behavior = cast_ability:GetBehavior()
			if type(cast_ability_behavior) == 'userdata' then
				cast_ability_behavior = tonumber(tostring(cast_ability_behavior))
			end
		end

		-- If cast ability is an attack ability (orb effect) then do nothing
		if HasBit(cast_ability_behavior, DOTA_ABILITY_BEHAVIOR_ATTACK) then
			return
		end

		-- If casted_ability is an item then do nothing
		if cast_ability:IsItem() then
			return
		end

		-- Stop interval think
		self:StartIntervalThink(-1)

		-- Spell (with mana cost) was cast
		parent.spell_not_cast = false

		-- Setting remaining duration is safer instead of removing the modifier
		self:SetDuration(0.1, false)
	end
end

function modifier_custom_curse_of_the_silent:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_curse.vpcf"
end

function modifier_custom_curse_of_the_silent:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
