-- Extension functions for CDOTA_BaseNPC
-- This file is also loaded on client

-- On Server:
if CDOTA_BaseNPC then
  if not CDOTA_BaseNPC.GetAttackRange then
    function CDOTA_BaseNPC:GetAttackRange()
      return self:Script_GetAttackRange()
    end
  end

  if not CDOTA_BaseNPC.ReduceMana then
    function CDOTA_BaseNPC:ReduceMana(amount, mana_burning_ability)
      return self:Script_ReduceMana(amount, mana_burning_ability)
    end
  end

  if not CDOTA_BaseNPC.GetMagicalArmorValue then
    function CDOTA_BaseNPC:GetMagicalArmorValue()
      local experimental_formula = false
      local inflictor = nil
      return self:Script_GetMagicalArmorValue(experimental_formula, inflictor)
    end
  end

  function CDOTA_BaseNPC:HasShardCustom()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function CDOTA_BaseNPC:IsStrongIllusionCustom()
    return self:HasModifier("modifier_chaos_knight_phantasm_illusion") or self:IsStrongIllusion()
  end

  function CDOTA_BaseNPC:IsCloneCustom()
    return self.original or self:IsClone()
  end

  function CDOTA_BaseNPC:IsHeroDominatedCustom()
    return self:HasModifier("modifier_charmed_hero")
  end

  function CDOTA_BaseNPC:IsCustomWardTypeUnit()
    local names = {
      "npc_dota_custom_death_ward",
      "npc_dota_custom_dummy_unit",
      "npc_dota_custom_electric_trap",
      "npc_dota_custom_phoenix_egg",
      "npc_dota_firelord_volcano",
      "npc_dota_techies_custom_land_mine_moving",
      "npc_dota_techies_custom_remote_mine",
      "npc_dota_techies_custom_remote_mine_moving",
      "npc_dota_techies_custom_stasis_trap_moving",
      "npc_dota_techies_land_mine",
      "npc_dota_techies_stasis_trap",
    }
    for _, v in pairs(names) do
      if self:GetUnitName() == v then
        return true
      end
    end
    return false
  end

  function CDOTA_BaseNPC:IsRoshanCustom()
    if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
      return true
    end

    return false
  end

  -- caster is needed for debuff amplification (bosses and creeps dont have that for now)
  -- ability is needed to check if it's an item (because Nether Core does not affect items)
  -- if it's a passive without a cooldown (because Nether Core does not affect those)
  function CDOTA_BaseNPC:GetValueChangedByStatusResistance(value, caster, ability)
    if self and value then
      local status_resist = self:GetStatusResistance()
      local other_debuff_duration_decrease = 0
      local debuff_amplifications = 0
      local isItem = false
      local isPassive = false
      local hasCooldown = true
      if ability and not ability:IsNull() then
        isItem = ability:IsItem()
        isPassive = ability:IsPassive()
        hasCooldown = ability:GetCooldown(-1) ~= 0
      end
      if caster and not caster:IsNull() then
        local ursa_debuff_amp = caster:FindAbilityByName("ursa_bear_down")
        local lion_debuff_amp = caster:HasModifier("modifier_lion_to_hell_and_back_buff")
        local bristle_debuff_amp = caster:FindAbilityByName("bristleback_prickly")
        local rubick_debuff_amp = caster:FindAbilityByName("rubick_curiosity")
        local timeless_debuff_amp = caster:HasModifier("modifier_item_enhancement_timeless")
        if ursa_debuff_amp and not ursa_debuff_amp:IsNull() then
          if ursa_debuff_amp:GetLevel() > 0 then
            local bear_down_debuff_amp = ursa_debuff_amp:GetSpecialValueFor("debuff_amp")
            debuff_amplifications = (1 + debuff_amplifications) * (1 + bear_down_debuff_amp / 100) - 1
          end
        end
        if lion_debuff_amp then
          local to_hell_and_back_mod = caster:FindModifierByNameAndCaster("modifier_lion_to_hell_and_back_buff", caster)
          if to_hell_and_back_mod then
            local to_hell_and_back_ability = to_hell_and_back_mod:GetAbility()
            if to_hell_and_back_ability and not to_hell_and_back_ability:IsNull() then
              if to_hell_and_back_ability:GetLevel() > 0 then
                local to_hell_and_back_debuff_amp = to_hell_and_back_ability:GetSpecialValueFor("debuff_amp")
                debuff_amplifications = (1 + debuff_amplifications) * (1 + to_hell_and_back_debuff_amp / 100) - 1
              end
            end
          end
        end
        if bristle_debuff_amp and not bristle_debuff_amp:IsNull() then
          if bristle_debuff_amp:GetLevel() > 0 then
            local prickly_debuff_amp = bristle_debuff_amp:GetSpecialValueFor("amp_pct")
            local angle = bristle_debuff_amp:GetSpecialValueFor("angle")
            -- The y value of the angles vector contains the angle we actually want: where units are directionally facing in the world.
            local bristle_angle = caster:GetAnglesAsVector().y
            local origin_difference = caster:GetAbsOrigin() - self:GetAbsOrigin()
            -- Get the radian of the origin difference between the victim and Bristleback. We use this to figure out at what angle the victim is at relative to Bristleback.
            local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
            -- Convert the radian to degrees.
            origin_difference_radian = origin_difference_radian * 180
            local victim_angle = origin_difference_radian / math.pi
            victim_angle = victim_angle + 180.0
            -- Finally, get the angle at which Bristleback is facing the attacker.
            local result_angle = victim_angle - bristle_angle
            result_angle = math.abs(result_angle)
            if result_angle >= (180 - (angle / 2)) and result_angle <= (180 + (angle / 2)) then
              debuff_amplifications = (1 + debuff_amplifications) * (1 + prickly_debuff_amp / 100) - 1
            end
          end
        end
        if rubick_debuff_amp and not rubick_debuff_amp:IsNull() then
          if rubick_debuff_amp:GetLevel() > 0 then
            local base_curiosity_debuff_amp = rubick_debuff_amp:GetSpecialValueFor("curiosity_modifier_amp")
            local curiosity_factor = rubick_debuff_amp:GetSpecialValueFor("curiosity_factor")
            local hero_lvl = caster:GetLevel()
            local curiosity_from_spell_casts = caster:FindModifierByName("modifier_rubick_curiosity")
            local curiosity_from_kills = caster:FindModifierByName("modifier_rubick_curiosity_from_heroes_tracker")
            local total_curiosity = hero_lvl
            if curiosity_from_spell_casts then
              total_curiosity = total_curiosity + curiosity_from_spell_casts:GetStackCount()
            end
            if curiosity_from_kills then
              total_curiosity = total_curiosity + curiosity_from_kills:GetStackCount()
            end
            -- Calculating total curiosity debuff amp
            local curiosity_debuff_amp
            if curiosity_factor ~= 0 then
              curiosity_debuff_amp = total_curiosity * base_curiosity_debuff_amp * curiosity_factor
            else
              curiosity_debuff_amp = total_curiosity * base_curiosity_debuff_amp
            end
            debuff_amplifications = (1 + debuff_amplifications) * (1 + curiosity_debuff_amp / 100) - 1
          end
        end
        if timeless_debuff_amp then
          local timeless_mod = caster:FindModifierByNameAndCaster("modifier_item_enhancement_timeless", caster)
          if timeless_mod then
            local timeless_item = timeless_mod:GetAbility()
            if timeless_item and not timeless_item:IsNull() then
              local timeless_amp = timeless_item:GetSpecialValueFor("debuff_amp")
              debuff_amplifications = (1 + debuff_amplifications) * (1 + timeless_amp / 100) - 1
            end
          end
        end
      end

      -- Capping max status resistance
      local new_value = value * (1 - status_resist) * (1 - other_debuff_duration_decrease) * (1 + debuff_amplifications)
      if new_value <= 0.01 or status_resist >= 1 or other_debuff_duration_decrease >= 1 or debuff_amplifications < 0 then
        return value*0.01
      end

      return new_value
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
      "modifier_astral_trekker_entrapment_debuff",
      "modifier_incinerate_stack",
      "modifier_mana_transfer_leash_debuff",
      "modifier_purge_enemy_creep",
      "modifier_purge_enemy_hero",
      "modifier_stealth_assassin_ambush_mini_stun",
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
    local normal_leashes = {
      --"modifier_furion_sprout_tether",                            -- not in the game anymore
      --"modifier_enigma_black_hole_pull",                          -- primarily a stun
      --"modifier_faceless_void_chronosphere_freeze",               -- primarily a stun
      "modifier_grimstroke_soul_chain",
      --"modifier_legion_commander_duel",                           -- primarily a taunt
      "modifier_puck_coiled",
      "modifier_slark_pounce_leash",
      "modifier_tidehunter_dead_in_the_water",
      -- custom leash modifiers:
      "modifier_custom_leash_debuff",
      "modifier_mana_transfer_leash_debuff",
    }

    -- Check for Leash immunities first (Sonic for example)
    if self:HasModifier("modifier_item_sonic_active") then
      return false
    end

    -- Debuff Immunity interactions
    if self:IsDebuffImmune() then
      -- Grimstroke ult always pierces debuff immunity
      if self:HasModifier("modifier_grimstroke_soul_chain") then
        return true
      end

      -- Puck Dream Coil pierce debuff immunity with the talent
      local dream_coil_mod = self:FindModifierByName("modifier_puck_coiled")
      if dream_coil_mod then
        local dream_coil_ab = dream_coil_mod:GetAbility()
        --local caster = dream_coil_mod:GetCaster()
        if dream_coil_ab then
          local pierce = dream_coil_ab:GetSpecialValueFor("pierces_debuff_immunity") == 1
          --if caster then
            --local talent = caster:FindAbilityByName("special_bonus_unique_puck_5")
            --if talent and talent:GetLevel() > 0 then
          if pierce then
            return true
          end
        end
      end

      return false
    end

    for _, v in pairs(normal_leashes) do
      if self:HasModifier(v) then
        return true
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
      "npc_dota_creep_badguys_flagbearer",
      "npc_dota_creep_badguys_flagbearer_upgraded",
      "npc_dota_creep_badguys_flagbearer_upgraded_mega",
      "npc_dota_creep_goodguys_melee",
      "npc_dota_creep_goodguys_melee_upgraded",
      "npc_dota_creep_goodguys_melee_upgraded_mega",
      "npc_dota_creep_goodguys_flagbearer",
      "npc_dota_creep_goodguys_flagbearer_upgraded",
      "npc_dota_creep_goodguys_flagbearer_upgraded_mega",
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

  -- Apply a modifier only if it's not from the same source ability otherwise just refresh
  function CDOTA_BaseNPC:ApplyNonStackableBuff(caster, ability, mod_name, duration)
    if not ability then
      return
    end
    local applied_by_this_ability = false
    local ability_name = ability:GetAbilityName()
    local mods = self:FindAllModifiersByName(mod_name)
    for _, mod in pairs(mods) do
      if mod and not mod:IsNull() then
        local mod_ability = mod:GetAbility()
        if mod_ability then
          local mod_ability_name = mod_ability:GetAbilityName()
          if string.find(mod_ability_name, string.sub(ability_name, 0, string.len(ability_name)-4)) then
            applied_by_this_ability = true
            mod:ForceRefresh()
            break
          end
        end
      end
    end
    if not applied_by_this_ability then
      return self:AddNewModifier(caster, ability, mod_name, {duration = duration})
    end
  end

  function GetValueChangedByBuffAmplification(value, victim, caster)
    if victim and value then
      local buff_amplifications = 0
      if caster and not caster:IsNull() then
        local largo_buff_amp = caster:FindAbilityByName("largo_encore")
        local rubick_buff_amp = caster:FindAbilityByName("rubick_curiosity")
        if largo_buff_amp and not largo_buff_amp:IsNull() then
          if largo_buff_amp:GetLevel() > 0 then
            local largo_encore_buff_amp = largo_buff_amp:GetSpecialValueFor("buff_amplification")
              buff_amplifications = (1 + buff_amplifications) * (1 + largo_encore_buff_amp / 100) - 1
            end
          end
        if rubick_buff_amp and not rubick_buff_amp:IsNull() then
          if rubick_buff_amp:GetLevel() > 0 then
            local base_curiosity_buff_amp = rubick_buff_amp:GetSpecialValueFor("curiosity_modifier_amp")
            local curiosity_factor = rubick_buff_amp:GetSpecialValueFor("curiosity_factor")
            local hero_lvl = caster:GetLevel()
            local curiosity_from_spell_casts = caster:FindModifierByName("modifier_rubick_curiosity")
            local curiosity_from_kills = caster:FindModifierByName("modifier_rubick_curiosity_from_heroes_tracker")
            local total_curiosity = hero_lvl
            if curiosity_from_spell_casts then
              total_curiosity = total_curiosity + curiosity_from_spell_casts:GetStackCount()
            end
            if curiosity_from_kills then
              total_curiosity = total_curiosity + curiosity_from_kills:GetStackCount()
            end
            -- Calculating total curiosity buff amp
            local curiosity_buff_amp
            if curiosity_factor ~= 0 then
              curiosity_buff_amp = total_curiosity * base_curiosity_buff_amp * curiosity_factor
            else
              curiosity_buff_amp = total_curiosity * base_curiosity_buff_amp
            end
            buff_amplifications = (1 + buff_amplifications) * (1 + curiosity_buff_amp / 100) - 1
          end
        end
      end

      local new_value = value * (1 + buff_amplifications)
      if buff_amplifications <= -1 then
        return value
      end

      return new_value
    end
  end

  function CDOTA_BaseNPC:GetValueChangedByKnockbackResistance(value)
    if self and value then
      local total_knockback_resistance = 0
      local solid_core = self:FindAbilityByName("magnataur_solid_core")
      local gyro_scope = self:FindAbilityByName("gyrocopter_innate_oaa")
      local tough_mod = self:FindModifierByNameAndCaster("modifier_item_enhancement_tough", self)
      if solid_core and not solid_core:IsNull() then
        if solid_core:GetLevel() > 0 then
          local knockback_resist = solid_core:GetSpecialValueFor("knockback_reduction")
          total_knockback_resistance = 1 - (1 - knockback_resist / 100) * (1 - total_knockback_resistance)
        end
      end
      if gyro_scope and not gyro_scope:IsNull() then
        if gyro_scope:GetLevel() > 0 then
          local knockback_resist = gyro_scope:GetSpecialValueFor("knockback_reduction")
          total_knockback_resistance = 1 - (1 - knockback_resist / 100) * (1 - total_knockback_resistance)
        end
      end
      if tough_mod and not tough_mod:IsNull() then
        local tough_enchantment = tough_mod:GetAbility()
        if tough_enchantment and not tough_enchantment:IsNull() then
          local knockback_resist = tough_enchantment:GetSpecialValueFor("knockback_resist")
          total_knockback_resistance = 1 - (1 - knockback_resist / 100) * (1 - total_knockback_resistance)
        end
      end
      local new_value = value * (1 - total_knockback_resistance)
      return new_value
    end
  end
