-- Adds gold when crit is succesful
function LuckyStars(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- To prevent crashes:
	if not target or target:IsNull() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
		return
    end

	local bonus_gold = ability:GetLevelSpecialValueFor("bonus_gold", ability:GetLevel() - 1)
	local caster_location = caster:GetAbsOrigin()

	-- Give gold (unreliable) to the caster
	--caster:ModifyGold(bonus_gold, false, DOTA_ModifyGold_Unspecified)
	PlayerResource:ModifyGold(caster:GetPlayerOwnerID(), bonus_gold, false, DOTA_ModifyGold_Unspecified)

	-- Coin particles
	local particle_coins = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_coins, 0, caster_location)
	ParticleManager:SetParticleControl(particle_coins, 1, caster_location)
	ParticleManager:ReleaseParticleIndex(particle_coins)

	-- Message Particle, has a bunch of options
	local symbol = 0 -- "+" presymbol
	local color = Vector(255, 200, 33) -- Gold color
	local lifetime = 2
	local digits = string.len(bonus_gold) + 1
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(symbol, bonus_gold, symbol))
    ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(particle, 3, color)
	ParticleManager:ReleaseParticleIndex(particle)
end
