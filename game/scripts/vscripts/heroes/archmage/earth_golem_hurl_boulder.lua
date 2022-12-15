-- Called OnProjectileHitUnit
function HurlBoulderStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration" , ability:GetLevel() - 1)

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		-- If the target didn't become spell immune in the same frame as the projectile hit then apply the stun
		if not target:IsMagicImmune() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_hurl_boulder_stun", {["duration"] = duration})
			target:Interrupt()
		end
	end
end
