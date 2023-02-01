-- Called OnProjectileHitUnit
function HurlBoulderStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration" , ability:GetLevel() - 1)

	-- Check for spell block and spell immunity (latter because of lotus)
	-- also if the target didn't become spell immune in the same frame when the projectile hit
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	ability:ApplyDataDrivenModifier(caster, target, "modifier_hurl_boulder_stun", {["duration"] = duration})
	target:Interrupt()
end
