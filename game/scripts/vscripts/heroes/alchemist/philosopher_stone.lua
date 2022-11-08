-- Called OnProjectileFinish inside Action
function PhilosopherStoneDamage(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local bonus_dmg_multiplier = ability:GetLevelSpecialValueFor("bonus_damage_multiplier", ability_level)

	-- Getting the attributes values
	local caster_str = caster:GetStrength()
	local caster_int = caster:GetIntellect()

	-- Define which attribute is higher
	local higher_attribute
	if caster_str > caster_int then
		higher_attribute = caster_str
	else
		higher_attribute = caster_int
	end

	-- Calculate damage
	local actual_damage = base_damage + bonus_dmg_multiplier*higher_attribute

	-- Set the damage type (depends on damage reductions of the unit)
	local damage_type = DAMAGE_TYPE_MAGICAL

	-- Getting the physical and magical reduction of the target
	local armor = target:GetPhysicalArmorValue(false)
	local armor_reduction = (armor*0.06/(1+0.06*(math.abs(armor))))
	local magic_reduction = target:GetMagicalArmorValue()

	-- Define the damage type accordingly
	if armor_reduction > magic_reduction then
		damage_type = DAMAGE_TYPE_MAGICAL
	else
		damage_type = DAMAGE_TYPE_PHYSICAL
	end

	if target:IsAttackImmune() or target:IsMagicImmune() then
		damage_type = DAMAGE_TYPE_PURE
	end

	-- Creating the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = damage_type
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	damage_table.ability = ability
	damage_table.victim = target
	damage_table.damage = actual_damage

	ApplyDamage(damage_table)
end

-- Called OnProjectileFinish
function PhilosopherStoneSound(event)
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]

	local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", point, false, caster, caster:GetOwner(), caster:GetTeamNumber())

	-- Sounds
	dummy:EmitSound("Hero_Phoenix.ProjectileImpact")
	dummy:EmitSound("Hero_Phoenix.FireSpirits.Target")

	dummy:AddNewModifier(caster, ability, "modifier_kill", {duration = 0.1})
end
