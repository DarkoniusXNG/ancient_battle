if modifier_custom_blood_mirror_buff_caster_redirect == nil then
	modifier_custom_blood_mirror_buff_caster_redirect = class({})
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsHidden()
	return true
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsDebuff()
	return false
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsPurgable()
	return false
end

function modifier_custom_blood_mirror_buff_caster_redirect:RemoveOnDeath()
	return true
end

function modifier_custom_blood_mirror_buff_caster_redirect:OnCreated()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
end

function modifier_custom_blood_mirror_buff_caster_redirect:OnRefresh()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
end

function modifier_custom_blood_mirror_buff_caster_redirect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}

	return funcs
end

function modifier_custom_blood_mirror_buff_caster_redirect:GetModifierIncomingDamage_Percentage(kv)
	local parent = self:GetParent()
	local redirect_target = parent.redirect_target -- nil on the client
	local reduction = self.damage_redirect_percent
	local ability = self:GetAbility()

	if ability then
		reduction = ability:GetSpecialValueFor("redirected_damage")
	end

	if not redirect_target then
		return 0
	end

	if redirect_target:IsNull() then
		return 0
	end

	-- Checking if the redirect_target has a debuff because it can be dispelled
	if redirect_target:IsAlive() and redirect_target:HasModifier("modifier_custom_blood_mirror_debuff_enemy") then
		-- Apply damage reduction
		return -(reduction)
	else
		return 0
	end
end

function modifier_custom_blood_mirror_buff_caster_redirect:OnTakeDamage(event)
    local parent = self:GetParent()
	-- Only consider damage the parent receives
    if event.unit == parent then
		local damage_table = {}
		local redirect_target = parent.redirect_target -- nil on the client
		local redirected_damage = self.damage_redirect_percent
		local ability = self:GetAbility()

		if ability then
			redirected_damage = ability:GetSpecialValueFor("redirected_damage")
			damage_table.ability = ability
		end

		damage_table.victim = redirect_target
		damage_table.attacker = event.attacker
		damage_table.damage = event.original_damage*(redirected_damage/100)
		damage_table.damage_type = event.damage_type -- DAMAGE_TYPE_PHYSICAL
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_REFLECTION)

		if not redirect_target then
			return nil
		end

		if redirect_target:IsNull() then
			return nil
		end

        -- Redirect damage to caster if he is alive and if he has that buff
		if redirect_target:IsAlive() and redirect_target:HasModifier("modifier_custom_blood_mirror_debuff_enemy") then
			ApplyDamage(damage_table)
		end
    end
end
