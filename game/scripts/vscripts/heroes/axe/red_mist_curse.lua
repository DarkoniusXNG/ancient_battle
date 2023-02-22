axe_custom_red_mist_curse = class({})

LinkLuaModifier("modifier_red_mist_curse_debuff", "heroes/axe/red_mist_curse.lua", LUA_MODIFIER_MOTION_NONE)

function axe_custom_red_mist_curse:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function axe_custom_red_mist_curse:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function axe_custom_red_mist_curse:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
		return
	end

	-- Sound
	target:EmitSound("Hero_Axe.Battle_Hunger")

	-- KVs
	local duration = self:GetSpecialValueFor("duration")

	-- Apply debuff
	target:AddNewModifier(caster, self, "modifier_red_mist_curse_debuff", {duration = duration})
end

function axe_custom_red_mist_curse:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_red_mist_curse_debuff == nil then
	modifier_red_mist_curse_debuff = class({})
end

function modifier_red_mist_curse_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_red_mist_curse_debuff:IsDebuff()
	return true
end

function modifier_red_mist_curse_debuff:IsPurgable()
	return true
end

function modifier_red_mist_curse_debuff:OnCreated()
	self:OnRefresh()

	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(self.interval)
	end
end

function modifier_red_mist_curse_debuff:OnRefresh()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local movement_slow = 12
	self.dps = 25
	self.interval = 1

	if ability and not ability:IsNull() then
		movement_slow = ability:GetSpecialValueFor("move_speed_slow")
		self.dps = ability:GetSpecialValueFor("damage_per_second")
		self.interval = ability:GetSpecialValueFor("damage_interval")
	end

	if IsServer() then
		-- Slow is reduced with Status Resistance
		self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
	else
		self.slow = movement_slow
	end
end

function modifier_red_mist_curse_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()

	-- Don't apply damage if source or target don't exist
	if not parent or parent:IsNull() or not parent:IsAlive() or not caster or caster:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local damage_per_interval = self.dps * self.interval

	ApplyDamage({
		victim = parent,
		damage = damage_per_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		attacker = caster,
		ability = self:GetAbility()
	})
end

function modifier_red_mist_curse_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function modifier_red_mist_curse_debuff:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.slow)
end

function modifier_red_mist_curse_debuff:GetModifierProvidesFOWVision()
	return 1
end

function modifier_red_mist_curse_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_battle_hunger.vpcf"
end

function modifier_red_mist_curse_debuff:StatusEffectPriority()
	return 9
end

function modifier_red_mist_curse_debuff:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf"
end

function modifier_red_mist_curse_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
