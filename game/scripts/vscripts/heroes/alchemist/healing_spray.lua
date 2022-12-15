-- Called OnCreated modifier_healing_spray_thinker
function HealingSpraySound(keys)
	local target = keys.target
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	target:EmitSound("Hero_Alchemist.AcidSpray")

	-- Stops the sound after the duration; a bit early to ensure the thinker still exists
	Timers:CreateTimer(duration-0.1, function()
		target:StopSound("Hero_Alchemist.AcidSpray")
	end)
end
