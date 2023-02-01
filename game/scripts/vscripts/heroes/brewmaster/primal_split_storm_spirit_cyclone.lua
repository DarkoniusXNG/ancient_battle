-- Called OnSpellStart
function Cyclone(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	local ability_level = ability:GetLevel() - 1
	local hero_duration = ability:GetLevelSpecialValueFor("duration_hero", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("duration_creeps", ability_level)

	-- Play sound
	target:EmitSound("Brewmaster_Storm.Cyclone")

	if target:IsRealHero() then
		target:AddNewModifier(caster, ability, "modifier_brewmaster_storm_cyclone", {duration=hero_duration})
	else
		target:AddNewModifier(caster, ability, "modifier_brewmaster_storm_cyclone", {duration=creep_duration})
	end
end
