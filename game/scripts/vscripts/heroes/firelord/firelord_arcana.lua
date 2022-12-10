-- Called OnCreated passive
function ModelChange(event)
    local caster = event.caster

    SwapWearable(caster, "models/heroes/shadow_fiend/shadow_fiend_head.vmdl", "models/heroes/shadow_fiend/head_arcana.vmdl")
    SwapWearable(caster, "models/heroes/shadow_fiend/shadow_fiend_arms.vmdl", "models/items/shadow_fiend/arms_deso/arms_deso.vmdl")

    -- Trail
    local particle = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 2, Vector(1,0,0))
    ParticleManager:SetParticleControl(particle, 3, Vector(1,0,0))
    ParticleManager:SetParticleControl(particle, 6, Vector(1,0,0))
	ParticleManager:ReleaseParticleIndex(particle)

	-- For Arcana casting animations
	caster:AddNewModifier(caster, nil, "modifier_firelord_arcana_animation_translate", {})
end

-- Called OnDeath
function DeathEffect(event)
	local caster = event.caster
	local origin = caster:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, origin)
	ParticleManager:ReleaseParticleIndex(particle)
end

---------------------------------------------------------------------------------------------------

modifier_firelord_arcana_animation_translate = class({})

function modifier_firelord_arcana_animation_translate:IsHidden()
  return true
end

function modifier_firelord_arcana_animation_translate:IsDebuff() 
  return false
end

function modifier_firelord_arcana_animation_translate:IsPurgable() 
  return false
end

function modifier_firelord_arcana_animation_translate:RemoveOnDeath()
  return false
end

function modifier_firelord_arcana_animation_translate:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_firelord_arcana_animation_translate:DeclareFunctions() 
  return {
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
  }
end

function modifier_firelord_arcana_animation_translate:GetActivityTranslationModifiers(...)
  return "arcana"
end

