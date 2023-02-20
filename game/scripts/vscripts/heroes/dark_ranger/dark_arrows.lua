if dark_ranger_dark_arrows == nil then
	dark_ranger_dark_arrows = class({})
end

LinkLuaModifier("modifier_dark_arrow_passive", "heroes/dark_ranger/dark_arrows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_arrow_slow", "heroes/dark_ranger/dark_arrows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_arrow_fx", "heroes/dark_ranger/dark_arrows.lua", LUA_MODIFIER_MOTION_NONE)

function dark_ranger_dark_arrows:GetIntrinsicModifierName()
	return "modifier_dark_arrow_passive"
end

function dark_ranger_dark_arrows:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function dark_ranger_dark_arrows:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function dark_ranger_dark_arrows:GetCastRange(location, target)
	return self:GetCaster():GetAttackRange()
end

function dark_ranger_dark_arrows:ShouldUseResources()
	return true
end

function dark_ranger_dark_arrows:IsStealable()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_dark_arrow_passive = class({})

function modifier_dark_arrow_passive:IsHidden()
	return true
end

function modifier_dark_arrow_passive:IsDebuff()
	return false
end

function modifier_dark_arrow_passive:IsPurgable()
	return false
end

function modifier_dark_arrow_passive:RemoveOnDeath()
	return false
end

function modifier_dark_arrow_passive:OnCreated()
	if not IsServer() then
		return
	end
	if not self.procRecords then
		self.procRecords = {}
	end
end

modifier_dark_arrow_passive.OnRefresh = modifier_dark_arrow_passive.OnCreated

function modifier_dark_arrow_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_ATTACK_FINISHED,
	}
end

if IsServer() then
	function modifier_dark_arrow_passive:OnAttackStart(event)
		-- OnAttackStart event is triggering before OnAttack event
		-- Only AttackStart is early enough to override the projectile
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		if parent:IsIllusion() then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Check if ability exists
		if not ability or ability:IsNull() then
			return
		end

		-- Orb
		if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
			if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
				-- The Attack while Autocast is ON or manually casted (current active ability)

				-- Add modifier to change attack sound and projectile
				parent:AddNewModifier(parent, ability, "modifier_dark_arrow_fx", {})
			end
		end
	end

	function modifier_dark_arrow_passive:OnAttack(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		if parent:IsIllusion() then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Check if ability exists
		if not ability or ability:IsNull() then
			return
		end

		-- OnOrbFire
		if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
			if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
			--The Attack while Autocast is ON or or manually casted (current active ability)

			-- Enable proc for this attack record number (event.record is the same for OnAttackLanded)
			self.procRecords[event.record] = true

			-- Use mana and trigger cd while respecting reductions
			-- Using attack modifier abilities doesn't actually fire any cast events so we need to use resources here
			ability:UseResources(true, false, true)

			-- Changing projectile back is too early during OnAttack,
			-- Changing projectile back is done by removing modifier_dark_arrow_fx from the parent
			-- it should be done during OnAttackFinished;
			end
		end
	end

	function modifier_dark_arrow_passive:OnAttackFinished(event)
		local parent = self:GetParent()
		if event.attacker == parent then
			-- Remove modifier on every finished attack even if its a normal attack
			parent:RemoveModifierByName("modifier_dark_arrow_fx")
		end
	end

	function modifier_dark_arrow_passive:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		if parent:IsIllusion() then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check if attacked entity is an item, rune or something weird
		if target.GetUnitName == nil then
			return
		end

		-- Check if ability exists
		if not ability or ability:IsNull() then
			return
		end

		-- OnOrbImpact
		if self.procRecords[event.record] and ability:CastFilterResultTarget(target) == UF_SUCCESS then
			-- Sound on target
			target:EmitSound("Hero_Medusa.MysticSnake.Target")

			-- KVs
			local hero_duration = ability:GetSpecialValueFor("hero_slow_duration")
			local creep_duration = ability:GetSpecialValueFor("creep_slow_duration")
			local damage = ability:GetSpecialValueFor("dark_arrow_damage")

			if target:IsRealHero() then
				target:AddNewModifier(parent, ability, "modifier_dark_arrow_slow", {duration = hero_duration})
			else
				target:AddNewModifier(parent, ability, "modifier_dark_arrow_slow", {duration = creep_duration})
			end

			-- Damage table constants
			local damage_table = {}
			damage_table.attacker = parent
			damage_table.damage_type = ability:GetAbilityDamageType()
			damage_table.ability = ability
			damage_table.victim = target
			damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
			damage_table.damage = damage

			ApplyDamage(damage_table)

			self.procRecords[event.record] = nil
		end
	end

	function modifier_dark_arrow_passive:OnAttackFail(event)
		local parent = self:GetParent()

		if event.attacker == parent and self.procRecords[event.record] then
			-- OnOrbFail
			self.procRecords[event.record] = nil
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_dark_arrow_slow = class({})

function modifier_dark_arrow_slow:IsHidden()
	return false
end

function modifier_dark_arrow_slow:IsDebuff()
	return true
end

function modifier_dark_arrow_slow:IsPurgable()
	return true
end

function modifier_dark_arrow_slow:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local move_speed_slow = 10
	local attack_speed_slow = 10

	if ability and not ability:IsNull() then
		move_speed_slow = ability:GetSpecialValueFor("movement_speed_slow")
		attack_speed_slow = ability:GetSpecialValueFor("attack_speed_slow")
	end

	if IsServer() then
		-- Slow is reduced with Status Resistance
		self.move_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
		self.attack_slow = parent:GetValueChangedByStatusResistance(attack_speed_slow)
	else
		self.move_slow = move_speed_slow
		self.attack_slow = attack_speed_slow
	end
end

modifier_dark_arrow_slow.OnRefresh = modifier_dark_arrow_slow.OnCreated

function modifier_dark_arrow_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_dark_arrow_slow:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.move_slow)
end

