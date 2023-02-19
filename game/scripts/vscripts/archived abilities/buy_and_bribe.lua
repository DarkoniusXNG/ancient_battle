-- Called on Spell Start
-- 1) Checks first if the target is Magic Immune, a Hero, an Illusion, an Ancient Creep, Roshan, a Neutral Creep or a Lane Creep
-- If its a Hero or Ancient Creep checks the level of ability
-- 2) Calculates gold cost and checks if the caster has enough gold
-- 3) Spell Block check
-- 4) Spends gold and gives gold to the target if it's a hero
function BuyStart (event)
	if IsServer() then
		local target = event.target
		local caster = event.caster
		local pID = caster:GetPlayerOwnerID()
		local ability = event.ability
		local ability_level = ability:GetLevel()
		-- Ability Specials
		local hero_duration = ability:GetLevelSpecialValueFor( "hero_duration" , ability_level - 1 )
		-- Gold costs
		local gold_cost_lane_creep = ability:GetLevelSpecialValueFor( "gold_cost_lane_creep" , ability_level - 1 )
		local gold_cost_neutral_creep_base = ability:GetLevelSpecialValueFor( "gold_cost_neutral_creep_base" , ability_level - 1 )
		local gold_cost_ancient_creep_base = ability:GetLevelSpecialValueFor( "gold_cost_ancient_creep_base" , ability_level - 1 )
		local gold_cost_hero_base = ability:GetLevelSpecialValueFor( "gold_cost_hero_base" , ability_level - 1 )
		local gold_cost_hero_level_multiplier = ability:GetLevelSpecialValueFor( "hero_level_multiplier" , ability_level - 1 )
		local gold_cost_hero_streak_multiplier = ability:GetLevelSpecialValueFor( "hero_streak_multiplier" , ability_level - 1 )
		local gold_cost_hero_illusion = 0
		local hero_gold_cost = gold_cost_hero_base
		local creep_gold_cost = gold_cost_neutral_creep_base
		-- Current caster gold
		local caster_gold = caster:GetGold()
		-- Caster Location
		local casterLoc = caster:GetAbsOrigin()
		
		-- Check if the target is a hero
		if target:IsHero() and not target:IsMagicImmune() then
			if target:IsRealHero() then
				--print("Target is a Real Hero that doesn't have magic immunity.")
				if ability_level == 4 then
					-- Calculating hero gold cost
					local target_hero_level = target:GetLevel()
					local target_hero_streak = target:GetStreak()
					if target_hero_level then
						hero_gold_cost = math.ceil (hero_gold_cost + gold_cost_hero_level_multiplier*target_hero_level)
					end
					if target_hero_streak then
						hero_gold_cost = math.ceil (hero_gold_cost + gold_cost_hero_streak_multiplier*target_hero_streak)
					end
					-- Checking caster gold with hero gold cost
					if caster_gold >= hero_gold_cost then
						if ( not target:TriggerSpellAbsorb( ability ) ) then
							--print("Target doesn't have Spell Block.")
							if target:HasModifier("modifier_bribed_cloned_hero") then
								--print("Target hero is bribed.")
								ability:RefundManaCost()
								ability:EndCooldown()
								SendErrorMessage( pID, "Target already bribed!" )
							else
								ability:ApplyDataDrivenModifier(caster, target, "modifier_bribed_hero", {["duration"] = hero_duration})
								-- Spend Gold and Give to Target hero
								caster:SpendGold(hero_gold_cost, 0)
								target:ModifyGold(hero_gold_cost, true, 0)
								--Start the particle and sound.
								target:EmitSound("DOTA_Item.Hand_Of_Midas")
								local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)	
								ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterLoc, false)
							end
						else
							--print("Target have Spell Block.")
						end
					else
						ability:RefundManaCost()
						ability:EndCooldown()
						SendErrorMessage( pID, "Not enough gold! Need: "..hero_gold_cost )
					end
				else
					ability:RefundManaCost()
					ability:EndCooldown()
					SendErrorMessage ( pID, "Need ability level 4!")
				end
			else
				--print("Target is an Illusion of a Hero.")
				-- If illusion have spell block, it's ignored
				-- Gold cost for illusions is gold_cost_hero_illusion = 0
				ability:ApplyDataDrivenModifier(caster, target, "modifier_bought_creep", {})
				--Start the particle and sound.
				target:EmitSound("DOTA_Item.Hand_Of_Midas")
				local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)	
				ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterLoc, false)
			end
		else
			--print("Target is either a hero with magic immunity or a creep.")
			if target:IsHero() then
				--print("Target is a Hero with magic immunity.")
				ability:RefundManaCost()
				ability:EndCooldown()
				-- we need to display the error message
				SendErrorMessage( pID, "Can't Target Spell Immune Heroes!" )
			else
				--print("Target is a creep")
				if not target:IsAncient() then
					-- print("Target is not an Ancient Creep")
					if not target:IsLaneCreepCustom() then
						--print("Target is a neutral creep.")
						local neutral_creep_level = target:GetLevel()
						if neutral_creep_level then
							creep_gold_cost = gold_cost_neutral_creep_base*neutral_creep_level
						end
					else
						--print("Target is a lane creep.")
						creep_gold_cost = gold_cost_lane_creep
					end
					-- Checking caster gold with creep gold cost
					if caster_gold >= creep_gold_cost then
						--print("Caster has enough gold")
						if not target:TriggerSpellAbsorb( ability ) then
							--print("Target doesn't have Spell Block.")
							ability:ApplyDataDrivenModifier(caster, target, "modifier_bought_creep", {})
							-- Spend Gold
							caster:SpendGold(creep_gold_cost, 0)
							--Start the particle and sound.
							target:EmitSound("DOTA_Item.Hand_Of_Midas")
							local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)	
							ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterLoc, false)
						else
							--print("Target have Spell Block.")
						end
					else
						--print("Caster doesn't have enough gold!")
						ability:RefundManaCost()
						ability:EndCooldown()
						SendErrorMessage( pID, "Not enough gold! Need: "..creep_gold_cost )
					end
				else
					-- print("Target is an Ancient Creep or Roshan")
					if IsRoshan(target) then
						-- print("Target is Roshan!")
						if ( not target:TriggerSpellAbsorb( ability ) ) then
							--print("Target doesn't have Spell Block.")
							ability:RefundManaCost()
							ability:EndCooldown()
							SendErrorMessage( pID, "Can't Target Roshan!" )
						else
							--print("Target have Spell Block.")
							-- This part of the code is ensuring that Buy and Bribe remove Spell Block from Roshan
						end
					else
						-- print("Target is not Roshan!")
						if ability_level >= 3 then
							--print("Ability level is 3 or 4")
							-- Calculating Ancient gold cost
							local ancient_level = target:GetLevel()
							local ancient_gold_cost = gold_cost_ancient_creep_base
							if ancient_level then
								ancient_gold_cost = gold_cost_ancient_creep_base*ancient_level
							end
							-- Checking caster gold with ancient gold cost
							if caster_gold >= ancient_gold_cost then
								--print("Caster has enough gold")
								if ( not target:TriggerSpellAbsorb( ability ) ) then
									--print("Target doesn't have Spell Block.")
									ability:ApplyDataDrivenModifier(caster, target, "modifier_bought_creep", {})
									-- Spend Gold
									caster:SpendGold(ancient_gold_cost, 0)
									--Start the particle and sound.
									target:EmitSound("DOTA_Item.Hand_Of_Midas")
									local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)	
									ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterLoc, false)
								else
									--print("Target have Spell Block.")
								end
							else
								--print("Caster doesn't have enough gold!")
								ability:RefundManaCost()
								ability:EndCooldown()
								SendErrorMessage( pID, "Not enough gold! Need: "..ancient_gold_cost )
							end
						else
							--print("Ability level is 1 or 2")
							ability:RefundManaCost()
							ability:EndCooldown()
							SendErrorMessage ( pID, "Need ability level 3!")
						end
					end
				end
			end
		end
	end
