techies_custom_remote_mines = class({})

LinkLuaModifier("modifier_techies_custom_remote_mine", "heroes/techies/remote_mines.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_custom_mine_slow", "heroes/techies/mine_slow.lua", LUA_MODIFIER_MOTION_NONE)

function techies_custom_remote_mines:GetCastPoint()
	local caster = self:GetCaster()

	if caster:HasScepter() then
		return self:GetSpecialValueFor("scepter_cast_point")
	end

	return self.BaseClass.GetCastPoint(self)
end

function techies_custom_remote_mines:GetCastRange(location, target)
	local caster = self:GetCaster()

	if caster:HasScepter() then
		return self:GetSpecialValueFor("scepter_cast_range")
	end

	return self.BaseClass.GetCastRange(self, location, target)
end

function techies_custom_remote_mines:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Sound
	caster:EmitSound("Hero_Techies.StickyBomb.Plant") -- "Hero_Techies.RemoteMine.Plant"

	local name = "npc_dota_techies_custom_remote_mine"
	-- Check for moving mines talent
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_5")
	if talent and talent:GetLevel() > 0 then
		name = "npc_dota_techies_custom_remote_mine_moving"
	end

	local mine_duration = self:GetSpecialValueFor("duration")
	local mine = CreateUnitByName(name, point, true, caster, caster, caster:GetTeamNumber())
	mine:SetOwner(caster:GetOwner())
	mine:SetControllableByPlayer(caster:GetPlayerID(), true)
	mine:SetDeathXP(20)
	mine:SetMaximumGoldBounty(30)
	mine:SetMinimumGoldBounty(30)
	mine:SetBaseMaxHealth(200)
	mine:SetMaxHealth(200)
	mine:SetHealth(200)
	mine:AddNewModifier(caster, self, "modifier_techies_custom_remote_mine", {})
	mine:AddNewModifier(caster, self, "modifier_kill", {duration = mine_duration})
end

function techies_custom_remote_mines:ProcsMagicStick()
	return true
end

-- Mine modifier ----------------------------------------------------------------------------------

if modifier_techies_custom_remote_mine == nil then
	modifier_techies_custom_remote_mine = class({})
end

function modifier_techies_custom_remote_mine:IsHidden()
	return true
end

function modifier_techies_custom_remote_mine:IsPurgable()
	return false
end

function modifier_techies_custom_remote_mine:IsDebuff()
	return false
end

function modifier_techies_custom_remote_mine:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_techies_custom_remote_mine:OnCreated()
	if not IsServer() then return end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	self.visible = true

	local activation_delay = ability:GetSpecialValueFor("activation_delay") -- serves as fade time
	self:StartIntervalThink(activation_delay)
end

function modifier_techies_custom_remote_mine:OnIntervalThink()
	if not IsServer() then return end

	self.visible = false
	self:StartIntervalThink(-1)
end

function modifier_techies_custom_remote_mine:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_techies_custom_remote_mine:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_techies_custom_remote_mine:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_techies_custom_remote_mine:GetDisableHealing()
	return 1
end

function modifier_techies_custom_remote_mine:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- immunity to knockbacks and motion controllers
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true, -- phased
		[MODIFIER_STATE_INVISIBLE] = not self.visible,
		[MODIFIER_STATE_STUNNED] = false, -- so the mine can use its ability even while stunned
		[MODIFIER_STATE_SILENCED] = false, -- so the mine can use its ability even while silenced
	}
end

---------------------------------------------------------------------------------------------------

