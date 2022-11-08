modifier_custom_strong_illusion = class({})

function modifier_custom_strong_illusion:IsHidden()
  return true
end

function modifier_custom_strong_illusion:IsDebuff()
  return false
end

function modifier_custom_strong_illusion:IsPurgable()
  return false
end

function modifier_custom_strong_illusion:RemoveOnDeath()
  return true
end

function modifier_custom_strong_illusion:IsAura()
  return true
end

function modifier_custom_strong_illusion:GetModifierAura()
  return "modifier_chaos_knight_phantasm_illusion"
end

function modifier_custom_strong_illusion:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_custom_strong_illusion:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_custom_strong_illusion:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_custom_strong_illusion:GetAuraRadius()
  return 200
end

function modifier_custom_strong_illusion:GetAuraEntityReject(hEntity)
  local parent = self:GetParent() -- using parent instead of caster so it works on illusions too
  -- Dont provide the aura effect to other heroes
  if hEntity ~= parent then
    return true
  end
  return false
end