end

-- Called when modifier_bought_creep is created
function BuyCreep(keys)
	local caster = keys.caster
	local target = keys.target
	local caster_team = caster:GetTeamNumber()
	local caster_owner = caster:GetPlayerOwnerID() -- Owning player
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_units = ability:GetLevelSpecialValueFor("max_creeps", ability_level)
	local max_ancients = ability:GetLevelSpecialValueFor("max_ancients", ability_level)
	
	-- Initialize the tracking data
	ability.unit_count = ability.unit_count or 0
	ability.bought_table = ability.bought_table or {}
	ability.ancient_count = ability.ancient_count or 0
	ability.ancient_table = ability.ancient_table or {}
		
	if target:IsIllusion() then
		--print("Buying an Illusion of a Hero.")
		target:Interrupt()
		target:SetTeam(caster_team)
		target:SetOwner(caster)
		target:SetControllableByPlayer(caster_owner, true)
		target:SetHealth(target:GetMaxHealth())
	else
		--print("Buying a Creep.")
		target:Interrupt()
		local target_name = target:GetUnitName()
		local bought_creep = CreateUnitByName(target_name, target:GetAbsOrigin(), true, caster, caster, caster_team)
		FindClearSpaceForUnit(bought_creep, target:GetAbsOrigin(), false)
		target:ForceKill(false)
		bought_creep:SetControllableByPlayer(caster_owner, true)
		ability:ApplyDataDrivenModifier(caster, bought_creep, "modifier_bought_general", nil)
		-- Track the unit
		if not bought_creep:IsAncient() then
			ability.unit_count = ability.unit_count + 1
			table.insert(ability.bought_table, bought_creep)
		else
			ability.ancient_count = ability.ancient_count + 1
			table.insert(ability.ancient_table, bought_creep)
		end
	end
		
	-- If the maximum amount of units is reached then kill the oldest unit in tables
	if ability.unit_count > max_units then
		ability.bought_table[1]:ForceKill(false) 
	end

	if ability.ancient_count > max_ancients then
		ability.ancient_table[1]:ForceKill(false) 
	end
