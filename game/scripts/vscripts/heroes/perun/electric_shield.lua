if perun_electric_shield == nil then
	perun_electric_shield = class({})
end

LinkLuaModifier("modifier_perun_electric_shield", "heroes/perun/electric_shield.lua", LUA_MODIFIER_MOTION_NONE)

function perun_electric_shield:GetAOERadius()
	local caster = self:GetCaster()
	local base_radius = self:GetSpecialValueFor("radius")

	-- Talent that increases radius
	local talent = caster:FindAbilityByName("special_bonus_unique_perun_2")
	if talent and talent:GetLevel() > 0 then
		return base_radius + talent:GetSpecialValueFor("value")
	end

	return base_radius
end

function perun_electric_shield:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end
	
	local buff_duration = self:GetSpecialValueFor("duration")
	-- Shard extended duration
	if caster:HasShardCustom() then
		buff_duration = self:GetSpecialValueFor("shard_duration")
	end

	-- Sound
	target:EmitSound("Hero_Dark_Seer.Ion_Shield_Start")

	-- Apply Modifier (no linkens block)
	target:AddNewModifier(caster, self, "modifier_perun_electric_shield", {duration = buff_duration})
	
	if caster:HasShardCustom() and target:GetTeamNumber() == caster:GetTeamNumber() then
		if target:IsRealHero() then
			target:CalculateStatBonus(true)
		else
			target:CalculateGenericBonuses()
		end
	end
end

function perun_electric_shield:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

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
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then
		return true
	end
	if self:GetParent():GetTeamNumber() ~= caster:GetTeamNumber() then
		return true
	else
		return false
	end
end

if IsServer() then
	function modifier_perun_electric_shield:OnCreated()
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local caster = self:GetCaster()

		local radius = ability:GetSpecialValueFor("radius")
		local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
		
		-- Talent that increases radius
		local talent1 = caster:FindAbilityByName("special_bonus_unique_perun_2")
		if talent1 and talent1:GetLevel() > 0 then
			radius = radius + talent1:GetSpecialValueFor("value")
		end
		
		-- Talent that increases damage
		local talent2 = caster:FindAbilityByName("special_bonus_unique_perun_3")
		if talent2 and talent2:GetLevel() > 0 then
			damage_per_second = damage_per_second + talent2:GetSpecialValueFor("value")
		end
		
		self.radius = radius
		self.damage_per_second = damage_per_second
		self.interval = ability:GetSpecialValueFor("damage_interval")

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
		local caster = self:GetCaster()
		
		if ability and not ability:IsNull() and caster and not caster:IsNull() then
			local radius = ability:GetSpecialValueFor("radius")
			local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
			
			-- Talent that increases radius
			local talent1 = caster:FindAbilityByName("special_bonus_unique_perun_2")
			if talent1 and talent1:GetLevel() > 0 then
				radius = radius + talent1:GetSpecialValueFor("value")
			end
			
			-- Talent that increases damage
			local talent2 = caster:FindAbilityByName("special_bonus_unique_perun_3")
			if talent2 and talent2:GetLevel() > 0 then
				damage_per_second = damage_per_second + talent2:GetSpecialValueFor("value")
			end
			
			self.radius = radius
			self.damage_per_second = damage_per_second
			self.interval = ability:GetSpecialValueFor("damage_interval")
		end
	end

	function modifier_perun_electric_shield:OnIntervalThink()
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()

		if not caster or not parent then
			return
		end

		local radius = self.radius
		if not radius and ability then
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
				if not damage_per_second and ability then
					damage_per_second = ability:GetSpecialValueFor("damage_per_second")
				end
				if not damage_interval and ability then
					damage_interval = ability:GetSpecialValueFor("damage_interval")
				end
				if ability then
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
		local parent = self:GetParent()

		if not parent then
			return
		end

		-- Stop loop sound
		parent:StopSound("Hero_Dark_Seer.Ion_Shield_lp")

		-- Emit End sound
		parent:EmitSound("Hero_Dark_Seer.Ion_Shield_end")

		--if self.particle then
			--ParticleManager:ReleaseParticleIndex(self.particle)
		--end
	end
end

function modifier_perun_electric_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		--MODIFIER_PROPERTY_HEALTH_BONUS, -- works on heroes, doesnt work on creeps
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
	}
end

function modifier_perun_electric_shield:GetModifierProvidesFOWVision()
	if self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
		return 1
	else
		return 0
	end
end

function modifier_perun_electric_shield:GetModifierHealthBonus()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if self:GetParent():GetTeamNumber() == caster:GetTeamNumber() and caster:HasShardCustom() and ability then
		return ability:GetSpecialValueFor("shard_ally_bonus_hp")
	else
		return 0
	end
end

function modifier_perun_electric_shield:GetModifierExtraHealthBonus()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if self:GetParent():GetTeamNumber() == caster:GetTeamNumber() and caster:HasShardCustom() and ability then
		return ability:GetSpecialValueFor("shard_ally_bonus_hp")
	else
		return 0
	end
end
