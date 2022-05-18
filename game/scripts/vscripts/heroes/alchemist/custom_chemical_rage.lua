if alchemist_custom_chemical_rage == nil then
	alchemist_custom_chemical_rage = class({})
end

LinkLuaModifier("modifier_custom_chemical_rage_buff", "heroes/alchemist/modifier_custom_chemical_rage_buff.lua", LUA_MODIFIER_MOTION_NONE)

function alchemist_custom_chemical_rage:GetBehavior()
  local caster = self:GetCaster()
  -- Talent that allows casting while stunned
  local talent = caster:FindAbilityByName("special_bonus_unique_alchemist_custom_2")
  if talent and talent:GetLevel() > 0 then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
  end

  return self.BaseClass.GetBehavior(self)
end

function alchemist_custom_chemical_rage:OnSpellStart()
	local caster = self:GetCaster()

	-- Talent that applies Strong Dispel
	local talent = caster:FindAbilityByName("special_bonus_unique_alchemist_custom_2")
	if talent and talent:GetLevel() > 0 then
		-- Apply Super Strong Dispel
		SuperStrongDispel(caster, true, false)
	else
		-- Apply Basic Dispel
		caster:Purge(false, true, false, false, false)
	end

	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)
	
	-- Sound
	caster:EmitSound("Hero_Alchemist.ChemicalRage.Cast")

	-- Applying the built-in modifier that controls the animations, sounds and body transformation.
	-- The modifier_alchemist_chemical_rage tooltip needs to be adjusted
	local transform_duration = self:GetSpecialValueFor("transformation_time")
	caster:AddNewModifier(caster, self, "modifier_alchemist_chemical_rage_transform", {duration = transform_duration})

	-- Apply the real buff
	local buff_duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_custom_chemical_rage_buff", {duration = buff_duration})
end

function alchemist_custom_chemical_rage:ProcsMagicStick()
	return true
end
