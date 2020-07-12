-- Called when modifier_iron_man_form is created
-- Swaps the ranged attack and projectile
function ChangeAttack( keys )
	local target = keys.target
	local projectile_model = keys.projectile_model

	-- Saves the original attack capability
	target.target_attack = target:GetAttackCapability()

	-- Sets the new projectile
	target:SetRangedProjectileName(projectile_model)

	-- Sets the new attack type
	target:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

-- Called when modifier_iron_man_form is destroyed
-- Reverts back to the original attack type and movement type
function RevertAttack( keys )
	local target = keys.target
	target:SetAttackCapability(target.target_attack)
	
	-- Prevent getting stuck on cliffs, units etc.
	FindClearSpaceForUnit(target, target:GetAbsOrigin(), false)
end

function ChangeIllusionAttack( keys )
	local original = keys.target
	local ability = keys.ability
	local original_position = original:GetAbsOrigin()
	local original_playerID = original:GetPlayerID()
	local radius = 20000
	
	local allies = FindUnitsInRadius(original:GetTeam(), original_position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for _,unit in pairs(allies) do
		if not unit:HasModifier("modifier_iron_man_form_illusion") and unit:IsIllusion() and unit:GetPlayerID() == original_playerID then
			-- Apply modifier_iron_man_form_illusion ONLY to Illusions of the original hero, not to ALLIED HEROES OR THEIR ILLUSIONS
			ability:ApplyDataDrivenModifier(original, unit, "modifier_iron_man_form_illusion", {duration = -1})
		end
    end
end