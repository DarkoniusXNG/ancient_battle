--[[
	Reflect any damage if they are not magic/spell immune
]]
function milk_reflect( keys )
	-- Variables
	local caster = keys.caster
	local attacker = keys.attacker
	local damageTaken = keys.DamageTaken
	local damage_table = {}
	
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PURE
	damage_table.ability = keys.ability
	damage_table.victim = attacker
	
	-- Check if it's magic immune
	if not attacker:IsMagicImmune() then
		if attacker:GetHealth() <= damageTaken then
			damage_table.damage = damageTaken
			ApplyDamage(damage_table)
		else
		attacker:SetHealth( attacker:GetHealth() - damageTaken )
		end
		caster:SetHealth( caster:GetHealth() + damageTaken )
	end
end

--[[
	Reflect attack damage to range units
]]
function milk_return( keys )
	-- Variables
	local caster = keys.caster
	local attacker = keys.attacker
	local damageTaken = keys.DamageTaken
	local damage_table = {}
	
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PURE
	damage_table.ability = keys.ability
	damage_table.victim = attacker
	
	-- Check if it's magic immune and range unit
	if not attacker:IsMagicImmune() and attacker:IsRangedAttacker() then
		if attacker:GetHealth() <= damageTaken then
			damage_table.damage = damageTaken
			ApplyDamage(damage_table)
		else
		attacker:SetHealth( attacker:GetHealth() - damageTaken )
		end
		caster:SetHealth( caster:GetHealth() + damageTaken )
	end
end

--[[
	Author: Noya
	Plays a looping and stops after the duration
]]
function AcidSpraySound( event )
	local target = event.target
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor( "pish_duration", ability:GetLevel() - 1 )

	target:EmitSound("Hero_Alchemist.AcidSpray")

	-- Stops the sound after the duration, a bit early to ensure the thinker still exists
	Timers:CreateTimer(duration-0.1, function() 
		target:StopSound("Hero_Alchemist.AcidSpray") 
	end)
end