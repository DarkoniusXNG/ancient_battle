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
	self.redirect_target = self:GetCaster()
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnRefresh()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
	self.redirect_target = self:GetCaster()
end

function modifier_custom_blood_mirror_buff_ally_redirect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}

	return funcs
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetModifierIncomingDamage_Percentage(kv)
	if IsServer() then
		local attacker = kv.attacker
		local redirect_target = self.redirect_target
		local reduction = self.damage_redirect_percent
		local damage_table = {}
		local ability = self:GetAbility()

		if ability then
			local ability_level	= ability:GetLevel()
			redirect_target = self:GetCaster()
			reduction = ability:GetLevelSpecialValueFor("redirected_damage", ability_level)
			--damage_table.ability = ability
		end

		local damage_after_reductions = kv.damage
		local damage_to_redirect = damage_after_reductions*reduction/100

		damage_table.victim = redirect_target
		damage_table.attacker = attacker
		damage_table.damage = damage_to_redirect
		damage_table.damage_type = kv.damage_type
		damage_table.damage_flags = bit.bor(kv.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)
		damage_table.ability = kv.inflictor

		-- Checking if the redirect_target has a debuff (just in case)
		if redirect_target:IsAlive() and redirect_target:HasModifier("modifier_custom_blood_mirror_debuff_caster") and damage_to_redirect > 0 then
			--Apply the damage to the caster
			ApplyDamage(damage_table)

			-- Apply damage reduction
			return -(reduction)
		end

		return 0
	end
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectName()
	return "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_ground_eztzhok.vpcf"
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
