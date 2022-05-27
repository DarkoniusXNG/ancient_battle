-- Called OnSpellStart
-- Latest update: Added a situation for Charming already Charmed heroes
function CharmStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	local pID = caster:GetPlayerOwnerID()
	local ability_level = ability:GetLevel() - 1
	
	local hero_duration = ability:GetLevelSpecialValueFor("charm_hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("charm_creep_duration", ability_level)
	local hero_duration_scepter = ability:GetLevelSpecialValueFor("charm_hero_duration_scepter", ability_level)
	
	if caster:HasScepter() then
		hero_duration = hero_duration_scepter
	end
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		if target:IsHero() and not target:IsMagicImmune() then
			if target:IsRealHero() then
				-- Target is a Real Hero that doesn't have spell immunity.
				if target:HasModifier("modifier_charmed_hero") then
					-- Target hero is already Charmed.
					ability:RefundManaCost()
					ability:EndCooldown()
					-- Display the error message
					SendErrorMessage(pID, "Can't Target already Charmed Heroes!")
				else
					ability:ApplyDataDrivenModifier(caster, target, "modifier_charmed_hero", {["duration"] = hero_duration})
				end
			else
				-- Target is an illusion of a hero. Creep duration.
				ability:ApplyDataDrivenModifier(caster, target, "modifier_charmed_creep", {["duration"] = creep_duration})
			end
		else
			if not target:IsHero() then
				-- Target is a creep.
				if not target:IsAncient() then
					ability:ApplyDataDrivenModifier(caster, target, "modifier_charmed_creep", {["duration"] = creep_duration})
				else
					-- Target is an Ancient creep
					if caster:HasScepter() and not IsRoshan(target) and not target:IsCourier() then 
						ability:ApplyDataDrivenModifier(caster, target, "modifier_charmed_creep", {["duration"] = creep_duration})
						-- this 'if block' is making sure that Charm works on any creep (even Ancients, but not Roshan) if the caster has Aghanim Scepter.
					else
						-- Target is Roshan or an Ancient creep but Caster doesn't have Aghanim Scepter.
						ability:RefundManaCost()
						ability:EndCooldown()
						-- Display error messages
						if IsRoshan(target) then 
							SendErrorMessage(pID, "Can't Target Roshan!")
						elseif target:IsCourier() then
							SendErrorMessage(pID, "Can't Target Couriers!")
						else
							SendErrorMessage(pID, "Can't Target Ancients without Aghanim Scepter!")
						end
					end
				end
			else
				-- Target is a Hero with spell immunity.
				ability:RefundManaCost()
				ability:EndCooldown()
				-- Display the error message
				SendErrorMessage(pID, "Can't Target Heroes Immune To Spells!")
			end
		end
	end
end

-- Called when modifier_charmed_creep is created
function CharmCreep(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local caster_team = caster:GetTeamNumber()
	local caster_owner = caster:GetPlayerOwnerID() -- Owning player
	
	local creep_duration = ability:GetLevelSpecialValueFor("charm_creep_duration", ability:GetLevel() - 1)
	
	target:Interrupt()
	if target:IsIllusion() then
		target:SetTeam(caster_team)
		target:SetOwner(caster)
		target:SetControllableByPlayer(caster_owner, true)
		--target:RemoveModifierByName("modifier_kill")
		target:AddNewModifier(caster, ability, "modifier_kill", {duration = creep_duration})
	else
		local target_name = target:GetUnitName()
		local target_location = target:GetAbsOrigin()
		target:ForceKill(true)
		local charmed_creep = CreateUnitByName(target_name, target_location, true, caster, caster, caster_team)
		FindClearSpaceForUnit(charmed_creep, target_location, false)
		charmed_creep:SetControllableByPlayer(caster_owner, true)
		--charmed_creep:RemoveModifierByName("modifier_kill")
		charmed_creep:AddNewModifier(caster, ability, "modifier_kill", {duration = creep_duration})
		ability:ApplyDataDrivenModifier(caster, charmed_creep, "modifier_charmed_general", nil)
	end
end

-- Called when modifier_charmed_hero is created
function CharmHero(keys)
	if IsServer() then
		local caster = keys.caster
		local target = keys.target
		local charm_ability = keys.ability
		local ability_level = charm_ability:GetLevel() - 1
		
		-- Setting the duration of the copy (checking if the caster has Aghanim Scepter)
		local duration
		if caster:HasScepter() then
			duration = charm_ability:GetLevelSpecialValueFor("charm_hero_duration_scepter", ability_level)
		else
			duration = charm_ability:GetLevelSpecialValueFor("charm_hero_duration", ability_level)
		end
		
		-- HideAndCopyHero is a function that creates a copy of a hero and hides the original hero (inside util.lua)
		local copy = HideAndCopyHero (target, caster)
		-- Applying a Modifier to the copy
		charm_ability:ApplyDataDrivenModifier(caster, copy, "modifier_charmed_cloned_hero", {["duration"] = duration})
		-- Vision (so the enemy can see what they are doing)
		copy:AddNewModifier(target, nil, "modifier_provide_vision", {duration = duration})
		-- Selecting the copy (Adding to selection)
		PlayerResource:AddToSelection(caster:GetPlayerID(), copy)
	end
end

-- Called when modifier_charmed_cloned_hero is destroyed (when copy's duration ends or when copy dies)
function CharmHeroEnd(keys)
	if IsServer() then
		local caster = keys.caster
		local target = keys.target -- target is a copy of the original hero
		local charm_ability = keys.ability
		local duration = charm_ability:GetLevelSpecialValueFor("charm_clone_duration", charm_ability:GetLevel() - 1)
		local copy_location = target:GetAbsOrigin()
		
		if target then
			-- Function HideTheCopyPermanently hides the copy of the hero and all modifiers from him
			HideTheCopyPermanently(target)
			
			if target:IsAlive() then
				-- Apply a modifier that will keep the copy alive/invulnerable and hidden for the duration
				charm_ability:ApplyDataDrivenModifier(caster, target, "modifier_charmed_removing", {["duration"] = duration})
			else
				print("Respawning didn't work! Report to custom game creator!")
			end
			if target and target.original then
				local original = target.original
				original:RemoveModifierByNameAndCaster("modifier_charmed_hero", caster)
				-- Function for revealing the original hero at certain location (inside util.lua)
				UnhideOriginalOnLocation(original, copy_location)
				-- Deselect the copy/target
				PlayerResource:RemoveFromSelection(caster:GetPlayerID(), target)
			end
		end
	end
end

-- Called when modifier_charmed_removing is destroyed (duration ends)
function CharmRemoveClone(keys)
	if IsServer() then
		local target = keys.target
		if target then
			target:MakeIllusion() -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
			--target:ForceKill(true) -- it plays a death animation so don't use this
			target:RemoveSelf()
		end
	end
end
