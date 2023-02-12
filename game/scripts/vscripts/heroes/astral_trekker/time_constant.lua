astral_trekker_time_constant = class({})

LinkLuaModifier("modifier_time_constant", "heroes/astral_trekker/time_constant.lua", LUA_MODIFIER_MOTION_NONE)

function astral_trekker_time_constant:GetIntrinsicModifierName()
  return "modifier_time_constant"
end

function astral_trekker_time_constant:ProcsMagicStick()
  return false
end

function astral_trekker_time_constant:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_time_constant = class({})

function modifier_time_constant:IsHidden()
  return true
end

function modifier_time_constant:IsDebuff()
  return false
end

function modifier_time_constant:IsPurgable()
  return false
end

function modifier_time_constant:RemoveOnDeath()
  return false
end

function modifier_time_constant:OnCreated()
	if not IsServer() then
		return
	end

	self:StartIntervalThink(0)
end

function modifier_time_constant:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local ability = self:GetAbility()

	if not parent or parent:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	if parent:PassivesDisabled() then
		return
	end

	if not ability or ability:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	if not ability:IsCooldownReady() then
		return
	end

	local threshold_ms = ability:GetSpecialValueFor("ms_threshold")
	local threshold_as = ability:GetSpecialValueFor("as_threshold")

	local current_as = parent:GetAttackSpeed()*100 		-- Current attack speed
	local current_ms = parent:GetIdealSpeed()			-- Current movement speed

	-- Checking current speeds with speed thresholds
	if current_as < threshold_as or current_ms < threshold_ms then

		SuperStrongDispel(parent, true, false)

		-- Sound
		parent:EmitSound("Hero_Tidehunter.KrakenShell")

		-- Particle
		local particleName = "particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(particle)

		-- Go on the cooldown
		ability:UseResources(false, false, true)
	end
end
