keeper_force_of_nature = class({})

function keeper_force_of_nature:GetAOERadius()
  return self:GetSpecialValueFor( "area_of_effect" )
end

-- Check for trees in cast area and throw a cast error if there are none
function keeper_force_of_nature:CastFilterResultLocation( target_point )
  if IsServer() then
    local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )

    if GridNav:IsNearbyTree( target_point, area_of_effect, true ) then
      return UF_SUCCESS
    else
      return UF_FAIL_CUSTOM
    end
  end
end

function keeper_force_of_nature:GetCustomCastErrorLocation( target_point )
  return "#dota_hud_error_must_target_tree"
end

--[[
  Gets all tree entities that would be destroyed by the ability and counts them then spawns treants up to that tree count.
  Prioritizes spawning Giant Treants first before spawning normal Treants if tree count allows it.
]]
function keeper_force_of_nature:OnSpellStart()
  local caster = self:GetCaster()
  local pID = caster:GetPlayerID()
  local target_point = self:GetCursorPosition()
  local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )
  local max_treants = self:GetSpecialValueFor( "max_treants" )
  local duration = self:GetSpecialValueFor( "duration" )
  local ability_level = self:GetLevel()
  -- Units to spawn for each ability level
  local treant_names = {
    "npc_dota_furion_treant_1",
    "npc_dota_furion_treant_2",
    "npc_dota_furion_treant_3",
    "npc_dota_furion_treant_4",
    "npc_dota_furion_treant_5",
    "npc_dota_furion_treant_6"
  }

  -- Treant stats
  local treant_hp = self:GetLevelSpecialValueFor("treant_health", ability_level-1)
  local treant_armor = self:GetLevelSpecialValueFor("treant_armor", ability_level-1)
  local treant_dmg = self:GetLevelSpecialValueFor("treant_damage", ability_level-1)
  local treant_speed = self:GetLevelSpecialValueFor("treant_move_speed", ability_level-1)

  local trees = GridNav:GetAllTreesAroundPoint( target_point, area_of_effect, true )
  local tree_count = #trees

  -- Play the particle
  local particleName = "particles/units/heroes/hero_furion/furion_force_of_nature_cast.vpcf"
  local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
  --ParticleManager:SetParticleControlEnt( particle1, 0, caster, PATTACH_POINT_FOLLOW, "attach_staff_base", caster:GetOrigin(), true )
  ParticleManager:SetParticleControl( particle1, 1, target_point )
  ParticleManager:SetParticleControl( particle1, 2, Vector(area_of_effect,0,0) )
  ParticleManager:ReleaseParticleIndex( particle1 )

  GridNav:DestroyTreesAroundPoint( target_point, area_of_effect, true )

  -- Talent that increases health and damage of treants with a multiplier
  local talent1 = caster:FindAbilityByName("special_bonus_unique_furion")
  if talent1 and talent1:GetLevel() > 0 then
    treant_hp = treant_hp * talent1:GetSpecialValueFor("value")
    treant_dmg = treant_dmg * talent1:GetSpecialValueFor("value")
  end

  -- Talent that increases maximum number of treants
  local talent2 = caster:FindAbilityByName("special_bonus_unique_furion_2")
  if talent2 and talent2:GetLevel() > 0 then
    max_treants = max_treants + talent2:GetSpecialValueFor("value")
  end

  -- Actual number of treants is determined by the number of trees
  local treants_to_spawn = math.min( max_treants, tree_count )

  -- Spawn Treants
  for i = 1, treants_to_spawn do
    local treant = CreateUnitByName( treant_names[ability_level], target_point, true, caster, caster:GetOwner(), caster:GetTeamNumber() )
    treant:SetControllableByPlayer( pID, false )
    treant:SetOwner( caster )
    treant:AddNewModifier( caster, self, "modifier_kill", {duration = duration} )

    -- Fix stats of treants
    -- HP
    treant:SetBaseMaxHealth(treant_hp)
    treant:SetMaxHealth(treant_hp)
    treant:SetHealth(treant_hp)

    -- DAMAGE
    treant:SetBaseDamageMin(treant_dmg)
    treant:SetBaseDamageMax(treant_dmg)

    -- ARMOR
    treant:SetPhysicalArmorBaseValue(treant_armor)

    -- Movement speed
    treant:SetBaseMoveSpeed(treant_speed)
  end

  EmitSoundOnLocationWithCaster( target_point, "Hero_Furion.ForceOfNature", caster )
end