if dark_ranger_charm == nil then
	dark_ranger_charm = class({})
end

LinkLuaModifier("modifier_charmed_hero", "heroes/dark_ranger/dark_ranger_charm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_charmed_general", "heroes/dark_ranger/dark_ranger_charm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_charmed_cloned_hero", "heroes/dark_ranger/dark_ranger_charm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_charmed_removing", "heroes/dark_ranger/dark_ranger_charm.lua", LUA_MODIFIER_MOTION_NONE)

function dark_ranger_charm:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsRoshan() or target:IsCustomWardTypeUnit() or target:IsHeroDominatedCustom() then
		return UF_FAIL_CUSTOM
	elseif target:IsCourier() then
		return UF_FAIL_COURIER
	elseif (target:IsAncient() and not caster:HasScepter()) then
		return UF_FAIL_ANCIENT
	elseif (target:IsMagicImmune() and not caster:HasScepter()) then
		return UF_FAIL_MAGIC_IMMUNE_ENEMY
	end

	return default_result
end

function dark_ranger_charm:GetCustomCastErrorTarget(target)
	if target:IsRoshan() then
		return "#dota_hud_error_cant_cast_on_roshan"
	end
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	if target:IsHeroDominatedCustom() then
		return "Can't Target Dominated Heroes!"
	end
	return ""
end

function dark_ranger_charm:GetCooldown(level)
	local cooldown_heroes = self:GetSpecialValueFor("cooldown_heroes")
	local cooldown_creeps = self:GetSpecialValueFor("cooldown_creeps")

	if IsServer() then
		local target = self:GetCursorTarget()
		if target and (target:IsHero() or target:IsConsideredHero()) then
			return cooldown_heroes
		elseif target then
			return cooldown_creeps
		end
	end

	return cooldown_heroes
end

function dark_ranger_charm:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- Don't continue if target and caster entities don't exist
	if not target or not caster then
		return
	end

	-- Can't target clones
	if target:IsCloneCustom() then
		self:RefundManaCost()
		self:EndCooldown()
		-- Display the error message
		SendErrorMessage(caster:GetPlayerOwnerID(), "Can't Target Clones or Super illusions!")
		return
	end

	-- Check for spell block
	if target:TriggerSpellAbsorb(self) then
		return
	end

	-- Check for spell immunity (because of lotus); pierces spell immunity with scepter
	if target:IsMagicImmune() and not caster:HasScepter() then
		return
	end

	-- Sound on caster
	caster:EmitSound("Hero_Chen.HolyPersuasionCast")

	local caster_team = caster:GetTeamNumber()
	local caster_owner = caster:GetPlayerOwnerID() -- Owning player id

	-- KVs
	local hero_duration = self:GetSpecialValueFor("charm_hero_duration")
	local creep_duration = self:GetSpecialValueFor("charm_creep_duration")

	-- Scepter duration
	if caster:HasScepter() then
		hero_duration = self:GetSpecialValueFor("charm_hero_duration_scepter")
	end

	-- Interrupt the target
	target:Interrupt()

	if target:IsRealHero() then
		target:AddNewModifier(caster, self, "modifier_charmed_hero", {duration = hero_duration})
	else
		if target:IsIllusion() then
			-- Change illusion ownership
			target:SetTeam(caster_team)
			target:SetOwner(caster:GetOwner())
			target:SetControllableByPlayer(caster_owner, true)
			--target:RemoveModifierByName("modifier_kill")
			target:AddNewModifier(caster, self, "modifier_charmed_general", {})
			target:AddNewModifier(caster, self, "modifier_kill", {duration = creep_duration}) -- this doesn't change the illusion duration unfortunately
		else
			local target_name = target:GetUnitName()
			local target_location = target:GetAbsOrigin()

			-- Kill the creep
			target:ForceKill(false)

			-- Create a new creep under caster's control
			local charmed_creep = CreateUnitByName(target_name, target_location, true, caster, caster, caster_team)
			FindClearSpaceForUnit(charmed_creep, target_location, false)
			charmed_creep:SetOwner(caster:GetOwner())
			charmed_creep:SetControllableByPlayer(caster_owner, true)
			charmed_creep:AddNewModifier(caster, self, "modifier_charmed_general", {duration = creep_duration})
			charmed_creep:AddNewModifier(caster, self, "modifier_kill", {duration = creep_duration})
		end
	end
end

function dark_ranger_charm:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_charmed_hero == nil then
	modifier_charmed_hero = class({})
end

function modifier_charmed_hero:IsHidden() -- needs tooltip (visible only on the target hero)
	return false
end

function modifier_charmed_hero:IsDebuff()
	return true
end

function modifier_charmed_hero:IsPurgable()
	return false
end

function modifier_charmed_hero:OnCreated()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local duration = self:GetDuration()

	-- HideAndCopyHero is a function that creates a copy of a hero and hides the original hero (inside util.lua)
	local copy = HideAndCopyHero(parent, caster)

	-- Apply the charmed debuff that makes the copy invulnerable and leashed
	local mod = copy:AddNewModifier(caster, ability, "modifier_charmed_cloned_hero", {duration = duration})
	mod.original = copy.original

	-- Add Vision so the parent can see his copy (so the parent can see "what they are doing")
	copy:AddNewModifier(parent, nil, "modifier_provide_vision", {duration = duration})

	-- Selecting the copy (Adding to selection) - not ideal
	PlayerResource:AddToSelection(caster:GetPlayerID(), copy)

	-- Sound on the "target hero"
	copy:EmitSound("Hero_Chen.HolyPersuasionEnemy")