function modifier_dark_arrow_slow:GetModifierAttackSpeedBonus_Constant()
	return 0 - math.abs(self.attack_slow)
end

if IsServer() then
	function modifier_dark_arrow_slow:OnDeath(event)
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local killer = event.attacker
		local dead = event.unit

		-- Check if killer exists
		if not killer or killer:IsNull() then
			return
		end

		-- Check if dead unit has this modifier
		if dead ~= parent then
			return
		end

		-- Check for reincarnations
		if parent:IsReincarnating() then
			return
		end

		-- Check if caster exists
		if not caster or caster:IsNull() then
			return
		end

		-- Check if ability exists
		if not ability or ability:IsNull() then
			return
		end

		local ability_lvl = ability:GetLevel()

		-- KVs
		local hp = ability:GetLevelSpecialValueFor("dark_minion_health", ability_lvl-1)
		local dmg = ability:GetLevelSpecialValueFor("dark_minion_damage", ability_lvl-1)
		local duration = ability:GetSpecialValueFor("minion_duration")

		local names = {
			"npc_dota_dark_arrow_minion_1",
			"npc_dota_dark_arrow_minion_2",
			"npc_dota_dark_arrow_minion_3",
			"npc_dota_dark_arrow_minion_4",
		}
		local name = names[ability_lvl]
		local point = parent:GetAbsOrigin()

		-- Create Dark Minion
		local minion = CreateUnitByName(name, point, true, caster, caster, caster:GetTeamNumber())
		FindClearSpaceForUnit(minion, point, false)
		minion:SetOwner(caster:GetOwner())
		minion:SetControllableByPlayer(caster:GetPlayerID(), true)
		minion:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

		-- HP
		minion:SetBaseMaxHealth(hp)
		minion:SetMaxHealth(hp)
		minion:SetHealth(hp)

		-- DAMAGE
		minion:SetBaseDamageMin(dmg)
		minion:SetBaseDamageMax(dmg)

		-- Spawn sound
		minion:EmitSound("Hero_Medusa.MysticSnake.Return")
	end
end

function modifier_dark_arrow_slow:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_dark_arrow_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_dark_arrow_fx = class({})

function modifier_dark_arrow_fx:IsHidden()
	return true
end

function modifier_dark_arrow_fx:IsDebuff()
	return false
end

function modifier_dark_arrow_fx:IsPurgable()
	return false
end

function modifier_dark_arrow_fx:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function modifier_dark_arrow_fx:GetAttackSound()
	return "Hero_DrowRanger.FrostArrows"
end

function modifier_dark_arrow_fx:GetModifierProjectileName()
	return "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf"
end
