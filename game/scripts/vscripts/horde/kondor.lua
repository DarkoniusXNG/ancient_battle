-- Called OnProjectileFinish inside Action
function TossDamageAndDebuff(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability:GetLevel() - 1)
	local max_hp_percent_dmg = ability:GetLevelSpecialValueFor("hp_percent_damage", ability:GetLevel() - 1)
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel() - 1)

	local target_max_hp = target:GetMaxHealth()

	-- Calculate damage for heroes
	local actual_damage = base_damage + target_max_hp * max_hp_percent_dmg * 0.01

	-- Damage on non-hero units
	if not target:IsRealHero() then
		actual_damage = 2 * actual_damage
	end

	-- Creating the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	damage_table.ability = ability
	damage_table.victim = target
	damage_table.damage = actual_damage

	ApplyDamage(damage_table)

	-- Apply stun if the target didn't become spell immune during damage calculation
	if not target:IsMagicImmune() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_poop_toss_stun", {["duration"] = stun_duration})
	end
end

-- Called OnSpellStart inside ActOnTargets inside Action
function SlamDamageAndDebuff(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability:GetLevel() - 1)
	local max_hp_percent_dmg = ability:GetLevelSpecialValueFor("hp_percent_damage", ability:GetLevel() - 1)
	local hero_duration = ability:GetLevelSpecialValueFor("slow_duration_hero", ability:GetLevel() - 1)
	local creep_duration = ability:GetLevelSpecialValueFor("slow_duration_creep", ability:GetLevel() - 1)

	local target_max_hp = target:GetMaxHealth()

	-- If the target is a hero
	local actual_damage = base_damage + target_max_hp * max_hp_percent_dmg * 0.01
	local slow_duration = hero_duration

	-- If the target is not a hero:
	if not target:IsRealHero() then
		actual_damage = 2 * actual_damage
		slow_duration = creep_duration
	end

	-- Creating the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	damage_table.ability = ability
	damage_table.victim = target
	damage_table.damage = actual_damage

	ApplyDamage(damage_table)

	-- Apply debuff if the target didn't become spell immune in the mean time
	if not target:IsMagicImmune() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_kondor_slam_debuff", {["duration"] = slow_duration})
	end
end