end

function modifier_charmed_hero:DeclareFunctions() -- properties of the hidden hero
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_charmed_hero:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_charmed_hero:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_charmed_hero:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_charmed_hero:CheckState() -- states of the hidden hero
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_BLIND] = true,
	}
end

---------------------------------------------------------------------------------------------------

if modifier_charmed_cloned_hero == nil then
	modifier_charmed_cloned_hero = class({})
end

function modifier_charmed_cloned_hero:IsHidden() -- needs tooltip (visible to everyone on the copy)
	return false
end

function modifier_charmed_cloned_hero:IsDebuff()
	return true
end

function modifier_charmed_cloned_hero:IsPurgable()
	return false
end

function modifier_charmed_cloned_hero:OnCreated()
	self.slow = 10

	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.slow = ability:GetSpecialValueFor("move_speed_slow")
	end
end

-- when copy's duration ends or when copy dies
function modifier_charmed_cloned_hero:OnDestroy()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent() -- copy of the original hero
	local copy_location = parent:GetAbsOrigin() -- store the location before we hide and move the copy

	-- Function HideTheCopyPermanently hides the copy of the hero and all modifiers from him (inside util.lua)
	HideTheCopyPermanently(parent)

	-- Apply a modifier that will keep the copy alive/invulnerable and hidden while debuffs exist
	parent:AddNewModifier(parent, nil, "modifier_charmed_removing", {})

	-- Deselect the copy
	PlayerResource:RemoveFromSelection(parent:GetPlayerOwnerID(), parent)

	local original = self.original or parent.original
	if original then
		-- Remove the modifier that hides the original if not removed already
		original:RemoveModifierByNameAndCaster("modifier_charmed_hero", caster)

		-- Function for revealing the original hero at certain location (inside util.lua)
		UnhideOriginalOnLocation(original, copy_location)
	end
end

function modifier_charmed_cloned_hero:DeclareFunctions() -- properties of the copy
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_charmed_cloned_hero:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_charmed_cloned_hero:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_charmed_cloned_hero:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_charmed_cloned_hero:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.slow)
end

if IsServer() then
	function modifier_charmed_cloned_hero:GetMinHealth()
		return 1
	end

	-- This is important when copy is killed somehow
	function modifier_charmed_cloned_hero:OnTakeDamage(event)
		local parent = self:GetParent()
		if event.unit ~= parent then
			return
		end

		if event.damage >= parent:GetHealth() then
			self:Destroy()
		end
	end

	-- This is important when copy dies through some other means
	function modifier_charmed_cloned_hero:OnDeath(event)
		local parent = self:GetParent()

		if event.unit ~= parent then
			return
		end

		self:Destroy()
	end
end

function modifier_charmed_cloned_hero:CheckState() -- states of the copy
	return {
		--[MODIFIER_STATE_INVULNERABLE] = true,
		--[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		--[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_TETHERED] = true,
	}
end

function modifier_charmed_cloned_hero:GetEffectName()
	return "particles/units/heroes/hero_chen/chen_test_of_faith.vpcf"
end

function modifier_charmed_cloned_hero:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

if modifier_charmed_general == nil then
	modifier_charmed_general = class({})
end

function modifier_charmed_general:IsHidden() -- needs tooltip (visible to everyone on the creep)
	return false
end

function modifier_charmed_general:IsDebuff()
	return false
end

function modifier_charmed_general:IsPurgable()
	return false
end

function modifier_charmed_general:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()

	-- Sound on creep or illusion
	parent:EmitSound("Hero_Chen.HolyPersuasionEnemy")
end

function modifier_charmed_general:CheckState() -- states of the dominated creep
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = self:GetElapsedTime() <= 0.1,
		[MODIFIER_STATE_DOMINATED] = true,
	}
end

function modifier_charmed_general:GetEffectName()
	return "particles/units/heroes/hero_chen/chen_test_of_faith.vpcf"
end

function modifier_charmed_general:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

if modifier_charmed_removing == nil then
	modifier_charmed_removing = class({})
end

function modifier_charmed_removing:IsHidden()
	return true
end

function modifier_charmed_removing:IsDebuff()
	return false
end

function modifier_charmed_removing:IsPurgable()
	return false
end

function modifier_charmed_removing:OnCreated()
	if not IsServer() then
		return
	end
	self.counter = 0
	self:StartIntervalThink(1)
end

function modifier_charmed_removing:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then
		return
	end

	--local num_of_active_modifiers = 0
	--for index = 0, parent:GetAbilityCount() - 1 do
		--local ability = parent:GetAbilityByIndex(index)
		--if ability and not ability:IsNull() and ability:GetLevel() > 0 then
			-- NumModifiersUsingAbility doesn't work for every ability for some reason, thanks Valve
			--if ability.NumModifiersUsingAbility and ability:NumModifiersUsingAbility() then
				--num_of_active_modifiers = num_of_active_modifiers + ability:NumModifiersUsingAbility()
			--end
		--end
	--end

	self.counter = self.counter + 1

	if self.counter > 60 then
		self:StartIntervalThink(-1)
		self:Destroy()
	end
end

function modifier_charmed_removing:OnDestroy()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then
		return
	end

	--parent:ForceKill(false) -- it plays a death animation so don't use this
	parent:MakeIllusion() -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
	parent:RemoveSelf()
end

function modifier_charmed_removing:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_charmed_removing:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_charmed_removing:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_charmed_removing:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_charmed_removing:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_charmed_removing:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_BLIND] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
	}
end
