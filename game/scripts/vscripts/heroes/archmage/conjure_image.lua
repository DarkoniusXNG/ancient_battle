-- Called OnSpellStart
function ConjureImage(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	local caster_team = caster:GetTeamNumber()
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if (not target:TriggerSpellAbsorb(ability)) or (target:GetTeamNumber() == caster_team) then
		-- Target is a friend or an enemy that doesn't have Spell Block
		local playerID = caster:GetPlayerID()
		local target_name = target:GetUnitName()
		local target_HP = target:GetHealth()
		local target_MP = target:GetMana()
		local target_level = target:GetLevel()
		local target_ability_count = target:GetAbilityCount()
		local ability_level = ability:GetLevel() - 1
		
		local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
		local outgoingDamage = ability:GetLevelSpecialValueFor("illusion_damage_out", ability_level)
		local incomingDamage = ability:GetLevelSpecialValueFor("illusion_damage_in", ability_level)

		-- Get a random position to create the illusion in
		local origin = target:GetAbsOrigin() + RandomVector(150)

		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local illusion = CreateUnitByName(target_name, origin, true, caster, nil, caster_team)
		illusion:SetPlayerID(playerID)
		illusion:SetControllableByPlayer(playerID, true)
		illusion:SetOwner(caster:GetOwner())
		FindClearSpaceForUnit(illusion, origin, false)
		
		-- Level Up the unit to the target's level
		for i=1,target_level-1 do
			illusion:HeroLevelUp(false) -- false because we don't want to see level up effects
		end

		-- Set the skill points to 0 and learn the skills of the caster
		illusion:SetAbilityPoints(0)
		for abilitySlot=0,target_ability_count-1 do
			local current_ability = target:GetAbilityByIndex(abilitySlot)
			if current_ability then 
				local current_ability_level = current_ability:GetLevel()
				local current_ability_name = current_ability:GetAbilityName()
				local illusion_ability = illusion:FindAbilityByName(current_ability_name)
				illusion_ability:SetLevel(current_ability_level)
			end
		end

		-- Recreate the items of the target to be the same on illusion
		for itemSlot=0,8 do
			local item = target:GetItemInSlot(itemSlot)
			if item then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end

		-- Setting health and mana to be the same as the target hero with items and abilities
		illusion:SetHealth(target_HP)
		illusion:SetMana(target_MP)
		
		-- Preventing dropping and selling items in inventory
		illusion:SetHasInventory(false)
		illusion:SetCanSellItems(false)
		
		-- Set the unit as an illusion
		-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
		illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage})
		
		-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
		illusion:MakeIllusion()
	end
end
