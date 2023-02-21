
function UnitVarToPlayerID(unitvar)
  if unitvar then
    if type(unitvar) == "number" then
      return unitvar
    elseif type(unitvar) == "table" and not unitvar:IsNull() and unitvar.entindex and unitvar:entindex() then
      if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
        return unitvar:GetPlayerID()
      elseif unitvar.GetPlayerOwnerID then
        return unitvar:GetPlayerOwnerID()
      end
    end
  end
  return -1
end

LinkLuaModifier("modifier_crypt_lord_carrion_beetles_spawn", "heroes/crypt_lord/carrion_beetles.lua", LUA_MODIFIER_MOTION_NONE)
-- modifier_carrion_beetle

crypt_lord_carrion_beetles = class({})

function crypt_lord_carrion_beetles:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_crypt_lord_carrion_beetles_spawn", {})
	else
		caster:RemoveModifierByNameAndCaster("modifier_crypt_lord_carrion_beetles_spawn", caster)
	end
end

function crypt_lord_carrion_beetles:ProcMagicStick()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_crypt_lord_carrion_beetles_spawn = class({})

function modifier_crypt_lord_carrion_beetles_spawn:IsHidden()
  return true
end

function modifier_crypt_lord_carrion_beetles_spawn:IsPurgable()
  return false
end

function modifier_crypt_lord_carrion_beetles_spawn:RemoveOnDeath()
  return false
end

function modifier_crypt_lord_carrion_beetles_spawn:OnCreated()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  -- Initialize the table of beetles
  if not parent.beetles then
    parent.beetles = {}
  end
end

function modifier_crypt_lord_carrion_beetles_spawn:OnRefresh()
  self:OnCreated()
end

