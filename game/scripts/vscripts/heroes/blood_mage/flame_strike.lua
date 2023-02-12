if blood_mage_flame_strike == nil then
	blood_mage_flame_strike = class({})
end

LinkLuaModifier("modifier_flame_strike_thinker", "heroes/blood_mage/flame_strike.lua", LUA_MODIFIER_MOTION_NONE)

function blood_mage_flame_strike:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function blood_mage_flame_strike:GetCooldown(level)
	local caster = self:GetCaster()
	local base_cooldown = self.BaseClass.GetCooldown(self, level)

	-- Talent that decreases cooldown
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_4")
	if talent and talent:GetLevel() > 0 then
		return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
	end

	return base_cooldown
end

function blood_mage_flame_strike:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	local caster_team = caster:GetTeamNumber()

	local particle_name1 = "particles/blood_mage/invoker_sun_strike_team_immortal1.vpcf"
    local particle1 = ParticleManager:CreateParticleForTeam(particle_name1, PATTACH_CUSTOMORIGIN, caster, caster_team)
	ParticleManager:SetParticleControl(particle1, 0, point)
	ParticleManager:ReleaseParticleIndex(particle1)

	local particle_name2 = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line_ground.vpcf"
    local particle2 = ParticleManager:CreateParticleForTeam(particle_name2, PATTACH_CUSTOMORIGIN, caster, caster_team)
    ParticleManager:SetParticleControl(particle2, 0, point)
	ParticleManager:ReleaseParticleIndex(particle2)

	local particle_name3 = "particles/neutral_fx/black_dragon_fireball_lava_scorch.vpcf"
    local particle3 = ParticleManager:CreateParticleForTeam(particle_name3, PATTACH_CUSTOMORIGIN, caster, caster_team)
    ParticleManager:SetParticleControl(particle3, 0, point)
    ParticleManager:SetParticleControl(particle3, 2, Vector(11,0,0))
	ParticleManager:ReleaseParticleIndex(particle3)

	-- Sound on caster
	caster:EmitSound("Hero_Invoker.SunStrike.Charge")

	local delay = self:GetSpecialValueFor("delay")
	local thinker_duration = self:GetSpecialValueFor("duration")
	local ability = self
	Timers:CreateTimer(delay, function()
		-- Thinker
		CreateModifierThinker(caster, ability, "modifier_flame_strike_thinker", {duration = thinker_duration}, point, caster:GetTeamNumber(), false)
    end)
end

function blood_mage_flame_strike:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_flame_strike_thinker == nil then
	modifier_flame_strike_thinker = class({})
end

function modifier_flame_strike_thinker:IsHidden()
  return true
end

function modifier_flame_strike_thinker:IsDebuff()
  return false
end

function modifier_flame_strike_thinker:IsPurgable()
  return false
end

function modifier_flame_strike_thinker:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()	-- thinker
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local point = parent:GetOrigin()

	local damage_to_units = ability:GetSpecialValueFor("initial_damage")
	local radius = ability:GetSpecialValueFor("radius")
	local interval = ability:GetSpecialValueFor("damage_interval")
	local buildings_damage = ability:GetSpecialValueFor("buildings_damage")

	-- Talent that increases initial damage:
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_2")
	if talent and talent:GetLevel() > 0 then
		damage_to_units = damage_to_units + talent:GetSpecialValueFor("value")
	end

	local damage_to_buildings = damage_to_units*buildings_damage*0.01
	local caster_team = caster:GetTeamNumber()

	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)

	-- Damage enemies (not buildings) in a radius
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy then
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_to_units, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end

	-- Damage enemy buildings in a radius
	local buildings = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy_building in pairs(buildings) do
		if enemy_building then
			ApplyDamage({victim = enemy_building, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end

	-- Sound
	parent:EmitSound("Ability.LightStrikeArray")

	-- Light Strike Particle
	local particle_name1 = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf"
	local particle1 = ParticleManager:CreateParticle(particle_name1, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, point)
	ParticleManager:SetParticleControl(particle1, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(particle1)

	-- Burning ground particle
	local particle_name2 = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf"
	local particle2 = ParticleManager:CreateParticle(particle_name2, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 0, point)
	ParticleManager:SetParticleControl(particle2, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(particle2)

	-- Destroy trees
	GridNav:DestroyTreesAroundPoint(point, radius, false)

	-- Start damaging
	self:StartIntervalThink(interval)
end

function modifier_flame_strike_thinker:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()	-- thinker
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local point = parent:GetOrigin()

	local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local buildings_damage = ability:GetSpecialValueFor("buildings_damage")
	local radius = ability:GetSpecialValueFor("radius")

	local damage_to_units = damage_per_second*damage_interval
	local damage_to_buildings = damage_to_units*buildings_damage*0.01
	local caster_team = caster:GetTeamNumber()

	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)

	-- Damage enemies (not buildings) in a radius
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy then
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_to_units, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end

	-- Damage enemy buildings in a radius
	local buildings = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy_building in pairs(buildings) do
		if enemy_building then
			ApplyDamage({victim = enemy_building, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end

	-- Burning ground particle
	local particle_name = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf"
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, point)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(particle)

	-- Destroy trees
	GridNav:DestroyTreesAroundPoint(point, radius, false)
end

function modifier_flame_strike_thinker:OnDestroy()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	if parent and not parent:IsNull() then
		parent:ForceKill(false)
	end
end
