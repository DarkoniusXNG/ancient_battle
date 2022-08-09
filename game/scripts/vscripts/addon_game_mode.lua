if ancient_battle_gamemode == nil then
	_G.ancient_battle_gamemode = class({})
end

require('util')
require('customgamemode')
-- Essential files:
require('libraries/timers')
require('player_resource')

function Precache(context)
	-- Custom items
	PrecacheItemByNameSync("item_custom_slippers_of_halcyon", context)
	PrecacheItemByNameSync("item_ultimate_king_bar", context)
	PrecacheItemByNameSync("item_infused_robe", context)
	PrecacheItemByNameSync("item_devastator", context)
	PrecacheItemByNameSync("item_pull_staff", context)
	PrecacheItemByNameSync("item_sonic", context)
	PrecacheItemByNameSync("item_splash_cannon", context)
	PrecacheItemByNameSync("item_stoneskin", context)
	
	-- Warp Beast
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_void_spirit.vsndevts", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_void_spirit/pulse", context)
	--"particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse.vpcf"
	
	-- Holdout stuff (units etc.)
	PrecacheUnitByNameSync("npc_dota_custom_corpse_lord", context)
	PrecacheUnitByNameSync("npc_dota_custom_minor_lich", context)
	PrecacheUnitByNameSync("npc_dota_custom_bash_roshling", context)
	PrecacheUnitByNameSync("npc_dota_custom_fire_roshling", context)
	PrecacheUnitByNameSync("npc_dota_kondor", context)
	
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_undying.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lich.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_batrider.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context)
	
	PrecacheResource("particle", "particles/econ/events/ti6/teleport_start_ti6_lvl3.vpcf", context)
end

function Activate()
	print("Ancient Battle custom game activated.")
	ancient_battle_gamemode:InitGameMode()
end