end

-- On Client:
if C_DOTA_BaseNPC then
  if not C_DOTA_BaseNPC.GetAttackRange then
    function C_DOTA_BaseNPC:GetAttackRange()
      return self:Script_GetAttackRange()
    end
  end

  if not C_DOTA_BaseNPC.ReduceMana then
    function C_DOTA_BaseNPC:ReduceMana(amount, mana_burning_ability)
      return self:Script_ReduceMana(amount, mana_burning_ability)
    end
  end

  if not C_DOTA_BaseNPC.GetMagicalArmorValue then
    function C_DOTA_BaseNPC:GetMagicalArmorValue()
      local experimental_formula = false
      local inflictor = nil
      return self:Script_GetMagicalArmorValue(experimental_formula, inflictor)
    end
  end

  function C_DOTA_BaseNPC:HasShardCustom()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function C_DOTA_BaseNPC:IsStrongIllusionCustom()
    return self:HasModifier("modifier_chaos_knight_phantasm_illusion") or self:IsStrongIllusion()
  end

  --function C_DOTA_BaseNPC:IsCloneCustom()
    --return self.original or self:IsClone()
  --end

  function C_DOTA_BaseNPC:IsHeroDominatedCustom()
    return self:HasModifier("modifier_charmed_hero")
  end

  function C_DOTA_BaseNPC:IsCustomWardTypeUnit()
    local names = {
      "npc_dota_custom_death_ward",
      "npc_dota_custom_dummy_unit",
      "npc_dota_custom_electric_trap",
      "npc_dota_custom_phoenix_egg",
      "npc_dota_firelord_volcano",
      "npc_dota_techies_custom_land_mine_moving",
      "npc_dota_techies_custom_remote_mine",
      "npc_dota_techies_custom_remote_mine_moving",
      "npc_dota_techies_custom_stasis_trap_moving",
      "npc_dota_techies_land_mine",
      "npc_dota_techies_stasis_trap",
    }
    for _, v in pairs(names) do
      if self:GetUnitName() == v then
        return true
      end
    end
    return false
  end

  function C_DOTA_BaseNPC:IsRoshanCustom()
    if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
      return true
    end

    return false
  end

  function C_DOTA_BaseNPC:IsLeashedCustom()
    local normal_leashes = {
      --"modifier_furion_sprout_tether",                            -- not in the game anymore
      --"modifier_enigma_black_hole_pull",                          -- primarily a stun
      --"modifier_faceless_void_chronosphere_freeze",               -- primarily a stun
      "modifier_grimstroke_soul_chain",
      --"modifier_legion_commander_duel",                           -- primarily a taunt
      "modifier_puck_coiled",
      "modifier_slark_pounce_leash",
      "modifier_tidehunter_dead_in_the_water",
      -- custom leash modifiers:
      "modifier_custom_leash_debuff",
      "modifier_mana_transfer_leash_debuff",
    }

    -- Check for Leash immunities first (Sonic for example)
    if self:HasModifier("modifier_item_sonic_active") then
      return false
    end

    -- Debuff Immunity interactions
    if self:IsDebuffImmune() then
      -- Grimstroke ult always pierces debuff immunity
      if self:HasModifier("modifier_grimstroke_soul_chain") then
        return true
      end

      -- FindModifierByName is not available on the client so can't check for other stuff

      return false
    end

    for _, v in pairs(normal_leashes) do
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
      "npc_dota_creep_badguys_flagbearer",
      "npc_dota_creep_badguys_flagbearer_upgraded",
      "npc_dota_creep_badguys_flagbearer_upgraded_mega",
      "npc_dota_creep_goodguys_melee",
      "npc_dota_creep_goodguys_melee_upgraded",
      "npc_dota_creep_goodguys_melee_upgraded_mega",
      "npc_dota_creep_goodguys_flagbearer",
      "npc_dota_creep_goodguys_flagbearer_upgraded",
      "npc_dota_creep_goodguys_flagbearer_upgraded_mega",
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
