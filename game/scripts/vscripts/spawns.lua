function DifficultyCheck()
	local heroes_on_the_map = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local difficulty = 1
	if #heroes_on_the_map == 2 then
		difficulty = 2
	elseif #heroes_on_the_map == 3 then
		difficulty = 3
	elseif #heroes_on_the_map == 4 then
		difficulty = 4
	end
	return difficulty
end
-- Fixing the AI/pathing of spawned units (for example for those that are not spawned with a spawner function)
function AttackMoveCommand(event)
	local target = event.target
	
	Timers:CreateTimer(function()
		if target:GetTeam() == DOTA_TEAM_BADGUYS then
			local order =
			{
				UnitIndex = target:GetEntityIndex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = Vector(0,0,0),
				Queue = true
			}
			ExecuteOrderFromTable(order)
		end
	end)
end

function AllEnemyCreaturesAttackMoveCommand()
	local creatures_on_map = Entities:FindAllByClassname("npc_dota_creature")
	for _,creature in pairs(creatures_on_map) do
		local table1 = {}
		table1.target = creature
		AttackMoveCommand(table1) -- this function will check if the creature is in enemy team and give him the command if true
	end
end

function SpawnWave(spawner_name, destination_name, units_to_spawn, number_of_units)
    local point = Entities:FindByName(nil, spawner_name):GetAbsOrigin()
	local waypoint = Entities:FindByName(nil, destination_name):GetAbsOrigin()
	for i=1,number_of_units do
		local unit = CreateUnitByName(units_to_spawn, point+RandomVector(RandomInt(100,200)), true, nil, nil, DOTA_TEAM_BADGUYS)
		Timers:CreateTimer(function()
			local order =
			{
				UnitIndex = unit:GetEntityIndex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = waypoint,
				Queue = true
			}
			ExecuteOrderFromTable(order)
		end)
	end
end

function SpawnDefence(spawner_name, destination_name, units_to_spawn, number_of_units)
	local point = Entities:FindByName(nil, spawner_name):GetAbsOrigin()
	local waypoint = Entities:FindByName(nil, destination_name):GetAbsOrigin()
	
	for i=1,number_of_units do
		local unit = CreateUnitByName(units_to_spawn, point+RandomVector(RandomInt(100,200)), true, nil, nil, DOTA_TEAM_GOODGUYS)
		Timers:CreateTimer(function()	
			local order =
			{
				UnitIndex = unit:GetEntityIndex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = waypoint,
				Queue = true
			}
			ExecuteOrderFromTable(order)
		end)
	end
end

function SpawnFirstSevenWaves()
	local pre_wave_message_time1 = 20.0
	local wave_1 = 30.0
	local wave_2 = 60.0
	local wave_3 = 90.0
	local wave_4 = 120.0
	local wave_5 = 150.0
	local wave_6 = 170.0
	local wave_7 = 180.0
	Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 1 will start at 00:30", duration=10.0})
	GameRules:SendCustomMessage("Stage 1 will start at 0:30", 0, 0)
	
	Timers:CreateTimer(pre_wave_message_time1, function()
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="First Wave will come in 10 seconds.", duration=5.0})
	end)
	Timers:CreateTimer(wave_1, function()
		--print("Stage 1: Dire Creeps")
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 1: Dire Creeps", duration=8.0, style={color="red", ["font-size"]="60px"}})
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee", 5)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged", 1)
	end)
	
	Timers:CreateTimer(wave_2, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee", 3)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged", 1)
	end)
	
	Timers:CreateTimer(wave_3, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged", 2)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded", 2)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee", 4)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged", 1)
	end)
	
	Timers:CreateTimer(wave_4, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_upgraded", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged_upgraded", 2)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded", 2)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded", 4)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded", 4)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded", 1)
	end)
	
	Timers:CreateTimer(wave_5, function()
		GameRules:SendCustomMessage("Dire Catapults are coming from ALL SIDES!", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_badguys_siege", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_badguys_siege", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_badguys_siege", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_creep_badguys_melee", 4)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_badguys_siege", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_creep_badguys_ranged", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded", 3)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded", 2)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded", 3)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded", 2)
		SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded", 3)
		SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded", 2)
	end)
	
	Timers:CreateTimer(wave_6, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_upgraded", 4)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_badguys_siege_upgraded", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged", 3)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_upgraded", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_badguys_siege_upgraded", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_upgraded", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_badguys_siege_upgraded", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_creep_badguys_melee_upgraded", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_goodguys_siege_upgraded", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_creep_badguys_ranged", 1)
		
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded", 2)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded", 2)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded", 1)
		SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded", 1)
		SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded", 1)
	end)
	
	Timers:CreateTimer(wave_7, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_badguys_siege_upgraded_mega", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_upgraded", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged_upgraded", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_badguys_siege_upgraded_mega", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_badguys_siege_upgraded_mega", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_goodguys_siege_upgraded_mega", 1)
		
		Stage2()
	end)
