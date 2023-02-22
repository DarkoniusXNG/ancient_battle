
function SpawnHawk(event)
	local caster = event.caster
	local ability = event.ability

	local ability_lvl = ability:GetLevel()
	local fv = caster:GetForwardVector()
	local position = caster:GetAbsOrigin() + fv * 200

	local duration = ability:GetLevelSpecialValueFor("duration", ability_lvl - 1)

	local hawk_name = "npc_dota_beastmaster_hawk"

	local hawk = CreateUnitByName(hawk_name, position, true, caster, caster, caster:GetTeamNumber())
	--FindClearSpaceForUnit(hawk, position, false) -- not needed because the hawk is flying
	hawk:SetOwner(caster:GetOwner())
	hawk:SetControllableByPlayer(caster:GetPlayerID(), true)
	hawk:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

	ability:ApplyDataDrivenModifier(caster, hawk, "modifier_beastmaster_bird", {})
	hawk:SetForwardVector(fv)

	-- Initialize the attack and move trackers
	hawk.hawkMoved = GameRules:GetGameTime()
	hawk.hawkAttacked = GameRules:GetGameTime()
end

--------------------------------------------------------------------------------

-- Keeps track of the last time the hawk moved
function HawkMoved( event )
    local caster = event.caster
    caster.hawkMoved = GameRules:GetGameTime()
end

-- Keeps track of the last time the hawk attacked
function HawkAttacked( event )
    local caster = event.caster
    caster.hawkAttacked = GameRules:GetGameTime()
end

-- If the hawk hasn't moved or attacked in the last duration, apply invis
function HawkInvisCheck( event )
    local caster = event.caster
    local ability = event.ability
    local motionless_time = ability:GetLevelSpecialValueFor("motionless_time", ability:GetLevel() - 1)

    local current_time = GameRules:GetGameTime()
    if (current_time - caster.hawkAttacked) > motionless_time and (current_time - caster.hawkMoved) > motionless_time then
        caster:AddNewModifier(caster, ability, "modifier_invisible", {})
    end
end

---------------------------------------------------------------------------------------------------

beastmaster_call_of_the_wild_hawk_custom = class({})

LinkLuaModifier( "modifier_hawk_invisibility_custom", "heroes/beastmaster/summon_hawk.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hawk_shard_truesight", "heroes/beastmaster/summon_hawk.lua", LUA_MODIFIER_MOTION_NONE )

function beastmaster_call_of_the_wild_hawk_custom:GetAOERadius()
  return self:GetSpecialValueFor("hawk_vision")
end

function beastmaster_call_of_the_wild_hawk_custom:OnSpellStart()
  local target_loc = self:GetCursorPosition()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()
  local duration = self:GetSpecialValueFor("duration")

  local hawk = self:SpawnHawk(caster, playerID, abilityLevel, duration, 1)

  caster:EmitSound("Hero_Beastmaster.Call.Hawk")

  Timers:CreateTimer(2/30, function()
    if hawk and target_loc then
      hawk:MoveToPosition(target_loc)
    end
  end)
end

function beastmaster_call_of_the_wild_hawk_custom:SpawnHawk(caster, playerID, abilityLevel, duration, number_of_hawks)
  local unit_name = "npc_dota_beastmaster_hawk_custom"
  local hawk_hp = self:GetLevelSpecialValueFor("hawk_hp", abilityLevel-1)
  local hawk_armor = self:GetLevelSpecialValueFor("hawk_armor", abilityLevel-1)
  local hawk_speed = self:GetLevelSpecialValueFor("hawk_speed", abilityLevel-1)
  local hawk_vision = self:GetLevelSpecialValueFor("hawk_vision", abilityLevel-1)
  local hawk_magic_resistance = self:GetLevelSpecialValueFor("hawk_magic_resistance", abilityLevel-1)
  local hawk_gold_bounty = self:GetLevelSpecialValueFor("hawk_gold_bounty", abilityLevel-1)

  if caster:HasShardCustom() then
    hawk_magic_resistance = 100
  end

  for i = 1, number_of_hawks do
    -- Spawn hawk and orient it to face the same way as the caster
    local hawk = self:SpawnUnit(unit_name, caster, playerID, abilityLevel, duration, true)

    -- Create particle effects
    local particleName = "particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf"
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle1, 0, hawk:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particle1)

    -- Invisibility buff
    hawk:AddNewModifier(caster, self, "modifier_hawk_invisibility_custom", {})

    -- Fix stats of hawks
    -- HP
    hawk:SetBaseMaxHealth(hawk_hp)
    hawk:SetMaxHealth(hawk_hp)
    hawk:SetHealth(hawk_hp)

    -- ARMOR
    hawk:SetPhysicalArmorBaseValue(hawk_armor)

    -- MOVEMENT SPEED
    hawk:SetBaseMoveSpeed(hawk_speed)

    -- VISION
    hawk:SetDayTimeVisionRange(hawk_vision)
    hawk:SetNightTimeVisionRange(hawk_vision)

    -- Magic Resistance
    hawk:SetBaseMagicalResistanceValue(hawk_magic_resistance)

    -- GOLD BOUNTY
    hawk:SetMaximumGoldBounty(hawk_gold_bounty)
    hawk:SetMinimumGoldBounty(hawk_gold_bounty)

    if caster:HasShardCustom() then
      --local dive_bomb = hawk:AddAbility("beastmaster_hawk_dive_custom")
      --dive_bomb:SetLevel(1)
      -- True-Sight buff
      hawk:AddNewModifier(caster, self, "modifier_hawk_shard_truesight", {})
    end

    if number_of_hawks == 1 then
      return hawk
    end
  end
end

function beastmaster_call_of_the_wild_hawk_custom:SpawnUnit(levelUnitName, caster, playerID, abilityLevel, duration, bRandomPosition)
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

---------------------------------------------------------------------------------------------------

modifier_hawk_invisibility_custom = class({})

function modifier_hawk_invisibility_custom:IsHidden()
  return true
end

function modifier_hawk_invisibility_custom:IsDebuff()
  return false
end

function modifier_hawk_invisibility_custom:IsPurgable()
  return false
end

function modifier_hawk_invisibility_custom:OnCreated()
  local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_hawk_invisibility_custom:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
  }
end

function modifier_hawk_invisibility_custom:GetModifierInvisibilityLevel()
  if IsClient() then
    return 1
  end
end

function modifier_hawk_invisibility_custom:CheckState()
  return {
    [MODIFIER_STATE_INVISIBLE] = true,
  }
end

function modifier_hawk_invisibility_custom:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end

---------------------------------------------------------------------------------------------------

modifier_hawk_shard_truesight = class({})

function modifier_hawk_shard_truesight:IsHidden()
  return true
end

function modifier_hawk_shard_truesight:IsDebuff()
  return false
end

function modifier_hawk_shard_truesight:IsPurgable()
  return false
end

function modifier_hawk_shard_truesight:IsAura()
  return true
end

function modifier_hawk_shard_truesight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_hawk_shard_truesight:GetAuraRadius()
  local parent = self:GetParent()
  return parent:GetCurrentVisionRange()
end

function modifier_hawk_shard_truesight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_hawk_shard_truesight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_hawk_shard_truesight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end
