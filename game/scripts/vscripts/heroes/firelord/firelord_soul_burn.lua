-- Called OnSpellStart
function SoulBurnStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)

	-- Checking if target is an enemy 
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Checking if target has spell block
		if not target:TriggerSpellAbsorb(ability) and not target:IsMagicImmune() then
			if caster:HasShardCustom() then
				target:Purge(true, false, false, false, false)
				LinkLuaModifier("modifier_soul_burn_shard_debuff", "heroes/firelord/firelord_soul_burn.lua", LUA_MODIFIER_MOTION_NONE)
			end
			if target:IsRealHero() then
				ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = hero_duration})
				if caster:HasShardCustom() then
					target:AddNewModifier(caster, ability, "modifier_soul_burn_shard_debuff", {duration = hero_duration+0.03})
				end
			else
				ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = creep_duration})
				if caster:HasShardCustom() then
					target:AddNewModifier(caster, ability, "modifier_soul_burn_shard_debuff", {duration = creep_duration+0.03})
				end
			end
		end
	else
		if caster:HasShardCustom() then
			SuperStrongDispel(target, true, false)
		end
		local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability_level)
		local cooldown_allies = ability:GetLevelSpecialValueFor("cooldown_allies", ability_level)

		ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_buff", {["duration"] = buff_duration})
		local cdr = caster:GetCooldownReduction()
		ability:EndCooldown()
		ability:StartCooldown(cdr*cooldown_allies)
	end
end

---------------------------------------------------------------------------------------------------

modifier_soul_burn_shard_debuff = class({})

function modifier_soul_burn_shard_debuff:IsHidden()
  return true
end

function modifier_soul_burn_shard_debuff:IsDebuff()
  return true
end

function modifier_soul_burn_shard_debuff:IsPurgable()
  return true
end

function modifier_soul_burn_shard_debuff:OnCreated()
  if IsServer() then
    local ability = self:GetAbility()
    self.damage_storage = 0
    self.damage_factor = ability:GetSpecialValueFor("shard_damage_percent")
  end
end

function modifier_soul_burn_shard_debuff:OnRefresh()
  if IsServer() then
    self.damage_storage = self.damage_storage or 0

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      self.damage_factor = 30
      return
    end

    self.damage_factor = ability:GetSpecialValueFor("shard_damage_percent")
  end
end

function modifier_soul_burn_shard_debuff:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

if IsServer() then
  function modifier_soul_burn_shard_debuff:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker

	-- Trigger only for this modifier
    if parent ~= event.unit then
      return
    end

    -- To prevent crashes
    if not attacker or attacker:IsNull() then
      return
    end

    self.damage_storage = self.damage_storage + event.damage
  end
end

function modifier_soul_burn_shard_debuff:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    -- If damage was taken, play the effect and damage the owner
    if self.damage_storage > 0 then

      -- Calculate and deal damage
      local damage = self.damage_storage * self.damage_factor * 0.01
      local damage_table = {
        attacker = caster,
        victim = parent,
        ability = ability,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL
      }

      if not caster or caster:IsNull() then
        damage_table.attacker = parent
        damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
      end

      ApplyDamage(damage_table)

      -- Particle
      local particle = ParticleManager:CreateParticle("particles/items2_fx/orchid_pop.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
      ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
      ParticleManager:SetParticleControl(particle, 1, Vector(100, 0, 0))
      ParticleManager:ReleaseParticleIndex(particle)
    end
  end
end
