pudge_custom_flesh_heap = class({})

LinkLuaModifier("modifier_pudge_custom_flesh_heap_passive", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_flesh_heap_kill_tracker", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_flesh_heap_heroes", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_flesh_heap_creeps", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)

function pudge_custom_flesh_heap:Spawn()
	if IsServer() then
		local caster = self:GetCaster()
		-- Add kill tracker modifier
		caster:AddNewModifier(caster, self, "modifier_pudge_custom_flesh_heap_kill_tracker", {})
	end
end

function pudge_custom_flesh_heap:GetIntrinsicModifierName()
	return "modifier_pudge_custom_flesh_heap_passive"
end

-- Refresh ability values on ability level up
function pudge_custom_flesh_heap:OnUpgrade()
	local caster = self:GetCaster()
	local mod_heroes = caster:FindModifierByName("modifier_pudge_custom_flesh_heap_heroes")
	local mod_creeps = caster:FindModifierByName("modifier_pudge_custom_flesh_heap_creeps")
	if mod_heroes then
		mod_heroes:OnIntervalThink()
	end
	if mod_creeps then
		mod_creeps:OnIntervalThink()
	end
end

function pudge_custom_flesh_heap:IsStealable()
	return false
end

function pudge_custom_flesh_heap:ShouldUseResources()
	return false
end

---------------------------------------------------------------------------------------------------
-- Only magic resistance
modifier_pudge_custom_flesh_heap_passive = class({})

function modifier_pudge_custom_flesh_heap_passive:IsHidden()
	return true
end

function modifier_pudge_custom_flesh_heap_passive:IsPurgable()
	return false
end

function modifier_pudge_custom_flesh_heap_passive:IsDebuff()
	return false
end

function modifier_pudge_custom_flesh_heap_passive:RemoveOnDeath()
	return false
end

function modifier_pudge_custom_flesh_heap_passive:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.magic_resist = ability:GetSpecialValueFor("magic_resistance")
	end

	if IsServer() then
		parent:CalculateStatBonus(true)
	end
end

function modifier_pudge_custom_flesh_heap_passive:OnRefresh()
	self:OnCreated()
end

function modifier_pudge_custom_flesh_heap_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_pudge_custom_flesh_heap_passive:GetModifierMagicalResistanceBonus()
	if self.magic_resist then
		return self.magic_resist
	end

	return 0
end

---------------------------------------------------------------------------------------------------
-- Only tracks kills
modifier_pudge_custom_flesh_heap_kill_tracker = class({})

function modifier_pudge_custom_flesh_heap_kill_tracker:IsHidden()
	return true
end

function modifier_pudge_custom_flesh_heap_kill_tracker:IsPurgable()
	return false
end

function modifier_pudge_custom_flesh_heap_kill_tracker:IsDebuff()
	return false
end

function modifier_pudge_custom_flesh_heap_kill_tracker:RemoveOnDeath()
	return false
end

function modifier_pudge_custom_flesh_heap_kill_tracker:OnCreated()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  if not self.hero_kills then
    self.hero_kills = 0
  end

  if not self.creep_kills then
    self.creep_kills = 0
  end
end

function modifier_pudge_custom_flesh_heap_kill_tracker:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
	function modifier_pudge_custom_flesh_heap_kill_tracker:OnDeath(event)
		local parent = self:GetParent()
		local killer = event.attacker
		local dead = event.unit

		-- Flesh Heap doesn't work on illusions of Pudge or when Pudge is dead
		if parent:IsIllusion() or not parent:IsAlive() then
			return
		end

		-- Don't continue if the killer doesn't exist
		if not killer or killer:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
		if dead.GetUnitName == nil then
			return
		end

		-- Don't trigger on Pudge deaths and allied deaths
		if parent == dead or dead:GetTeamNumber() == parent:GetTeamNumber() then
			return
		end

		-- Flesh Heap stacks don't increase when killing a buildings, wards or illusions
		if dead:IsTower() or dead:IsBarracks() or dead:IsBuilding() or dead:IsOther() or dead:IsIllusion() then
			return
		end

		local parent_loc = parent:GetAbsOrigin()
		local dead_loc = dead:GetAbsOrigin()
		local parentToDeadVector = dead_loc - parent_loc
		local ability = self:GetAbility()
		local flesh_heap_range = ability:GetSpecialValueFor("range")
		if flesh_heap_range == 0 then
			flesh_heap_range = 250
		end
		local isDeadInRange = parentToDeadVector:Length2D() <= flesh_heap_range

		if isDeadInRange or killer == parent then
			if dead:IsRealHero() and not dead:IsClone() and not dead:IsTempestDouble() and not dead.original then
				self.hero_kills = self.hero_kills + 1

				local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_fleshheap_count.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
				ParticleManager:SetParticleControl(nFXIndex, 1, Vector(1, 0, 0))
				ParticleManager:ReleaseParticleIndex(nFXIndex)
			else
				self.creep_kills = self.creep_kills + 1
			end

			if not parent:HasModifier("modifier_pudge_custom_flesh_heap_heroes") then
				parent:AddNewModifier(parent, ability, "modifier_pudge_custom_flesh_heap_heroes", {})
			end
			if not parent:HasModifier("modifier_pudge_custom_flesh_heap_creeps") then
				parent:AddNewModifier(parent, ability, "modifier_pudge_custom_flesh_heap_creeps", {})
			end

			local mod_heroes = parent:FindModifierByName("modifier_pudge_custom_flesh_heap_heroes")
			local mod_creeps = parent:FindModifierByName("modifier_pudge_custom_flesh_heap_creeps")
			
			mod_heroes:SetStackCount(self.hero_kills)
			mod_creeps:SetStackCount(self.creep_kills)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Only gives str from hero kills
modifier_pudge_custom_flesh_heap_heroes = class({})

function modifier_pudge_custom_flesh_heap_heroes:IsHidden()
	local parent = self:GetParent()
	local ability = parent:FindAbilityByName("pudge_custom_flesh_heap")
	if ability and ability:GetLevel() > 0 then
		return false
	end
	return true
end

function modifier_pudge_custom_flesh_heap_heroes:IsPurgable()
	return false
end

function modifier_pudge_custom_flesh_heap_heroes:IsDebuff()
	return false
end

function modifier_pudge_custom_flesh_heap_heroes:RemoveOnDeath()
	return false
end

function modifier_pudge_custom_flesh_heap_heroes:OnCreated()
	--local parent = self:GetParent()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		self:StartIntervalThink(0)
	elseif ability:GetLevel() > 0 then
		self.str_per_hero_kill = ability:GetSpecialValueFor("str_per_hero_kill")
	end
end

function modifier_pudge_custom_flesh_heap_heroes:OnIntervalThink()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		ability = parent:FindAbilityByName("pudge_custom_flesh_heap")
		if ability and ability:GetLevel() > 0 then
			self.str_per_hero_kill = ability:GetSpecialValueFor("str_per_hero_kill")
			self:StartIntervalThink(-1)
		end
	elseif ability:GetLevel() > 0 then
		self.str_per_hero_kill = ability:GetSpecialValueFor("str_per_hero_kill")
		self:StartIntervalThink(-1)
	end
end

function modifier_pudge_custom_flesh_heap_heroes:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_pudge_custom_flesh_heap_heroes:GetModifierBonusStats_Strength()
	if self.str_per_hero_kill then
		return self:GetStackCount() * self.str_per_hero_kill
	end

	return 0
end

function modifier_pudge_custom_flesh_heap_heroes:GetTexture()
	return "pudge_flesh_heap"
end

---------------------------------------------------------------------------------------------------
-- Only gives str from creep kills
modifier_pudge_custom_flesh_heap_creeps = class({})

function modifier_pudge_custom_flesh_heap_creeps:IsHidden()
	local parent = self:GetParent()
	local ability = parent:FindAbilityByName("pudge_custom_flesh_heap")
	if ability and ability:GetLevel() > 0 then
		return false
	end
	return true
end

function modifier_pudge_custom_flesh_heap_creeps:IsPurgable()
	return false
end

function modifier_pudge_custom_flesh_heap_creeps:IsDebuff()
	return false
end

function modifier_pudge_custom_flesh_heap_creeps:RemoveOnDeath()
	return false
end

function modifier_pudge_custom_flesh_heap_creeps:OnCreated()
	--local parent = self:GetParent()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		self:StartIntervalThink(0)
	elseif ability:GetLevel() > 0 then
		self.str_per_creep_kill = ability:GetSpecialValueFor("str_per_creep_kill")
	end
end

function modifier_pudge_custom_flesh_heap_creeps:OnIntervalThink()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		ability = parent:FindAbilityByName("pudge_custom_flesh_heap")
		if ability and ability:GetLevel() > 0 then
			self.str_per_creep_kill = ability:GetSpecialValueFor("str_per_creep_kill")
			self:StartIntervalThink(-1)
		end
	elseif ability:GetLevel() > 0 then
		self.str_per_creep_kill = ability:GetSpecialValueFor("str_per_creep_kill")
		self:StartIntervalThink(-1)
	end
end

function modifier_pudge_custom_flesh_heap_creeps:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_pudge_custom_flesh_heap_creeps:GetModifierBonusStats_Strength()
	if self.str_per_creep_kill then
		return self:GetStackCount() * self.str_per_creep_kill
	end

	return 0
end

function modifier_pudge_custom_flesh_heap_creeps:GetTexture()
	return "pudge_flesh_heap"
end
