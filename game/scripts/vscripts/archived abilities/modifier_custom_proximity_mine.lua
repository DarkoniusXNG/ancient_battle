if modifier_custom_proximity_mine == nil then
	modifier_custom_proximity_mine = class({})
end

function modifier_custom_proximity_mine:IsHidden()
    return true
end

function modifier_custom_proximity_mine:IsPurgable()
    return false
end

function modifier_custom_proximity_mine:OnCreated()
	if not IsServer() then
		return
	end
	self:StartIntervalThink(0.15)
end

function modifier_custom_proximity_mine:OnIntervalThink()
	local parent = self:GetParent()
	local mine_team = parent:GetTeamNumber()
	local point = parent:GetAbsOrigin()
	local radius = 450

	if parent:IsOutOfGame() or parent:IsUnselectable() or parent:IsInvulnerable() then
		return
	end

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	local all_enemies = FindUnitsInRadius(mine_team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	local enemies = {}
	for _, enemy in pairs(all_enemies) do
		-- Add here which enemy units should be ignored
		if not enemy:HasFlyMovementCapability() then
			table.insert(enemies, enemy)
		end
	end

	if #enemies > 0 then
		-- Stop Interval think
		self:StartIntervalThink(-1)

		-- Sound
		parent:EmitSound("Hero_Techies.LandMine.Priming")

		local delay = 1.6
		local mine_dmg = 200

		-- Damage table
		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_MAGICAL
		damage_table.damage = mine_dmg

		local parent_name = parent:GetUnitName()

		Timers:CreateTimer(delay, function ()
			if parent:IsNull() then
				return nil
			end
			if parent:IsAlive() and (not parent:IsOutOfGame()) and (not parent:IsUnselectable()) then
				local parent_team = parent:GetTeamNumber()
				local parent_origin = parent:GetAbsOrigin()
				local parent_death_xp = parent:GetDeathXP()
				local all = FindUnitsInRadius(parent_team, parent_origin, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
				local enemies_again = {}
				for _, enemy in pairs(all) do
					-- Add here which enemy units should be ignored
					if not enemy:HasFlyMovementCapability() then
						table.insert(enemies_again, enemy)
					end
				end

				if #enemies_again > 0 then

					-- Hide parent 
					parent:AddNoDraw()

					-- Explode particles
					local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_CUSTOMORIGIN, nil)
					ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
					ParticleManager:SetParticleControl(pfx, 2, Vector(radius, radius, radius))

					Timers:CreateTimer(5.0, function()
						ParticleManager:DestroyParticle(pfx, true)
						ParticleManager:ReleaseParticleIndex(pfx)
					end)

					-- Explode sound
					parent:EmitSound("Hero_Techies.LandMine.Detonate")

					for _, enemy in pairs(enemies_again) do
						damage_table.victim = enemy
						if enemy:IsBuilding() or enemy:IsBarracks() or enemy:IsTower() or enemy:IsFort() then
							damage_table.damage = damage_table.damage*0.25
						end
						-- Explode (damage)
						ApplyDamage(damage_table)
					end

					parent:ForceKill(false)
					
					local hero_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO)
					local enemy_heroes_around = FindUnitsInRadius(parent_team, parent_origin, nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, hero_flags, FIND_ANY_ORDER, false)
					local number_of_heroes = #enemy_heroes_around
					for _, hero in pairs(enemy_heroes_around) do
						if number_of_heroes > 0 then
							hero:AddExperience(parent_death_xp/number_of_heroes, DOTA_ModifyXP_CreepKill, false, false)
						end
					end
					
					self:StartIntervalThink(-1)
				else
					self:StartIntervalThink(0.15)
				end
			end
		end)
	end
end

function modifier_custom_proximity_mine:DeclareFunctions()
	local funcs = {
	  MODIFIER_PROPERTY_DISABLE_HEALING,
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
      MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
      MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

function modifier_custom_proximity_mine:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_custom_proximity_mine:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_custom_proximity_mine:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_custom_proximity_mine:GetDisableHealing()
  return 1
end

function modifier_custom_proximity_mine:OnAttackLanded(event)
  if IsServer() then
    local hParent = self:GetParent()
    if event.target == hParent then
      local hAttacker = event.attacker
      if hAttacker then
        local damage_dealt = 1
        -- To prevent dead staying in memory (preventing SetHealth(0) or SetHealth(-value) )
        if hParent:GetHealth() - damage_dealt <= 0 then
          hParent:Kill(self:GetAbility(), hAttacker)
        else
          hParent:SetHealth(hParent:GetHealth() - damage_dealt)
        end
      end
    end
  end
end