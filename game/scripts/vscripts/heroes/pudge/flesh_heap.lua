pudge_custom_flesh_heap = class({})

LinkLuaModifier("modifier_pudge_custom_flesh_heap_passive", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_flesh_heap_kill_tracker", "heroes/pudge/flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)

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

function pudge_custom_flesh_heap:IsStealable()
	return false
end

function pudge_custom_flesh_heap:ShouldUseResources()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_pudge_custom_flesh_heap_passive = class({})

function modifier_pudge_custom_flesh_heap_passive:IsHidden()
	return false
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

function modifier_pudge_custom_flesh_heap_passive:OnCreated(event)
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.magic_resist = ability:GetSpecialValueFor("magic_resistance")
		self.str_per_hero_kill = ability:GetSpecialValueFor("str_per_hero_kill")
	end

	if IsServer() then
		-- Find the kill tracker modifier
		local tracker = parent:FindModifierByName("modifier_pudge_custom_flesh_heap_kill_tracker")
		-- If tracker doesn't exist for some reason don't continue
		if not tracker then
			return
		end
		
		-- This is the actual strength Flesh Heap should give
		local strength = tracker:GetStackCount()

		-- Change stack count of this intrinsic modifier
		if self.str_per_hero_kill then
			if self.str_per_hero_kill ~= 0 then
				-- We are ''turning creep kills into hero kills'' -- this is not entirely accurate but whatever
				local new_stack_count = strength / self.str_per_hero_kill
				local old_stack_count = self:GetStackCount()
				if new_stack_count > old_stack_count then
					self:SetStackCount(new_stack_count)
				end
			end
		end

		parent:CalculateStatBonus(true)
	end
end

function modifier_pudge_custom_flesh_heap_passive:OnRefresh(event)
	self:OnCreated(event)
end

function modifier_pudge_custom_flesh_heap_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}

	return funcs
end

function modifier_pudge_custom_flesh_heap_passive:GetModifierMagicalResistanceBonus()
	if self.magic_resist then
		return self.magic_resist
	end

	return 0
end

function modifier_pudge_custom_flesh_heap_passive:GetModifierBonusStats_Strength()
	if self.str_per_hero_kill then
		return self:GetStackCount() * self.str_per_hero_kill
	end
	
	return self:GetStackCount()
end

---------------------------------------------------------------------------------------------------

modifier_pudge_custom_flesh_heap_kill_tracker = class({})

function modifier_pudge_custom_flesh_heap_kill_tracker:IsHidden()
	return not IsInToolsMode()
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

function modifier_pudge_custom_flesh_heap_kill_tracker:OnRefresh()
  self:OnCreated()
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

		-- Don't continue if the killer isn't the parent
		if killer ~= parent then
			return
		end

		-- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
		if dead.GetUnitName == nil then
			return
		end

		-- Don't trigger on Pudge deaths and denies
		if parent == dead then
			return
		end

		-- Don't continue if the ability doesn't exist
		local ability = self:GetAbility()
		if not ability or ability:IsNull() then
			return
		end

		-- Flesh Heap stacks don't increase when killing a buildings, wards or illusions
		if dead:IsTower() or dead:IsBarracks() or dead:IsBuilding() or dead:IsOther() or dead:IsIllusion() then
			return
		end

		if dead:IsRealHero() and not dead:IsClone() and not dead:IsTempestDouble() and not dead.original then
			self.hero_kills = self.hero_kills + 1

			local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_fleshheap_count.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
			ParticleManager:SetParticleControl(nFXIndex, 1, Vector(1, 0, 0))
			ParticleManager:ReleaseParticleIndex(nFXIndex)
		else
			self.creep_kills = self.creep_kills + 1
		end

		local str_per_hero_kill = ability:GetSpecialValueFor("str_per_hero_kill")
		local str_per_creep_kill = ability:GetSpecialValueFor("str_per_creep_kill")

		-- Calculate total strength and change stack count
		self:SetStackCount(math.floor(self.hero_kills * str_per_hero_kill + self.creep_kills * str_per_creep_kill))

		-- Refresh the intrinsic modifier if it exists
		local intrinsic = parent:FindModifierByName("modifier_pudge_custom_flesh_heap_passive")
		if intrinsic then
			intrinsic:ForceRefresh()
		end
	end
end