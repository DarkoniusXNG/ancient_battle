function ShockwaveStart(event)

end

function ShockwaveDamage(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local damage = ability:GetAbilityDamage()

    if damage > 0 then
		ApplyDamage({ victim = target, attacker = caster, damage = damage, ability = ability, damage_type = ability:GetAbilityDamageType() })
    end
end