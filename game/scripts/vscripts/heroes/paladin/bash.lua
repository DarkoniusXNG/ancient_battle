if guardian_angel_bash == nil then
	guardian_angel_bash = class({})
end

LinkLuaModifier("modifier_custom_guardian_angel_bash", "heroes/paladin/bash.lua", LUA_MODIFIER_MOTION_NONE)

function guardian_angel_bash:IsStealable()
	return false
end

function guardian_angel_bash:GetIntrinsicModifierName()
	return "modifier_custom_guardian_angel_bash"
end

function guardian_angel_bash:ShouldUseResources()
	return false
end

-------------------------------------------------------------------------------
if modifier_custom_guardian_angel_bash == nil then
	modifier_custom_guardian_angel_bash = class({})
end

function modifier_custom_guardian_angel_bash:IsHidden()
	return true
end

function modifier_custom_guardian_angel_bash:IsDebuff()
	return false
end

function modifier_custom_guardian_angel_bash:IsPurgable()
	return false
end

function modifier_custom_guardian_angel_bash:RemoveOnDeath()
	return false
end

function modifier_custom_guardian_angel_bash:OnCreated(kv)
	local ability = self:GetAbility()

	self.chance = ability:GetSpecialValueFor("chance")
	self.duration = ability:GetSpecialValueFor("duration")
	self.duration_creep = ability:GetSpecialValueFor("duration_creep")
end

function modifier_custom_guardian_angel_bash:OnRefresh(kv)
	local ability = self:GetAbility()

	self.chance = ability:GetSpecialValueFor("chance")
	self.duration = ability:GetSpecialValueFor("duration")
	self.duration_creep = ability:GetSpecialValueFor("duration_creep")
end

function modifier_custom_guardian_angel_bash:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

if IsServer() then
  function modifier_custom_guardian_angel_bash:OnAttackLanded(event)
    local parent = self:GetParent()
	local ability = self:GetAbility()
	local target = event.target

	if parent ~= event.attacker then
		return
	end

    -- No bash while broken or illusion
	if parent:PassivesDisabled() or parent:IsIllusion() then
		return
	end

	-- To prevent crashes:
	if not target then
		return
	end

	if target:IsNull() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
		return
    end

	-- Don't affect buildings and wards
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
		return
	end

	local chance = ability:GetSpecialValueFor("chance") or self.chance

	if ability:PseudoRandom(chance) then
		local duration = ability:GetSpecialValueFor("duration") or self.duration

		-- Creeps have a different duration
		if not target:IsHero() then
			duration = ability:GetSpecialValueFor("duration_creep") or self.duration_creep
		end

		-- Apply built-in stun modifier
		target:AddNewModifier(parent, ability, "modifier_bashed", {duration = duration})

		-- Sound of Bash stun
		target:EmitSound("Hero_Slardar.Bash")
	end
  end
end

