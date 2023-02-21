
function SpawnQuilbeast(event)
	local caster = event.caster
	local ability = event.ability

	local ability_lvl = ability:GetLevel()
	local fv = caster:GetForwardVector()
	local position = caster:GetAbsOrigin() + fv * 200

	local duration = ability:GetLevelSpecialValueFor("duration", ability_lvl - 1)

	local quilbeastNames = {
		[1] = "npc_dota_beastmaster_boar_1",
		[2] = "npc_dota_beastmaster_boar_2",
		[3] = "npc_dota_beastmaster_boar_3",
		[4] = "npc_dota_beastmaster_boar_4",
	}

	local boar = CreateUnitByName(quilbeastNames[ability_lvl], position, true, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(boar, position, false)
	boar:SetOwner(caster:GetOwner())
	boar:SetControllableByPlayer(caster:GetPlayerID(), true)
	boar:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

	ability:ApplyDataDrivenModifier(caster, boar, "modifier_beastmaster_boar", {})
	boar:SetForwardVector(fv)
end

---------------------------------------------------------------------------------------------------

--Handles the AutoCast logic after starting an attack
function FrenzyAutocast( event )
    local caster = event.caster
    local ability = event.ability

    -- Name of the modifier to avoid casting the spell if the caster is buffed
    local modifier = "modifier_frenzy"

    -- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
    if ability:GetAutoCastState() and not caster:HasModifier(modifier) then
        caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
    end 
end

--Adds modifier_model_scale
function FrenzyResize( event )
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)

    caster:AddNewModifier(caster,ability,"modifier_model_scale",{duration=duration,scale=25})
end

---------------------------------------------------------------------------------------------------

beastmaster_call_of_the_wild_boar_custom = class({})

function beastmaster_call_of_the_wild_boar_custom:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  self:SpawnBoar(caster, playerID, abilityLevel, duration)

  caster:EmitSound("Hero_Beastmaster.Call.Boar")

  -- if abilityLevel > 3 then
    -- local npcCreepList = {
      -- "npc_dota_neutral_alpha_wolf",
      -- "npc_dota_neutral_centaur_khan",
      -- "npc_dota_neutral_dark_troll_warlord",
      -- "npc_dota_neutral_polar_furbolg_ursa_warrior",
      -- "npc_dota_neutral_satyr_hellcaller"
    -- }

    -- local levelUnitName = npcCreepList[RandomInt(1, 5)]

    -- local npcCreep = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
  -- end
end

function beastmaster_call_of_the_wild_boar_custom:SpawnBoar(caster, playerID, abilityLevel, duration)
  local baseUnitName = "npc_dota_beastmaster_boar"
  local levelUnitName = baseUnitName .. "_" .. abilityLevel
  local boar_hp = self:GetLevelSpecialValueFor("boar_health", abilityLevel-1)
  local boar_dmg = self:GetLevelSpecialValueFor("boar_damage", abilityLevel-1)
  local boar_armor = self:GetLevelSpecialValueFor("boar_armor", abilityLevel-1)
  local boar_speed = self:GetLevelSpecialValueFor("boar_move_speed", abilityLevel-1)

  -- Talent that increases attack damage of boars
  local talent = caster:FindAbilityByName("special_bonus_unique_beastmaster_2_custom")
  if talent and talent:GetLevel() > 0 then
    boar_dmg = boar_dmg + talent:GetSpecialValueFor("value")
  end

  -- Spawn boar and orient it to face the same way as the caster
  local boar = self:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, false)
  boar:AddNewModifier(caster, self, "modifier_beastmaster_boar_poison", {})

  -- Fix stats of boars
  -- HP
  boar:SetBaseMaxHealth(boar_hp)
  boar:SetMaxHealth(boar_hp)
  boar:SetHealth(boar_hp)

  -- DAMAGE
  boar:SetBaseDamageMin(boar_dmg)
  boar:SetBaseDamageMax(boar_dmg)

  -- ARMOR
  boar:SetPhysicalArmorBaseValue(boar_armor)

  -- MOVEMENT SPEED
  boar:SetBaseMoveSpeed(boar_speed)

  -- Level the boar's poison ability to match abilityLevel
  local boarPoisonAbility = boar:FindAbilityByName("beastmaster_boar_poison")
  if boarPoisonAbility then
    boarPoisonAbility:SetLevel(abilityLevel)
  end

  -- Create particle effects
  local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_boar.vpcf"
  local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(particle1, 0, boar:GetOrigin())
  ParticleManager:ReleaseParticleIndex(particle1)
end

function beastmaster_call_of_the_wild_boar_custom:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, bRandomPosition)
  local position = caster:GetOrigin();

  if bRandomPosition then
    position = position + RandomVector(1):Normalized() * RandomFloat(50, 100)
  end

  local npcCreep = CreateUnitByName(levelUnitName, position, true, caster, caster:GetOwner(), caster:GetTeam())
  npcCreep:SetControllableByPlayer(playerID, false)
  npcCreep:SetOwner(caster)
  npcCreep:SetForwardVector(caster:GetForwardVector())
  npcCreep:AddNewModifier(caster, self, "modifier_kill", {duration = duration})

  return npcCreep
end