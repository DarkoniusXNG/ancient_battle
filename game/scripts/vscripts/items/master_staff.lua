-- Called OnSpellStart
function Mute_Disable_Start(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	local duration = ability:GetLevelSpecialValueFor("mute_duration", ability:GetLevel() - 1)
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		
		-- Play hit sound
		target:EmitSound("DOTA_Item.Nullifier.Target")
		
		if target:IsRealHero() then
			DispelEnemy(target)
			ability:ApplyDataDrivenModifier(caster, target, "modifier_item_master_staff_muted", {["duration"] = duration})
			CustomItemDisable(caster, target)
		else
			local damage_table = {}
			damage_table.attacker = caster
			damage_table.victim = target
			damage_table.damage_type = DAMAGE_TYPE_PURE
			damage_table.ability = ability	
			damage_table.damage = 99999
			ApplyDamage(damage_table)
		end
	end
end

-- Called when modifier_item_master_staff_muted is destroyed
function Mute_Disable_End (keys)
	local target = keys.target
	local caster = keys.caster
	
	CustomItemEnable(caster, target)
end

function DispelEnemy(unit)
	if unit then
		-- Basic Dispel
		local RemovePositiveBuffs = true
		local RemoveDebuffs = false
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false
		unit:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
		unit:RemoveModifierByName("modifier_eul_cyclone")
		unit:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
	end
end
