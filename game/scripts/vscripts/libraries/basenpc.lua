-- Extension functions for CDOTA_BaseNPC
-- This file is also loaded on client

-- On Server:
if CDOTA_BaseNPC then
  function CDOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end

  function CDOTA_BaseNPC:IsCustomBoss()
    return self:HasModifier("modifier_boss_resistance") or self:IsRoshan()
  end

  function CDOTA_BaseNPC:HasShardCustom()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function CDOTA_BaseNPC:IsStrongIllusionCustom()
    return self:HasModifier("modifier_chaos_knight_phantasm_illusion") or self:HasModifier("modifier_vengefulspirit_hybrid_special") or self:HasModifier("modifier_chaos_knight_phantasm_illusion_shard")
  end

  function CDOTA_BaseNPC:IsCloneCustom()
    return self.original or self:IsClone()
  end

  function CDOTA_BaseNPC:IsHeroDominatedCustom()
    return self:HasModifier("modifier_charmed_hero")
  end

  function CDOTA_BaseNPC:IsRoshan()
    if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
      return true
    end

    return false
  end

  function CDOTA_BaseNPC:GetValueChangedByStatusResistance(value)
    if self and value then
      local reduction = self:GetStatusResistance()

      -- Capping max status resistance
      if reduction >= 1 then
        return value*0.01
      end

      -- It should work with Negative Status Resistance
      return value*(1-reduction)
    end
  end

  function CDOTA_BaseNPC:AbsolutePurge()
    local undispellable_item_buffs = {
      "modifier_black_king_bar_immune",
      "modifier_item_blade_mail_reflect",
      "modifier_item_book_of_shadows_buff",
      "modifier_item_hood_of_defiance_barrier",
      "modifier_item_invisibility_edge_windwalk",
      "modifier_item_lotus_orb_active",
      "modifier_item_pipe_barrier",
      "modifier_item_satanic_unholy",
      "modifier_item_shadow_amulet_fade",
      "modifier_item_silver_edge_windwalk",
      "modifier_item_sphere_target",                    -- Linken's Sphere transferred buff
      "modifier_rune_invis",
      -- custom:
      "item_modifier_forgotten_king_bar_damage_shield",
      "modifier_infused_robe_damage_barrier",
      "modifier_item_custom_butterfly_active",
      "modifier_item_custom_heart_active",
      "modifier_item_orb_of_reflection_active_reflect",
      "modifier_item_stoneskin_active",
      "modifier_pull_staff_active_buff",
      "modifier_slippers_of_halcyon_caster",
    }

    local undispellable_item_debuffs = {
      "modifier_item_skadi_slow",
      "modifier_heavens_halberd_debuff",        -- Heaven's Halberd debuff
      "modifier_silver_edge_debuff",            -- Silver Edge debuff
      "modifier_item_nullifier_mute",           -- Nullifier debuff
      -- custom:
      "modifier_pull_staff_active_buff",
    }

    local undispellable_ability_debuffs = {
      "modifier_axe_berserkers_call",
      "modifier_bane_nightmare_invulnerable",						-- invulnerable type
      "modifier_bloodseeker_rupture",
      "modifier_bristleback_quill_spray",							-- Quill Spray stacks
      "modifier_dazzle_bad_juju_armor",								-- Bad Juju stacks
      "modifier_doom_bringer_doom",
      "modifier_earthspirit_petrify",								-- Earth Spirit Enchant Remnant debuff
      "modifier_forged_spirit_melting_strike_debuff",				-- Forged Spirit Melting Strike stacks
      "modifier_grimstroke_soul_chain",
      "modifier_huskar_burning_spear_debuff",						-- Burning Spear stacks
      "modifier_ice_blast",
      "modifier_invoker_deafening_blast_disarm",					-- BKB removes it
      "modifier_maledict",
      "modifier_obsidian_destroyer_astral_imprisonment_prison",		-- doesn't pierce BKB
      "modifier_razor_eye_of_the_storm_armor",						-- Eye of the Storm stacks
      "modifier_razor_static_link_debuff",
      "modifier_sand_king_caustic_finale_orb",						-- Caustic Finale initial debuff
      "modifier_shadow_demon_disruption",							-- doesn't pierce BKB
      "modifier_shadow_demon_purge_slow",
      "modifier_shadow_demon_shadow_poison",
      "modifier_silencer_curse_of_the_silent",						-- Arcane Curse becomes undispellable with the talent
      "modifier_slardar_amplify_damage",							-- Corrosive Haze becomes undispellable with the talent
      "modifier_slark_pounce_leash",								-- BKB removes it
      "modifier_tusk_walrus_kick_slow",
      "modifier_tusk_walrus_punch_slow",
      "modifier_ursa_fury_swipes_damage_increase",
      "modifier_venomancer_poison_nova",							-- doesn't damage through BKB
      "modifier_viper_viper_strike_slow",
      "modifier_windrunner_windrun_slow",
      "modifier_winter_wyvern_winters_curse",
      "modifier_winter_wyvern_winters_curse_aura",					-- doesn't pierce BKB
      -- custom:
      "modifier_bakedanuki_futatsuiwas_curse",
      "modifier_custom_enfeeble_debuff",
      "modifier_custom_rupture",
      "modifier_entrapment",
      "modifier_incinerate_stack",
      "modifier_mana_transfer_leash_debuff",
      "modifier_purge_enemy_creep",
      "modifier_purge_enemy_hero",
      "modifier_time_stop",
      "modifier_time_stop_scepter",
      "modifier_volcano_stun",
    }

    local undispellable_ability_buffs = {
      "modifier_alchemist_chemical_rage",
      "modifier_axe_berserkers_call_armor",
      "modifier_bounty_hunter_wind_walk",
      "modifier_broodmother_insatiable_hunger",
      "modifier_centaur_stampede",
      "modifier_clinkz_wind_walk",
      "modifier_dark_willow_shadow_realm_buff",
      "modifier_dazzle_shallow_grave",
      "modifier_doom_bringer_devour",
      "modifier_doom_bringer_scorched_earth_effect",
      "modifier_doom_bringer_scorched_earth_effect_aura",
      "modifier_enchantress_natures_attendants",
      "modifier_gyrocopter_flak_cannon",
      "modifier_invoker_ghost_walk_self",
      "modifier_juggernaut_blade_fury",
      "modifier_kunkka_ghost_ship_damage_absorb",
      "modifier_kunkka_ghost_ship_damage_delay",
      "modifier_leshrac_diabolic_edict",							-- Removes only one instance
      "modifier_life_stealer_rage",
      "modifier_lone_druid_true_form_battle_cry",
      "modifier_luna_eclipse",
      "modifier_medusa_stone_gaze",
      "modifier_mirana_moonlight_shadow",
      "modifier_nyx_assassin_spiked_carapace",
      "modifier_nyx_assassin_vendetta",
      "modifier_oracle_false_promise_timer",
      "modifier_pangolier_shield_crash_buff",
      "modifier_phantom_assassin_blur_active",
      "modifier_phoenix_supernova_hiding",
      "modifier_rattletrap_battery_assault",
      "modifier_razor_eye_of_the_storm",							-- Removes only one instance
      "modifier_razor_static_link_buff",
      "modifier_skeleton_king_reincarnation_scepter_active",		-- Wraith King Wraith Form
      "modifier_slark_shadow_dance",
      "modifier_templar_assassin_refraction_absorb",
      "modifier_templar_assassin_refraction_damage",
      "modifier_ursa_enrage",
      "modifier_weaver_shukuchi",
      "modifier_windrunner_windrun",
      "modifier_windrunner_windrun_invis",
      "modifier_winter_wyvern_cold_embrace",
      "modifier_wisp_overcharge",
      -- custom:
      "modifier_absorb_bonus_mana_scepter",
      "modifier_custom_blade_storm",
      "modifier_custom_chemical_rage_buff",
      "modifier_custom_death_pact",
      "modifier_custom_marksmanship_buff",
      "modifier_custom_rage_buff",
      "modifier_drunken_fist_bonus",
      "modifier_drunken_fist_knockback",
      "modifier_giant_growth_active",
      "modifier_mana_eater_mana_flare_buff_aura",
      "modifier_mass_haste_buff",
      "modifier_paladin_divine_shield",
      "modifier_paladin_divine_shield_upgraded",
      "modifier_roulette_caster_buff",
      "modifier_sohei_flurry_self",
      "modifier_sohei_guard_reflect",
      "modifier_time_slow_aura_applier",
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, undispellable_item_buffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_item_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_buffs)

    -- Dispel stuff
    local BuffsCreatedThisFrameOnly = false
    local RemoveExceptions = false              -- Offensive Strong Dispel (yes or no), can cause errors, crashes etc.
    local RemoveStuns = true                    -- Defensive Strong Dispel (yes or no)

    self:Purge(true, true, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
  end

  function CDOTA_BaseNPC:IsLeashedCustom()
    local leashes = {
      "modifier_slark_pounce_leash",
      "modifier_grimstroke_soul_chain",
      "modifier_furion_sprout_tether",
      "modifier_puck_coiled",
      -- custom leash modifiers:
      "modifier_custom_leash_debuff",
      "modifier_mana_transfer_leash_debuff",
    }

    for _, v in pairs(leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    local power_cogs = self:FindModifierByName("modifier_rattletrap_cog_marker")
    if power_cogs then
      local caster = power_cogs:GetCaster()
      if caster then
        local talent = caster:FindAbilityByName("special_bonus_unique_clockwerk_2")
        if talent and talent:GetLevel() then
          return true
        end
      end
    end
    return false
  end

  function CDOTA_BaseNPC:IsLaneCreepCustom()
    local unit_name = self:GetUnitName()
    local lane_creep_names = {
      "npc_dota_creep_badguys_ranged",
      "npc_dota_creep_badguys_ranged_upgraded",
      "npc_dota_creep_badguys_ranged_upgraded_mega",
      "npc_dota_creep_goodguys_ranged",
      "npc_dota_creep_goodguys_ranged_upgraded",
      "npc_dota_creep_goodguys_ranged_upgraded_mega",
      "npc_dota_creep_badguys_melee",
      "npc_dota_creep_badguys_melee_upgraded",
      "npc_dota_creep_badguys_melee_upgraded_mega",
      "npc_dota_creep_goodguys_melee",
      "npc_dota_creep_goodguys_melee_upgraded",
      "npc_dota_creep_goodguys_melee_upgraded_mega",
      "npc_dota_goodguys_siege",
      "npc_dota_goodguys_siege_upgraded",
      "npc_dota_goodguys_siege_upgraded_mega",
      "npc_dota_badguys_siege",
      "npc_dota_badguys_siege_upgraded",
      "npc_dota_badguys_siege_upgraded_mega",
	}

    for _, v in pairs(lane_creep_names) do
      if unit_name == v then
        return true
      end
    end

    return false
  end
end

-- On Client:
if C_DOTA_BaseNPC then
  function C_DOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end

  function C_DOTA_BaseNPC:IsCustomBoss()
    return self:HasModifier("modifier_boss_resistance") or self:IsRoshan()
  end

  function C_DOTA_BaseNPC:HasShardCustom()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function C_DOTA_BaseNPC:IsStrongIllusionCustom()
    return self:HasModifier("modifier_chaos_knight_phantasm_illusion") or self:HasModifier("modifier_vengefulspirit_hybrid_special") or self:HasModifier("modifier_chaos_knight_phantasm_illusion_shard")
  end

  --function C_DOTA_BaseNPC:IsCloneCustom()
    --return self.original or self:IsClone()
  --end

  function C_DOTA_BaseNPC:IsHeroDominatedCustom()
    return self:HasModifier("modifier_charmed_hero")
  end

  function C_DOTA_BaseNPC:IsRoshan()
    if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
      return true
    end

    return false
  end

  function C_DOTA_BaseNPC:IsLeashedCustom()
    local leashes = {
      "modifier_slark_pounce_leash",
      "modifier_grimstroke_soul_chain",
      "modifier_furion_sprout_tether",
      "modifier_puck_coiled",
	  -- custom leash modifiers:
      "modifier_custom_leash_debuff",
      "modifier_mana_transfer_leash_debuff",
    }

    for _, v in pairs(leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    return false
  end

  function C_DOTA_BaseNPC:IsLaneCreepCustom()
    local unit_name = self:GetUnitName()
    local lane_creep_names = {
      "npc_dota_creep_badguys_ranged",
      "npc_dota_creep_badguys_ranged_upgraded",
      "npc_dota_creep_badguys_ranged_upgraded_mega",
      "npc_dota_creep_goodguys_ranged",
      "npc_dota_creep_goodguys_ranged_upgraded",
      "npc_dota_creep_goodguys_ranged_upgraded_mega",
      "npc_dota_creep_badguys_melee",
      "npc_dota_creep_badguys_melee_upgraded",
      "npc_dota_creep_badguys_melee_upgraded_mega",
      "npc_dota_creep_goodguys_melee",
      "npc_dota_creep_goodguys_melee_upgraded",
      "npc_dota_creep_goodguys_melee_upgraded_mega",
      "npc_dota_goodguys_siege",
      "npc_dota_goodguys_siege_upgraded",
      "npc_dota_goodguys_siege_upgraded_mega",
      "npc_dota_badguys_siege",
      "npc_dota_badguys_siege_upgraded",
      "npc_dota_badguys_siege_upgraded_mega",
	}

    for _, v in pairs(lane_creep_names) do
      if unit_name == v then
        return true
      end
    end

    return false
  end
end
