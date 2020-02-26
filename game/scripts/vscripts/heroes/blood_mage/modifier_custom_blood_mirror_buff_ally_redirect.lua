if modifier_custom_blood_mirror_buff_ally_redirect == nil then
	modifier_custom_blood_mirror_buff_ally_redirect = class({})
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsHidden()
	return false
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsDebuff()
	return false
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsPurgable()
	return true
end

function modifier_custom_blood_mirror_buff_ally_redirect:RemoveOnDeath()
	return true
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnCreated()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnRefresh()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
end

function modifier_custom_blood_mirror_buff_ally_redirect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}

	return funcs
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetModifierIncomingDamage_Percentage(kv)
	local redirect_target = self:GetCaster()
	local reduction = self.damage_redirect_percent
	local ability = self:GetAbility()

	if ability then
		reduction = ability:GetSpecialValueFor("redirected_damage")
		redirect_target = ability:GetCaster()
	end

	-- Checking if the redirect_target has a debuff (just in case)
	if redirect_target:IsAlive() and redirect_target:HasModifier("modifier_custom_blood_mirror_debuff_caster") then
		-- Apply damage reduction only if caster is alive and has a buff
		return -(reduction)
	else
		return 0
	end
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnTakeDamage(event)
    -- Only consider damage the parent receives
    if event.unit == self:GetParent() then
		local damage_table = {}
		local redirect_target = self:GetCaster()
		local redirected_damage = self.damage_redirect_percent
		local ability = self:GetAbility()

		if ability then
			redirected_damage = ability:GetSpecialValueFor("redirected_damage")
			redirect_target = ability:GetCaster()
			damage_table.ability = ability
		end

		damage_table.victim = redirect_target
		damage_table.attacker = event.attacker
		damage_table.damage = event.original_damage*(redirected_damage/100)
		damage_table.damage_type = event.damage_type -- DAMAGE_TYPE_PHYSICAL
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_REFLECTION)

        -- Redirect damage to caster if he is alive and if he has that buff
		if redirect_target:IsAlive() and redirect_target:HasModifier("modifier_custom_blood_mirror_debuff_caster") then
			ApplyDamage(damage_table)
		end
    end
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectName()
	return "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_ground_eztzhok.vpcf"
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