function Detonate(parent, ability, caster)
	if not caster or caster:IsNull() or not ability or ability:IsNull() then
		-- Remove the mine
		local parent = self:GetParent()
		if parent and not parent:IsNull() then
			parent:ForceKill(false)
		end
		return
	end

	if not parent or parent:IsNull() then
		return
	end

	if parent:IsOutOfGame() or parent:IsUnselectable() or parent:IsInvulnerable() then
		return
	end

	-- Make mine visible before detonation
	local modifier = parent:FindModifierByName("modifier_techies_custom_remote_mine")
	if modifier and not modifier:IsNull() then
		modifier.visible = true
	end

	-- Sound alert before detonation
	parent:EmitSound("Hero_Techies.RemoteMine.Priming") --"Hero_Techies.RemoteMine.Activate"

	-- KV
	local radius = ability:GetSpecialValueFor("radius") -- explosion radius
	local delay = ability:GetSpecialValueFor("detonation_delay")
	local dmg = ability:GetSpecialValueFor("damage")
	local vision_radius = ability:GetSpecialValueFor("vision_radius")
	local vision_duration = ability:GetSpecialValueFor("vision_duration")

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	-- Check for scepter
	if caster:HasScepter() then
		dmg = ability:GetSpecialValueFor("scepter_damage")
	end

	-- Check for mine slow talent
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_1")
	local has_talent = talent and talent:GetLevel() > 0
	local slow_duration = 0
	if has_talent then
		slow_duration = talent:GetSpecialValueFor("duration")
	end

	-- Damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage = dmg
	damage_table.damage_type = ability:GetAbilityDamageType()
	--damage_table.damage_flags = 
	damage_table.ability = ability

	Timers:CreateTimer(delay, function()
		if parent:IsNull() then
			return
		end
		if parent:IsAlive() and not parent:IsOutOfGame() and not parent:IsUnselectable() and not parent:IsInvulnerable() then
			local parent_team = parent:GetTeamNumber() -- we check this again if mine changed teams somehow
			local parent_origin = parent:GetAbsOrigin() -- we check this again if mine changed position

			local enemies = FindUnitsInRadius(parent_team, parent_origin, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
			for _, enemy in pairs(enemies) do
				if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() and not enemy:HasFlyMovementCapability() then
					-- Apply mine slow if talent is learned
					if has_talent then
						enemy:AddNewModifier(parent, talent, "modifier_techies_custom_mine_slow", {duration = slow_duration})
					end

					-- Victim
					damage_table.victim = enemy

					-- Explode (damage)
					ApplyDamage(damage_table)
				end
			end

			-- Hide the mine
			parent:AddNoDraw()

			-- Explode particles
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf", PATTACH_WORLDORIGIN, parent)
			ParticleManager:SetParticleControl(pfx, 0, parent_origin)
			ParticleManager:SetParticleControl(pfx, 1, Vector(radius, 1, 1))
			ParticleManager:SetParticleControl(pfx, 3, parent_origin)
			ParticleManager:ReleaseParticleIndex(pfx)

			-- Destroy trees
			GridNav:DestroyTreesAroundPoint(parent_origin, radius, false)

			-- Explode sound
			parent:EmitSound("Hero_Techies.RemoteMine.Detonate")

			-- Vision
			ability:CreateVisibilityNode(parent_origin, vision_radius, vision_duration)

			-- Remove the mine
			parent:ForceKill(false)
		end
	end)
end

---------------------------------------------------------------------------------------------------

techies_custom_focused_detonate = class({})

function techies_custom_focused_detonate:GetAOERadius()
	return self:GetSpecialValueFor("radius") 
end

function techies_custom_focused_detonate:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Find the main Remote Mines ability on the caster
	local ability = caster:FindAbilityByName("techies_custom_remote_mines")

	-- Find allies in the radius around target point
	local radius = self:GetVanillaAbilitySpecial("radius")
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER)
	local allies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	-- Iterate over every ally and check if it's a remote mine
	for _, ally in pairs(allies) do
		if ally and not ally:IsNull() and ally.HasModifier then
			if ally:HasModifier("modifier_techies_custom_remote_mine") then
				Detonate(ally, ability, caster)
			end
		end
	end
end

function techies_custom_focused_detonate:IsStealable()
	return false
end

---------------------------------------------------------------------------------------------------

remote_mine_custom_self_detonate = class({})

function remote_mine_custom_self_detonate:OnSpellStart()
	local mine = self:GetCaster()

	-- Find the hero that created this mine
	local hero
	local player = mine:GetPlayerOwner()
	local playerID = mine:GetPlayerOwnerID()
	if not player then
		player = PlayerResource:GetPlayer(playerID)
		if not player then
			-- now we really desperate
			hero = PlayerResource:GetBarebonesAssignedHero(playerID)
		else
			hero = player:GetAssignedHero()
		end
	else
		hero = player:GetAssignedHero()
	end
	if not hero then
		-- last resort
		hero = PlayerResource:GetSelectedHeroEntity(playerID)
	end

	-- Check if hero doesnt exist or it's about to be deleted
	if not hero or hero:IsNull() then
		-- Remove the mine
		mine:ForceKill(false)
		return
	end

	-- Find the main Remote Mines ability on the hero
	local ability = hero:FindAbilityByName("techies_custom_remote_mines")

	-- Detonate
	Detonate(mine, ability, hero)
end

function remote_mine_custom_self_detonate:IsStealable()
	return false
end