end

-- Called when modifier_bribed_hero is created
function BribeHero(keys)
	if IsServer() then
		local caster = keys.caster
		local target = keys.target
		local ability = keys.ability
		local duration = ability:GetLevelSpecialValueFor( "hero_duration" , ability:GetLevel() - 1 )
		-- HideAndCopyHero is a function that creates a copy of a hero and hides the original hero (inside util.lua)
		local clone = HideAndCopyHero (target, caster)
		-- Applying a Modifier to the copy
		ability:ApplyDataDrivenModifier(caster, clone, "modifier_bribed_cloned_hero", {["duration"] = duration})
	end
end

-- Called when modifier_bribed_cloned_hero is destroyed (when clone's duration ends or he dies)
function BribeHeroEnd (keys)
	if IsServer() then
		local caster = keys.caster
		local target = keys.target -- target is a clone of the original hero
		local ability = keys.ability
		local duration = ability:GetLevelSpecialValueFor( "clone_duration" , ability:GetLevel() - 1 )
		local clone_location = target:GetAbsOrigin()
		
		if target then
			-- Function HideTheCopyPermanently hides the clone of the hero and disables all passives and auras on him
			HideTheCopyPermanently(target)
			
			if target:IsAlive() then
				-- Apply a modifier that will keep the clone alive/invulnerable and hidden for a few seconds
				ability:ApplyDataDrivenModifier(caster, target, "modifier_bribed_removing", {["duration"] = duration})
			else
				print("Respawning didn't work!")
			end
			if target and target.original then
				local original = target.original
				original:RemoveModifierByNameAndCaster("modifier_bribed_hero", caster)
				-- Function for revealing the original hero at certain location (inside util.lua)
				UnhideOriginalOnLocation(original, clone_location)
				if target.died and target.died == true then
					-- If clone died original must die too; Caster is the killer;
					local max_health = original:GetMaxHealth()
					local damage_table = {}
					damage_table.attacker = caster
					damage_table.victim = original
					damage_table.damage_type = DAMAGE_TYPE_PURE
					damage_table.ability = ability	
					damage_table.damage = max_health
					ApplyDamage(damage_table)
				else
					local clone_health = target:GetHealth()
					original:SetHealth(clone_health)
				end
			end
		end
	end
end

-- Called when modifier_bribed_removing is destroyed (when duration ends)
function BribeRemoveClone (keys)
	local target = keys.target
	if target then
		target:MakeIllusion() -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
		--target:ForceKill(false) -- it plays a death animation
		target:RemoveSelf()
	end
end

-- Called when modifier_bought_general is destroyed (killed or purged)
function RemoveFromTable (keys)
	local target = keys.target
	local ability = keys.ability

	if target and target:IsAlive() then
		target:ForceKill(false)
	end
	-- Find the unit and remove it from the table
	for i = 1, #ability.bought_table do
		if ability.bought_table[i] == target then
			table.remove(ability.bought_table, i)
			ability.unit_count = ability.unit_count - 1
			break
		end
	end
	
	for j = 1, #ability.ancient_table do
		if ability.ancient_table[j] == target then
			table.remove(ability.ancient_table, j)
			ability.ancient_count = ability.ancient_count - 1
			break
		end
	end
end