end

function Stage2()
	local pre_wave_8 = 60.0
	local pre_wave_8_2 = 70.0
	local wave_8 = 80.0
	local wave_8_2 = 85.0
	local wave_8_3 = 90.0
	local wave_9 = 100.0
	local wave_10 = 110.0
	local wave_10_2 = 140.0 -- reinforcements
	local wave_11 = 160.0
	local wave_11_2 = 170.0 -- reinforcements
	local wave_11_3 = 180.0 -- reinforcements
	local wave_12 = 200.0
	local wave_13 = 230.0
	local wave_13_2 = 240.0
	local wave_13_3 = 250.0
	local wave_14 = 280.0
	local wave_14_2 = 285.0 -- reinforcements, message and check for the next stage
	
	Timers:CreateTimer(pre_wave_8, function()
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 2 will start in 20 seconds.", duration=5.0})
		GameRules:SendCustomMessage("Stage 2 will start at 4:20", 0, 0)
	end)
	
	Timers:CreateTimer(pre_wave_8_2, function()
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 2 will start in 10 seconds.", duration=5.0})
	end)
	
	Timers:CreateTimer(wave_8, function()
		--print("Stage 2: Night of the Undead")
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 2: Night of the Undead", duration=8.0, style={color="red", ["font-size"]="60px"}})
		GameRules:SendCustomMessage("The Undead are coming from ALL SIDES!", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_spooky_scary_skeleton", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_spooky_scary_skeleton", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_spooky_scary_skeleton", 5)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
	end)
	
	Timers:CreateTimer(wave_8_2, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_spooky_scary_skeleton", 5)
		if DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_spooky_scary_skeleton", 5)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_spooky_scary_skeleton", 5)
		end
	end)
	
	Timers:CreateTimer(wave_8_3, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_spooky_scary_skeleton", 5)
		if DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_spooky_scary_skeleton", 5)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_spooky_scary_skeleton", 5)
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_spooky_scary_skeleton", 5)
		end
	end)
	
	Timers:CreateTimer(wave_9, function()
		GameRules:SendCustomMessage("Incoming zombies!", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_basic_zombie", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 2)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_corpse_lord", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_basic_zombie", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
	end)
	
	Timers:CreateTimer(wave_10, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_basic_zombie", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_exploding_zombie", 2)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 2)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_corpse_lord", 1)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		if DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_corpse_lord", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_corpse_lord", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_basic_zombie", 5)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_corpse_lord", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_basic_zombie", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_corpse_lord", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		end
	end)
	
	Timers:CreateTimer(wave_10_2, function()
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_11, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 2)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_basic_zombie", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_exploding_zombie", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_corpse_lord", 1)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_diretide", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_basic_zombie", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_basic_zombie", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_exploding_zombie", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_diretide", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_basic_zombie", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		end	
		GameRules:BeginTemporaryNight(200.0) -- Night will end on 9 minute of game time
	end)
	
	Timers:CreateTimer(wave_11_2, function()
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_11_3, function()
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_12, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_diretide", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged_diretide", 2)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_diretide", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_creep_badguys_ranged_diretide", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_melee_diretide", 5)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_creep_badguys_ranged_diretide", 2)
		end
	end)
	
	Timers:CreateTimer(wave_13, function()
		GameRules:SendCustomMessage("The Undead are coming from ALL SIDES!", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_combie", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_13_2, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_mali_trenja", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_13_3, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_combie", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_14, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_combie", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_combie", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_combie", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_mali_trenja", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_minor_lich", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_combie", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 2)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		end
	end)
	
	Timers:CreateTimer(wave_14_2, function()
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
		GameRules:SendCustomMessage("You need to kill ALL enemies if you want to start the next stage!", 0, 0)
		CreatureDeadCheck(3)
	end)
end

function CreatureDeadCheck(next_round)
	Timers:CreateTimer(60.0, function()
		local creatures_on_map = Entities:FindAllByClassname("npc_dota_creature")
		local number_of_enemy_creatures = 0
		
		for _,creature in pairs(creatures_on_map) do
			if creature:GetTeam() == DOTA_TEAM_BADGUYS then
				number_of_enemy_creatures = number_of_enemy_creatures + 1
			end
		end
		
		if number_of_enemy_creatures > 0 then
			--print("There are still enemies on the map.")
			AllEnemyCreaturesAttackMoveCommand()
			return 1.0
		else
			Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Next Stage will start in 30 seconds.", duration=5.0})
			GameRules:SendCustomMessage("Don't leave items on the ground, they will disappear soon!", 0, 0)
			if next_round == 3 then
				Stage3()
				GameRules:SendCustomMessage("Stage 3 will start in 30 seconds.", 0, 0)
			elseif next_round == 4 then
				Stage4()
				GameRules:SendCustomMessage("Stage 4 will start in 30 seconds.", 0, 0)
			end
		end
	end)
end

function ClearItems()
	local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
	for _,item in pairs(items_on_the_ground) do
		local containedItem = item:GetContainedItem()
		if containedItem then
			UTIL_RemoveImmediate(containedItem)
		end
		UTIL_RemoveImmediate(item)
	end
end

function Stage3()
	local pre_wave_15 = 20.0
	local wave_15 = 30.0
	local wave_15_2 = 40.0 -- only messages
	local wave_16 = 60.0
	local wave_17 = 70.0
	local wave_18 = 100.0
	local wave_19 = 110.0
	local wave_20 = 150.0
	local wave_20_1 = 155.0 			-- wave_20 + 5
	local wave_20_2 = 165.0 			-- wave_20 + 15
	local wave_21 = 200.0 				-- ~12 minute (start of night)
	local wave_22 = 230.0				-- wave_21 + 30.0
	local mini_boss_wave_1 = 260.0		-- wave_21 + 60.0
	local mini_boss_wave_2 = 270.0		-- wave_21 + 70.0
	local mini_boss_wave_3 = 280.0		-- wave_21 + 80.0
	local reinforcement_wave_1 = 320.0 	-- wave_21 + 120.0 (from the north)
	local boss_wave = 330.0 			-- reinforcement_wave_1 + 10.0
	
	-- npc_dota_necronomicon_warrior_1
	-- npc_dota_necronomicon_archer_1
	-- npc_dota_necronomicon_warrior_2
	-- npc_dota_necronomicon_archer_2
	-- npc_dota_necronomicon_warrior_3
	-- npc_dota_necronomicon_archer_3
	-- npc_dota_creep_goodguys_melee_diretide
	-- npc_dota_creep_goodguys_ranged_diretide
	Timers:CreateTimer(pre_wave_15, function()
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 3 will start in 10 seconds.", duration=5.0})
	end)
	
	Timers:CreateTimer(wave_15, function()
		--print("Stage 3: Revenge of the Roshan")
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Stage 3: Revenge of the Roshan!", duration=8.0, style={color="blue", ["font-size"]="60px"}})
		GameRules:SendCustomMessage("First part of Roshan army will come from the South.", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_melee_upgraded_mega", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_creep_badguys_ranged_upgraded_mega", 3)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_ranged_upgraded_mega", 1)
	end)
	
	Timers:CreateTimer(wave_15_2, function()
		GameRules:SendCustomMessage("These dire creeps were just running away from the Roshan army...", 0, 0)
		ClearItems()
	end)
	
	Timers:CreateTimer(wave_16, function()
		if DifficultyCheck() == 1 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 5)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_roshling", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_roshling", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_roshling", 2)
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_roshling", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_roshling", 2)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		end
		GameRules:SendCustomMessage("Prepare for the real battle!", 0, 0)
	end)
	
	Timers:CreateTimer(wave_17, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 2)
		end
	end)
	
	Timers:CreateTimer(wave_18, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_greater_roshling", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 2)
		end
	end)
	
	Timers:CreateTimer(wave_19, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_greater_roshling", 5)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 2)
		end
	end)
	
	Timers:CreateTimer(wave_20, function()
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_roshling", 3)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_greater_roshling", 3)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 7)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 2)
		end
	end)
	
	Timers:CreateTimer(wave_20_1, function()
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_roshling", 3)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_greater_roshling", 3)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 7)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
		--AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(wave_20_2, function()
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_roshling", 3)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_greater_roshling", 3)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_fire_roshling", 1)
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 7)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 5)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 3)
		elseif DifficultyCheck() == 4 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 1)
		end
		--AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(wave_21, function()
		GameRules:SendCustomMessage("Roshlings are coming from ALL SIDES!", 0, 0)
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Roshlings are coming from ALL SIDES!", duration=8.0})
		GameRules:SendCustomMessage("We can't send more troops to aid you in battle. Hold on for 2 minutes.", 0, 0)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_greater_roshling", 5)
		SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_greater_roshling", 5)
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_greater_roshling", 5)
		SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_fire_roshling", 1)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_greater_roshling", 5)
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_fire_roshling", 1)
		AllEnemyCreaturesAttackMoveCommand()
		if DifficultyCheck() == 1 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 6)
			SpawnDefence("defence_spawner2", "waypoint_path2", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
		elseif DifficultyCheck() == 2 then
			SpawnDefence("defence_spawner1", "waypoint_path1", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
			SpawnDefence("defence_spawner3", "waypoint_path3", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 10)
		elseif DifficultyCheck() == 3 then
			SpawnDefence("defence_spawner4", "waypoint_path4", "npc_dota_creep_goodguys_melee_upgraded_mega", 8)
		elseif DifficultyCheck() == 4 then
			
		end
	end)
	
	Timers:CreateTimer(wave_22, function()
		if DifficultyCheck() == 1 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_fire_roshling", 1)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner1", "defence_spawner4", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_bash_roshling", 2)
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_fire_roshling", 1)
		end
		AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(mini_boss_wave_1, function()
		GameRules:SendCustomMessage("Kondor is coming from the West!", 0, 0)
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Kondor is coming from the West!", duration=8.0})
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_kondor", 1)
		if DifficultyCheck() == 1 then
			
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_greater_roshling", 2)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_greater_roshling", 3)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_greater_roshling", 5)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 2)
		end
		AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(mini_boss_wave_2, function()
		if DifficultyCheck() == 1 then
		
		else
			GameRules:SendCustomMessage("Another Kondor is coming from the East!", 0, 0)
			Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Another Kondor is coming from the East!", duration=8.0})
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_kondor", 1)
			SpawnWave("horde_spawner3", "defence_spawner2", "npc_dota_custom_bash_roshling", 2)
		end
		--AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(mini_boss_wave_3, function()
		GameRules:SendCustomMessage("Another Kondor is coming from the North!", 0, 0)
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Another Kondor is coming from the North!", duration=8.0})
		SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_kondor", 1)
		if DifficultyCheck() == 1 then
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_greater_roshling", 1)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_greater_roshling", 2)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_greater_roshling", 3)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner4", "defence_spawner1", "npc_dota_custom_greater_roshling", 5)
		end
		--AllEnemyCreaturesAttackMoveCommand()
	end)
	
	Timers:CreateTimer(boss_wave, function()
		GameRules:SendCustomMessage("Roshan is coming from the West!", 0, 0)
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="Roshan is coming from the West!", duration=8.0})
		SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_boss_roshan", 1)
		
		if DifficultyCheck() == 1 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 1)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 1)
		elseif DifficultyCheck() == 2 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 2)
		elseif DifficultyCheck() == 3 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 3)
		elseif DifficultyCheck() == 4 then
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_fire_roshling", 2)
			SpawnWave("horde_spawner2", "defence_spawner3", "npc_dota_custom_bash_roshling", 4)
		end
		AllEnemyCreaturesAttackMoveCommand()
	end)
end
