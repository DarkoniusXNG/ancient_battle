-- Called when modifier_giant_growth_active is created
function GrowStart(event)
	local caster = event.caster
	local ability = event.ability

	-- Basic dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- Growing
	local model_size = ability:GetLevelSpecialValueFor("growth_size", ability:GetLevel() - 1)
	local original_model_scale = caster:GetModelScale()
	caster.original_model_scale = original_model_scale
	local model_size_interval = 100 / (model_size - original_model_scale)

	-- Scale Up in 100 intervals (please don't use 100 timers, use only 1)
	local i = 1
	Timers:CreateTimer(function()
		local modelScale = original_model_scale + i/model_size_interval
		caster:SetModelScale(modelScale)
		i = i + 1
		if i > 100 then
			return -- this ends the timer
		else
			return 1/75 -- this repeats the timer after ... seconds
		end
	end)
end

-- Called when modifier_giant_growth_active is destroyed (purged, after death, after duration etc.)
function GrowEnd(event)
	local caster = event.caster
	local ability = event.ability

	local model_size = ability:GetLevelSpecialValueFor("growth_size", ability:GetLevel() - 1)
	local original_model_scale = caster.original_model_scale or 0.74
	local model_size_interval = 100 / (model_size - original_model_scale)

	-- Scale Down in 100 intervals (please don't use 100 timers, use only 1)
	local i = 1
	Timers:CreateTimer(function()
		local modelScale = model_size - i/model_size_interval
		caster:SetModelScale(modelScale)
		i = i + 1
		if i > 100 then
			return
		else
			return 1/50
		end
	end)
end
