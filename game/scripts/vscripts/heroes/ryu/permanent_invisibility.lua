if stealth_assassin_permanent_invisibility == nil then
	stealth_assassin_permanent_invisibility = class({})
end

LinkLuaModifier("modifier_stealth_assassin_permanent_invisibility_buff", "heroes/ryu/permanent_invisibility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stealth_assassin_permanent_invisibility_disable", "heroes/ryu/permanent_invisibility.lua", LUA_MODIFIER_MOTION_NONE)

function stealth_assassin_permanent_invisibility:IsStealable()
	return false
end

function stealth_assassin_permanent_invisibility:GetIntrinsicModifierName()
	return "modifier_stealth_assassin_permanent_invisibility_buff"
end

function stealth_assassin_permanent_invisibility:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_stealth_assassin_permanent_invisibility_disable", {})
	else
		caster:RemoveModifierByNameAndCaster("modifier_stealth_assassin_permanent_invisibility_disable", caster)
		local passive = caster:FindModifierByNameAndCaster("modifier_stealth_assassin_permanent_invisibility_buff", caster)
		if passive then
			passive:OnRefresh()
		end
	end
end

function stealth_assassin_permanent_invisibility:ProcMagicStick()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_permanent_invisibility_buff = class({})

function modifier_stealth_assassin_permanent_invisibility_buff:IsHidden()
	return true
end

function modifier_stealth_assassin_permanent_invisibility_buff:IsDebuff()
	return false
end

function modifier_stealth_assassin_permanent_invisibility_buff:IsPurgable()
	return false
end

function modifier_stealth_assassin_permanent_invisibility_buff:RemoveOnDeath()
	return false
end

function modifier_stealth_assassin_permanent_invisibility_buff:AllowIllusionDuplicate()
	return true
end

function modifier_stealth_assassin_permanent_invisibility_buff:OnCreated()
	local ability = self:GetAbility()
	self.fade_time = ability:GetSpecialValueFor("fade_delay")
	self.move_speed = ability:GetSpecialValueFor("movement_speed")
	self.hp_regen = ability:GetSpecialValueFor("hp_regen")

	self:OnRefresh()
end

function modifier_stealth_assassin_permanent_invisibility_buff:OnRefresh()
	if IsServer() then
		local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:ReleaseParticleIndex(particle)

		self:SetStackCount(0)

		-- Start thinking
		self:StartIntervalThink(1)

		-- Start cooldown
		self:GetAbility():StartCooldown(self.fade_time)
	end
end

function modifier_stealth_assassin_permanent_invisibility_buff:OnIntervalThink()
	local count = self:GetStackCount()

	self:SetStackCount(count+1)

	if count >= self.fade_time then
		self:StartIntervalThink(-1)
	end
end

function modifier_stealth_assassin_permanent_invisibility_buff:IsCustomDisabled()
	local parent = self:GetParent()
	if parent:PassivesDisabled() or parent:IsSilenced() or parent:IsHexed() or parent:HasModifier("modifier_stealth_assassin_permanent_invisibility_disable") or self:GetStackCount() < self.fade_time then
		return true
	end
	return false
end

function modifier_stealth_assassin_permanent_invisibility_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_stealth_assassin_permanent_invisibility_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:IsCustomDisabled() then
		return 0
	end
	return self.move_speed
end

function modifier_stealth_assassin_permanent_invisibility_buff:GetModifierConstantHealthRegen()
	if self:IsCustomDisabled() then
		return 0
	end
	return self.hp_regen
end

function modifier_stealth_assassin_permanent_invisibility_buff:GetModifierInvisibilityLevel()
	return math.min(1, self:GetStackCount() / self.fade_time) -- using stack count only works for fade times that are above 1
end

if IsServer() then
	function modifier_stealth_assassin_permanent_invisibility_buff:OnTakeDamage()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local damaged_unit = event.unit
		local damage = event.damage

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end
		
		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- Check if damaged entity exists
		if not damaged_unit or damaged_unit:IsNull() then
			return
		end

		-- Don't continue if attacker is dead
		if not parent:IsAlive() then
			return
		end

		-- Don't continue if the damage is <= 0
		if damage <= 0 then
			return
		end

		if not ability or ability:IsNull() then
			return
		end

		-- Disable the buff if parent dealt damage somehow
		self:OnRefresh()
	end
end

function modifier_stealth_assassin_permanent_invisibility_buff:CheckState()
	local state = {}

	if not self:IsCustomDisabled() then
		state[MODIFIER_STATE_INVISIBLE] = true
	end

	return state
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_permanent_invisibility_disable = class({})

function modifier_stealth_assassin_permanent_invisibility_disable:IsHidden()
	return true
end

function modifier_stealth_assassin_permanent_invisibility_disable:IsDebuff()
	return true
end

function modifier_stealth_assassin_permanent_invisibility_disable:IsPurgable()
	return false
end
