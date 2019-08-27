if perun_electric_shield == nil then
	perun_electric_shield = class({})
end

LinkLuaModifier("modifier_perun_electric_shield", "heroes/perun/electric_shield.lua", LUA_MODIFIER_MOTION_NONE) --LUA_MODIFIER_MOTION_HORIZONTAL

function perun_electric_shield:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function perun_electric_shield:OnSpellStart()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- Sound
	target:EmitSound("Hero_Dark_Seer.Ion_Shield_Start")

	-- Apply Modifier (no linkens block)
	target:AddNewModifier(caster, self, "modifier_perun_electric_shield", {duration = self:GetSpecialValueFor("duration")})
end

function perun_electric_shield:ProcsMagicStick()
	return true
end

if modifier_perun_electric_shield == nil then
	modifier_perun_electric_shield = class({})
end

function modifier_perun_electric_shield:IsHidden()
	return false
end

function modifier_perun_electric_shield:IsPurgable()
	return true
end

function modifier_perun_electric_shield:IsDebuff()
	if self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
		return true
	else
		return false
	end
end

function modifier_perun_electric_shield:OnCreated()
	local ability = self:GetAbility()
	local parent = self:GetParent()

	self.radius = ability:GetSpecialValueFor("radius")
	self.damage_per_second = ability:GetSpecialValueFor("damage_per_second")
	self.interval = ability:GetSpecialValueFor("damage_interval")

	if not IsServer() then
		return
	end

	-- Start loop sound
	parent:EmitSound("Hero_Dark_Seer.Ion_Shield_lp")

	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_ion_shell.vpcf", PATTACH_POINT_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.particle, 1, Vector(50, 50, 50)) -- Arbitrary
	self:AddParticle(self.particle, false, false, -1, false, false) -- Maybe not needed

	self:StartIntervalThink(self.interval)
end

function modifier_perun_electric_shield:OnRefresh()
	local ability = self:GetAbility()
	self.radius = ability:GetSpecialValueFor("radius")
	self.damage_per_second = ability:GetSpecialValueFor("damage_per_second")
end

function modifier_perun_electric_shield:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	if not caster or not parent then
		return
	end

	local radius = self.radius
	if ability then
		radius = ability:GetSpecialValueFor("radius")
	end
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), parent:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs (enemies) do
		if enemy and enemy ~= parent then
			-- Damage particle
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_ion_shell_damage.vpcf", PATTACH_POINT, parent)
			ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)

			-- Update damage values here if needed
			local damage_per_second = self.damage_per_second
			local damage_interval = self.interval
			local damage_type = DAMAGE_TYPE_MAGICAL
			if ability then
				damage_per_second = ability:GetSpecialValueFor("damage_per_second")
				damage_interval = ability:GetSpecialValueFor("damage_interval")
				damage_type = ability:GetAbilityDamageType()
			end

			local damage_table = {}
			damage_table.victim = enemy
			damage_table.damage = damage_per_second*damage_interval
			damage_table.damage_type = damage_type
			damage_table.attacker = caster
			damage_table.ability = ability

			ApplyDamage(damage_table)
		end
	end
end

function modifier_perun_electric_shield:OnDestroy()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()

	if not parent then
		return
	end

	-- Stop loop sound
	--parent:StopSound("Hero_Dark_Seer.Ion_Shield_lp")

	-- Emit End sound
	parent:EmitSound("Hero_Dark_Seer.Ion_Shield_end")
	
	if self.particle then
		--ParticleManager:ReleaseParticleIndex(self.particle)
	end
end

function modifier_perun_electric_shield:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_perun_electric_shield:GetModifierProvidesFOWVision()
	if self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
		return 1
	else
		return 0
	end
end
