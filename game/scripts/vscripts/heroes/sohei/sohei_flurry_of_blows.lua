sohei_flurry_of_blows = class({})

LinkLuaModifier("modifier_sohei_flurry_self", "heroes/sohei/sohei_flurry_of_blows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_flurry_talent", "heroes/sohei/sohei_flurry_of_blows.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

if IsServer() then
  function sohei_flurry_of_blows:OnSpellStart()
    local caster = self:GetCaster()
    local target_loc = self:GetCursorPosition()
    local flurry_radius = self:GetAOERadius()
    local delay = self:GetSpecialValueFor("delay")
    local bonus_damage = self:GetSpecialValueFor("bonus_damage")

    -- Emit sound
    caster:EmitSound( "Hero_EmberSpirit.FireRemnant.Cast" )

    -- Draw the particle
    if caster.flurry_ground_pfx then
      ParticleManager:DestroyParticle( caster.flurry_ground_pfx, false )
      ParticleManager:ReleaseParticleIndex( caster.flurry_ground_pfx )
    end
    caster.flurry_ground_pfx = ParticleManager:CreateParticle( "particles/hero/sohei/flurry_of_blows_ground.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( caster.flurry_ground_pfx, 0, target_loc )
    ParticleManager:SetParticleControl( caster.flurry_ground_pfx, 10, Vector(flurry_radius,0,0))

    -- Disjoint projectiles
    ProjectileManager:ProjectileDodge(caster)

    -- Put caster in the middle of the circle little above ground
    caster:SetAbsOrigin( target_loc + Vector(0, 0, 200) )

    -- Add a modifier that does actual spell effect
    caster:AddNewModifier( caster, self, "modifier_sohei_flurry_self", {
      duration = delay + 0.1,
      damage = bonus_damage,
      flurry_radius = flurry_radius,
    } )

    -- Give vision over the area
    AddFOWViewer(caster:GetTeamNumber(), target_loc, flurry_radius, delay + 0.1, false)
  end
end

function sohei_flurry_of_blows:GetAOERadius()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("flurry_radius")

	if IsServer() then
		-- Talent that increases radius
		local talent = caster:FindAbilityByName("special_bonus_sohei_fob_radius")
		if talent then
			if talent:GetLevel() ~= 0 then
				radius = radius + talent:GetSpecialValueFor("value")
			end
		end
	else
		if caster:HasModifier("modifier_sohei_flurry_talent") then
			radius = radius + caster.flurry_talent_value
		end
	end

	return radius
end

---------------------------------------------------------------------------------------------------

-- Flurry of Blows' self buff
modifier_sohei_flurry_self = class({})

function modifier_sohei_flurry_self:IsDebuff()
  return false
end

function modifier_sohei_flurry_self:IsHidden()
  return true
end

function modifier_sohei_flurry_self:IsPurgable()
  return false
end

function modifier_sohei_flurry_self:IsStunDebuff()
  return false
end

function modifier_sohei_flurry_self:StatusEffectPriority()
  return 20
end

function modifier_sohei_flurry_self:GetStatusEffectName()
  return "particles/status_fx/status_effect_omnislash.vpcf"
end

function modifier_sohei_flurry_self:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ROOTED] = true
  }

  return state
end

function modifier_sohei_flurry_self:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }

  return funcs
end

function modifier_sohei_flurry_self:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end


function modifier_sohei_flurry_self:OnCreated(event)
  local parent = self:GetParent()
  self.bonus_damage = event.damage
  self.radius = event.flurry_radius

  if IsServer() then
    local delay = event.duration - 0.1
    self:StartIntervalThink(delay)
  end
end

function modifier_sohei_flurry_self:OnIntervalThink()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if IsServer() then
    -- Flurry of Blows actual spell effect - Hit everyone in a radius once at the same time
    local units = FindUnitsInRadius(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
      FIND_ANY_ORDER,
      false
    )

    local bUseProjectile = false
    if ability and ability:IsStolen() then
      bUseProjectile = true
    end

    for _,unit in pairs(units) do
      if unit and not unit:IsNull() and not caster:IsDisarmed() then
        caster:PerformAttack(unit, true, true, true, false, bUseProjectile, false, false)
      end
    end

    --caster:Interrupt()
    --caster:RemoveNoDraw()
    self:Destroy()
  end
end

function modifier_sohei_flurry_self:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    ParticleManager:DestroyParticle( caster.flurry_ground_pfx, false )
    ParticleManager:ReleaseParticleIndex( caster.flurry_ground_pfx )
    caster.flurry_ground_pfx = nil
  end
end

---------------------------------------------------------------------------------------------------

if modifier_sohei_flurry_talent == nil then
	modifier_sohei_flurry_talent = class({})
end

function modifier_sohei_flurry_talent:IsHidden()
    return true
end

function modifier_sohei_flurry_talent:IsPurgable()
    return false
end

function modifier_sohei_flurry_talent:AllowIllusionDuplicate() 
	return false
end

function modifier_sohei_flurry_talent:RemoveOnDeath()
    return false
end

function modifier_sohei_flurry_talent:OnCreated()
	if IsClient() then
		local parent = self:GetParent()
		local talent = self:GetAbility()
		local talent_value = talent:GetSpecialValueFor("value")
		parent.flurry_talent_value = talent_value
	end
end