function modifier_crypt_lord_carrion_beetles_spawn:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_crypt_lord_carrion_beetles_spawn:OnDeath(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local dead = event.unit

    if not parent or parent:IsNull() or parent:IsIllusion() then
      return
    end

    -- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
    if dead.GetUnitName == nil then
      return
    end

	local unit_name = "npc_dota_broodmother_spiderling"

	-- Remove a beetle from the table when a beetle (belonging to parent) dies
	if UnitVarToPlayerID(dead) == UnitVarToPlayerID(parent) and (dead:GetUnitName() == unit_name then
		if parent.beetles then
			local beetles = parent.beetles
			for k, beetle in pairs(beetles) do
				if beetle and beetle == dead then
					table.remove(parent.beetles, k)
				end
			end
		end
	end

    -- modifier_kill makes the beetles kill themselves when they expire (dead = killer)
    -- Don't create more beetles if beetles expire or if the dead unit is the parent (parent suicided somehow)
    if dead == killer or dead == parent then
      return
    end

    -- Don't continue if the killer doesn't exist
    if not killer or killer:IsNull() then
      return
    end

    -- Don't continue if the killer doesn't belong to the parent
    if UnitVarToPlayerID(killer) ~= UnitVarToPlayerID(parent) then
      return
    end

    -- Don't continue if the ability doesn't exist
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- KVs
    local base_hp = ability:GetSpecialValueFor("beetle_base_hp")
    local hp_per_level = ability:GetSpecialValueFor("beetle_hp_per_level")
    local base_armor = ability:GetSpecialValueFor("beetle_base_armor")
    local armor_per_level = ability:GetSpecialValueFor("beetle_armor_per_level")
    local base_speed = ability:GetSpecialValueFor("beetle_speed")
    local base_damage = ability:GetSpecialValueFor("beetle_base_attack_damage")
    local damage_per_level = ability:GetSpecialValueFor("beetle_attack_damage_per_level")
    local summon_duration = ability:GetSpecialValueFor("beetle_duration")
    local summon_count = ability:GetSpecialValueFor("beetle_spawn_count")
    local max_count = ability:GetSpecialValueFor("beetle_limit")
    local spawn_radius = ability:GetSpecialValueFor("beetle_spawn_radius")

    -- Beetles can spawn beetles only if near Crypt Lord, otherwise don't continue
    if killer ~= parent and (killer:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > spawn_radius then
      return
    end

	-- Check if dead unit is a hero
    if dead:IsRealHero() then
		summon_count = 3
    end

	-- Kill some beetles if we already reached the max amount of beetles
	local beetle_count = #parent.beetles
	if beetle_count >= max_count then
		local extra_beetles = beetle_count - max_count + summon_count
		for _, v in pairs(parent.beetles) do
			if v and not v:IsNull() and v:IsAlive() then
				v:ForceKill(false)
				extra_beetles = extra_beetles - 1
				if extra_beetles <= 0 then
					break
				end
			end
		end
	end

    local summon_position = dead:GetAbsOrigin() or killer:GetAbsOrigin()

    -- Spawn Particle
    local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn.vpcf", PATTACH_ABSORIGIN, dead)
    ParticleManager:SetParticleControl(pfx, 0, summon_position)
    ParticleManager:ReleaseParticleIndex(pfx)

    -- Talents for beetle stats
    local hp_talent = parent:FindAbilityByName("special_bonus_unique_crypt_lord_beetle_hp")
    local dmg_talent = parent:FindAbilityByName("special_bonus_unique_crypt_lord_beetle_dmg")

    if hp_talent and hp_talent:GetLevel() > 0 then
      base_hp = base_hp + hp_talent:GetSpecialValueFor("value")
    end

    if dmg_talent and dmg_talent:GetLevel() > 0 then
      base_damage = base_damage + dmg_talent:GetSpecialValueFor("value")
    end

    local level = parent:GetLevel()
    local playerID = parent:GetPlayerID()

    -- Calculate stats
    local summon_hp = base_hp + (level - 1) * hp_per_level
    local summon_armor = base_armor + (level - 1) * armor_per_level
    local summon_damage = base_damage + (level - 1) * damage_per_level

    for i = 1, summon_count do
      local summon = self:SpawnUnit(unit_name, parent, playerID, summon_position, false)

      -- Level up beetle abilities
      --local ability1 = summon:FindAbilityByName("")
      --if ability1 then
        --ability1:SetLevel(1)
      --end
      --local ability2 = summon:FindAbilityByName("")
      --if ability2 then
        --ability2:SetLevel(1)
      --end

      -- Add duration to beetles
      summon:AddNewModifier(parent, ability, "modifier_kill", {duration = summon_duration})

      -- Fix stats of summons
      -- HP
      summon:SetBaseMaxHealth(summon_hp)
      summon:SetMaxHealth(summon_hp)
      summon:SetHealth(summon_hp)

      -- DAMAGE
      summon:SetBaseDamageMin(summon_damage)
      summon:SetBaseDamageMax(summon_damage)

      -- ARMOR
      summon:SetPhysicalArmorBaseValue(summon_armor)

      -- Movement speed
      summon:SetBaseMoveSpeed(base_speed)

      table.insert(parent.beetles, summon)
	  
	  --ability:ApplyDataDrivenModifier(parent, summon, "modifier_carrion_beetle", {})

      -- Break the for loop if we reached the maximum
      if #parent.beetles >= max_count then
        break
      end
    end

    -- Spawn sound
    killer:EmitSound("Hero_Broodmother.SpawnSpiderlings")
  end
end

function modifier_crypt_lord_carrion_beetles_spawn:SpawnUnit(unitName, caster, playerID, spawnPosition, bRandomPosition)
  local position = spawnPosition

  if bRandomPosition then
    position = position + RandomVector(1):Normalized() * RandomFloat(50, 100)
  end

  local npcCreep = CreateUnitByName(unitName, position, true, caster, caster:GetOwner(), caster:GetTeam())
  FindClearSpaceForUnit(npcCreep, position, true)
  npcCreep:SetControllableByPlayer(playerID, false)
  npcCreep:SetOwner(caster)
  npcCreep:SetForwardVector(caster:GetForwardVector())

  return npcCreep
end

---------------------------------------------------------------------------------------------------

-- Burrows Up or Down
function Burrow( event )
    local caster = event.caster
    local move = event.Move
    local caster_x = event.caster:GetAbsOrigin().x
    local caster_y = event.caster:GetAbsOrigin().y
    local caster_z = event.caster:GetAbsOrigin().z
    local position = Vector(caster_x, caster_y, caster_z)

    if move == "up" then
        position.z = position.z + 128
        caster:SetAbsOrigin(position)
    else
        position.z = position.z - 128
        caster:SetAbsOrigin(position)
    end
end