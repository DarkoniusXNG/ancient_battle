LinkLuaModifier("modifier_soul_burn", "<unknown>.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_soul_buff", "<unknown>.lua", LUA_MODIFIER_MOTION_NONE)


--Spell Function

firelord_soul_burn = class({})


function firelord_soul_burn:OnSpellStart()
	self:GetCursorTarget():EmitSound(hero_bloodseeker.bloodRage)
	SoulBurnStart(self)

	unit:AddNewModifier(self:GetCaster(), self, "modifier_soul_buff", {Duration = self:GetAbility():GetSpecialValueFor("buff_duration"),})
end


--Old Functions

function SoulBurnStart(self)
	local target = self.target
	local caster = self:GetCaster()
	local ability = self
	local ability_level = ability:GetLevel() - 1
	
	local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)
	
	
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber() then
		if target:IsRealHero() then
			target:AddNewModifier(caster, self, "modifier_soul_burn", {["duration"] = hero_duration})
		else
			target:AddNewModifier(caster, self, "modifier_soul_burn", {["duration"] = creep_duration})
		end
	end
end



--Modifiers

modifier_soul_burn = class({})

function modifier_soul_burn:IsDebuff()
	return true
end

function modifier_soul_burn:IsPurgable()
	return true
end

function modifier_soul_burn:GetEffectName()
	return "particles/econ/items/axe/axe_cinder/axe_cinder_battle_hunger.vpcf"
end

function modifier_soul_burn:OnCreated()
	local damageTable = 
	{
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("damage_per_second"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	ApplyDamage(damageTable)
	self:StartIntervalThink(1.0)
end

function modifier_soul_burn:OnIntervalThink()
	local damageTable = 
	{
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("damage_per_second"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	ApplyDamage(damageTable)
end

function modifier_soul_burn:CheckState()
	local state = {
		[MODIFIER_STATE_SILENCED] = true,
	}
	return state
end

function modifier_soul_burn:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

function modifier_soul_burn:GetModifierDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

modifier_soul_buff = class({})

function modifier_soul_buff:IsPurgable()
	return true
end

function modifier_soul_buff:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf"
end

function modifier_soul_buff:OnCreated()
	local damageTable = 
	{
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("damage_per_second_ally"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	ApplyDamage(damageTable)
	self:StartIntervalThink(1.0)
end

function modifier_soul_buff:OnIntervalThink()
	local damageTable = 
	{
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("damage_per_second_ally"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	ApplyDamage(damageTable)
end

function modifier_soul_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

function modifier_soul_buff:GetModifierDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_amp")
end

