function ShadowStrikeSlow(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local duration = ability:GetSpecialValueFor("duration")

    ability:ApplyDataDrivenModifier(caster,target,"modifier_shadow_strike_slow_stack",{duration=duration})
    target:SetModifierStackCount("modifier_shadow_strike_slow_stack",caster,10)
end

function ShadowStrikeSlowDecay(event)
    local caster = event.caster
    local target = event.target

    target:SetModifierStackCount("modifier_shadow_strike_slow_stack", caster, target:GetModifierStackCount("modifier_shadow_strike_slow_stack",caster)-2)
end