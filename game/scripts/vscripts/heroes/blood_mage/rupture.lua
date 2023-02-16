blood_mage_rupture = class({})

LinkLuaModifier("modifier_custom_rupture", "heroes/blood_mage/rupture.lua", LUA_MODIFIER_MOTION_NONE)

function blood_mage_rupture:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function blood_mage_rupture:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function blood_mage_rupture:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not caster or not target then
		return
	end

	-- Sound
	caster:EmitSound("Hero_Bloodseeker.Rupture.Cast")

	-- Check for spell block; pierces spell immunity
	if not target:TriggerSpellAbsorb(self) then
		local rupture_duration = self:GetSpecialValueFor("duration")
		target:AddNewModifier(caster, self, "modifier_custom_rupture", {duration = rupture_duration})

		target:EmitSound("Hero_Bloodseeker.Rupture")
		target:EmitSound("Hero_Bloodseeker.Rupture_FP")
	end
end

function blood_mage_rupture:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_custom_rupture = class({})

function modifier_custom_rupture:IsHidden()
	return true
end

function modifier_custom_rupture:IsDebuff()
	return true
end

function modifier_custom_rupture:IsPurgable()
	return false
end

function modifier_custom_rupture:RemoveOnDeath()
	return true
end

function modifier_custom_rupture:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	local interval = 0.25
	local current_hp_pct = 15
	self.damage_per_movement = 30
	self.distance_cap_amount = 1500
	self.damage_type = DAMAGE_TYPE_PURE

	if ability and not ability:IsNull() then
		interval = ability:GetSpecialValueFor("damage_cap_interval")
		current_hp_pct = ability:GetSpecialValueFor("initial_damage_pct")
		self.damage_per_movement = ability:GetSpecialValueFor("movement_damage_pct")
		self.distance_cap_amount = ability:GetSpecialValueFor("distance_cap_amount")
		self.damage_type = ability:GetAbilityDamageType()
	end

	local damage_table = {}
	damage_table.victim = parent
	damage_table.attacker = caster
	damage_table.ability = ability
	damage_table.damage = parent:GetHealth() * current_hp_pct * 0.01
	damage_table.damage_type = self.damage_type
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL

	ApplyDamage(damage_table)

	-- Store target's current location
	self.last_position_rupture = parent:GetAbsOrigin()

	-- Start checking distance travelled
	self:StartIntervalThink(interval)
end

-- Checks the parent's distance from its last position and deals damage accordingly
function modifier_custom_rupture:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent()

	if not parent or parent:IsNull() or not parent:IsAlive() or not caster or caster:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local damage_per_movement = self.damage_per_movement
	local distance_cap_amount = self.distance_cap_amount
	local damage = 0

	if self.last_position_rupture then
		local distance = (self.last_position_rupture - parent:GetAbsOrigin()):Length2D()

		if distance <= distance_cap_amount and distance > 0 then
			damage = distance * damage_per_movement * 0.01
		end

		if damage > 0 then
			local damage_table = {}
			damage_table.victim = parent
			damage_table.attacker = caster
			damage_table.ability = self:GetAbility()
			damage_table.damage = damage
			damage_table.damage_type = self.damage_type

			ApplyDamage(damage_table)
		end
	end
	if parent and not parent:IsNull() and parent:IsAlive() then
		self.last_position_rupture = parent:GetAbsOrigin()
	end
end

function modifier_custom_rupture:OnDestroy()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	parent:StopSound("Hero_Bloodseeker.Rupture_FP")
end

function modifier_custom_rupture:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

function modifier_custom_rupture:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
