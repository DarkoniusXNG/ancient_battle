sohei_palm_of_life = class({})

function sohei_palm_of_life:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if caster == target or target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function sohei_palm_of_life:GetCustomCastErrorTarget(target)
	if self:GetCaster() == target then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function sohei_palm_of_life:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:GetTeamNumber() == caster:GetTeamNumber()  then
		SuperStrongDispel(target, true, false)

		local base_heal = self:GetSpecialValueFor("base_heal")
		local scepter_heal = 0
		if caster:HasScepter() then
			scepter_heal = caster:GetMaxHealth() * self:GetSpecialValueFor("scepter_max_hp_as_heal") / 100
		end
		local total_heal = base_heal + scepter_heal

		target:Heal(total_heal, self)

		target:EmitSound("Sohei.PalmOfLife.Heal")

		local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl( part, 0, target:GetAbsOrigin() )
		ParticleManager:SetParticleControl( part, 1, Vector( target:GetModelRadius(), 1, 1 ) )
		ParticleManager:ReleaseParticleIndex( part )

		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, total_heal, nil)
	else
		-- Check for spell block and spell immunity (latter because of lotus)
		if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
			return
		end

		-- Basic Dispel (Buffs)
		local RemovePositiveBuffs = true
		local RemoveDebuffs = false
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false
		target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

		-- Sound
		target:EmitSound("Sohei.PalmOfLife.Damage")

		local base_damage = self:GetSpecialValueFor("base_damage")
		local caster_str = caster:GetStrength()
		local victim_str
		if target.GetStrength then
			victim_str = target:GetStrength()
		else
			victim_str = 0
		end
		local diff_multiplier = self:GetSpecialValueFor("str_diff_multiplier")
		if caster:HasScepter() then
			diff_multiplier = self:GetSpecialValueFor("scepter_str_diff_multiplier")
		end

		local str_diff_damage = math.max((caster_str - victim_str) * diff_multiplier, 0)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = self:GetAbilityDamageType()
		damage_table.ability = self
		damage_table.damage = base_damage + str_diff_damage
		damage_table.victim = target

		ApplyDamage(damage_table)
	end
end
