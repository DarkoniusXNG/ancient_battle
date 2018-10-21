LinkLuaModifier("modifier_breath_fire_haze_burn", "<unknown>.lua", LUA_MODIFIER_MOTION_NONE)


--Spell Function

brewmaster_custom_breath_of_fire = class({})


function brewmaster_custom_breath_of_fire:OnSpellStart()
	self:GetCaster():EmitSound(Hero_DragonKnight.BreathFire)
end


function brewmaster_custom_breath_of_fire:OnProjectileHitUnit()
	local damageTable = 
	{
		victim = self:GetCursorTarget(),
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetSpecialValueFor("initial_damage"),
		damage_type = DAMAGE_TYPE_MAGICAL,
	}
	ApplyDamage(damageTable)
	HazeBurnStart(self)

end


--Old Functions

function HazeBurnStart(self)
    local caster = self:GetCaster()
    local ability = self
    local target = self.target
	
    if target:HasModifier("modifier_custom_drunken_haze_debuff") then
		target:AddNewModifier(caster, self, "modifier_breath_fire_haze_burn", {})
	end
end

function HazeBurnDamage(self)
	local caster = self:GetCaster()
	local ability = self
	local target = self.target
	
	local ability_level = ability:GetLevel() - 1
	local damage_per_second = ability:GetLevelSpecialValueFor("burn_damage_per_second", ability_level)
	local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)
    
	local damage_per_tick = damage_per_second*tick_interval
	
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
	
end



--Modifiers

modifier_breath_fire_haze_burn = class({})

function modifier_breath_fire_haze_burn:IsHidden()
	return false
end

function modifier_breath_fire_haze_burn:IsDebuff()
	return true
end

function modifier_breath_fire_haze_burn:IsPurgable()
	return true
end

function modifier_breath_fire_haze_burn:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf"
end

function modifier_breath_fire_haze_burn:OnCreated()
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("tick_interval"))
end

function modifier_breath_fire_haze_burn:OnIntervalThink()
	HazeBurnDamage(self:GetAbility())

end

