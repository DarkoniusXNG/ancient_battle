-- Called
function Hide(keys)
    local caster = keys.caster
    local ability = keys.ability
    local modifier = keys.modifier
	local modifier1 = keys.modifier1

    if not GameRules:IsDaytime() then
        ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
		ability:ApplyDataDrivenModifier(caster, caster, modifier1, {})
    else
        if caster:HasModifier(modifier) then
			caster:RemoveModifierByName(modifier)
			caster:RemoveModifierByName(modifier1)
		end
    end
end
