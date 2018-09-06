-- Gets the summoning location (in front of the caster) for the new summoned units
function GetSummonPoints(event)
    local caster = event.caster
	local distance = event.distance
	local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
	
	local front_position = origin + fv*distance

    local result = {}
    table.insert(result, front_position)

    return result
end

-- Set units to look at the same point as the caster
function SetUnitsMoveForward(event)
	local caster = event.caster
	local target = event.target
    local fv = caster:GetForwardVector()
    
	target:SetForwardVector(fv)
end
