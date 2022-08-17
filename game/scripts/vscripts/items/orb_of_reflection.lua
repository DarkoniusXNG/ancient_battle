item_orb_of_reflection = class({})

LinkLuaModifier("modifier_item_orb_of_reflection_passives", "items/orb_of_reflection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_orb_of_reflection_active_reflect", "items/orb_of_reflection.lua", LUA_MODIFIER_MOTION_NONE)

function item_orb_of_reflection:GetIntrinsicModifierName()
	return "modifier_item_orb_of_reflection_passives"
end

function item_orb_of_reflection:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("DOTA_Item.BladeMail.Activate")
	
	-- Basic Dispel (Removes normal debuffs)
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false

	caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- Get duration
	local buff_duration = self:GetSpecialValueFor("reflect_duration")
	-- Apply modifier
	caster:AddNewModifier(caster, self, "modifier_item_orb_of_reflection_active_reflect", {duration = buff_duration})
	-- Built-in modifier (Lotus Orb Echo Shell)
	caster:AddNewModifier(caster, self, "modifier_item_lotus_orb_active", {duration = buff_duration})
end

---------------------------------------------------------------------------------------------------

modifier_item_orb_of_reflection_passives = class({})

function modifier_item_orb_of_reflection_passives:IsHidden()
	return true
end

function modifier_item_orb_of_reflection_passives:IsDebuff()
	return false
end

function modifier_item_orb_of_reflection_passives:IsPurgable()
	return false
end

function modifier_item_orb_of_reflection_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_orb_of_reflection_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_orb_of_reflection_passives:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_dmg")
end

function modifier_item_orb_of_reflection_passives:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_orb_of_reflection_passives:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_orb_of_reflection_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_orb_of_reflection_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_orb_of_reflection_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_orb_of_reflection_passives:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_orb_of_reflection_passives:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_orb_of_reflection_passives:OnTakeDamage(event)
	local parent = self:GetParent()

	-- Trigger only for this modifier
	if parent ~= event.unit then
		return nil
	end

	-- Don't trigger on illusions
	if parent:IsIllusion() then
		return nil
	end
	
	-- If there is a stronger reflection modifier, don't continue
	if parent:HasModifier("modifier_item_orb_of_reflection_active_reflect") or parent:HasModifier("modifier_item_blade_mail_reflect") then
		return nil
	end
	
	if not IsServer() then
		return nil
	end
	
	if event.original_damage > 0 then
		local damage_flags = event.damage_flags
		local attacker = event.attacker

		-- Don't trigger on damage with these flags
		if HasBit(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then
			return nil
		end

		-- To prevent crashes
		if not attacker then
			return nil
		end

		-- To prevent crashes
		if attacker:IsNull() then
			return nil
		end

		-- Don't trigger on self damage or on damage from allies
		if attacker == parent or attacker:GetTeamNumber() == parent:GetTeamNumber() then
			return nil
		end

		-- Don't trigger if attacker is dead
		if not attacker:IsAlive() then
			return nil
		end

		-- Don't trigger on buildings, towers and fountains
		if attacker:IsBuilding() or attacker:IsTower() or attacker:IsFountain() then
			return nil
		end

		-- Damage before reductions
		local damage = event.original_damage
		local ability = self:GetAbility()

		-- Fetch the damage return amount/percentage
		local damage_return = ability:GetSpecialValueFor("passive_damage_return")

		-- Calculating damage that will be returned to attacker
		local new_damage = damage*damage_return/100

		local damage_table = {}
		damage_table.victim = attacker
		damage_table.attacker = parent
		damage_table.damage_type = event.damage_type -- Same damage type as original damage
		damage_table.ability = ability
		damage_table.damage = new_damage
		damage_table.damage_flags = bit.bor(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

		ApplyDamage(damage_table)
	end
end

---------------------------------------------------------------------------------------------------

modifier_item_orb_of_reflection_active_reflect = class({})

function modifier_item_orb_of_reflection_active_reflect:IsHidden()
	return false
end

function modifier_item_orb_of_reflection_active_reflect:IsDebuff()
	return false
end

function modifier_item_orb_of_reflection_active_reflect:IsPurgable()
	return false
end

function modifier_item_orb_of_reflection_active_reflect:GetEffectName()
	return "particles/items_fx/blademail.vpcf"
end

function modifier_item_orb_of_reflection_active_reflect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW -- follow_origin
end

function modifier_item_orb_of_reflection_active_reflect:GetStatusEffectName()
	return "particles/status_fx/status_effect_blademail.vpcf"
end

function modifier_item_orb_of_reflection_active_reflect:OnCreated()
	local parent = self:GetParent()
	if IsServer() then
		-- If there is a Blade Mail modifier, remove it
		if parent:HasModifier("modifier_item_blade_mail_reflect") then
			parent:RemoveModifierByName("modifier_item_blade_mail_reflect")
		end
	end
	
end

function modifier_item_orb_of_reflection_active_reflect:OnDestroy()
	if IsServer() then	
		self:GetParent():EmitSound("DOTA_Item.BladeMail.Deactivate")
	end
end

function modifier_item_orb_of_reflection_active_reflect:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_orb_of_reflection_active_reflect:OnTakeDamage(event)
	local parent = self:GetParent()

	-- Trigger only for this modifier
	if parent ~= event.unit then
		return nil
	end

	-- Don't trigger on illusions
	if parent:IsIllusion() then
		return nil
	end

	if not IsServer() then
		return nil
	end
	
	-- If there is a Blade Mail modifier, remove it
	if parent:HasModifier("modifier_item_blade_mail_reflect") then
		parent:RemoveModifierByName("modifier_item_blade_mail_reflect")
	end

	if event.original_damage > 0 then
		local damage_flags = event.damage_flags
		local attacker = event.attacker

		-- Don't trigger on damage with these flags
		if HasBit(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then
			return nil
		end

		-- To prevent crashes
		if not attacker then
			return nil
		end

		-- To prevent crashes
		if attacker:IsNull() then
			return nil
		end

		-- Don't trigger on self damage or on damage from allies
		if attacker == parent or attacker:GetTeamNumber() == parent:GetTeamNumber() then
			return nil
		end

		-- Don't trigger if attacker is dead
		if not attacker:IsAlive() then
			return nil
		end

		-- Don't trigger on buildings, towers and fountains
		if attacker:IsBuilding() or attacker:IsTower() or attacker:IsFountain() then
			return nil
		end

		local damage_table = {}
		damage_table.victim = attacker
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_PURE
		damage_table.ability = self:GetAbility()
		damage_table.damage = event.original_damage
		damage_table.damage_flags = bit.bor(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

		ApplyDamage(damage_table)
		
		EmitSoundOnClient("DOTA_Item.BladeMail.Damage", attacker:GetPlayerOwner())
	end
end
