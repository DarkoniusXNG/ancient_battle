if modifier_pulverize_cleave == nil then
	modifier_pulverize_cleave = class({})
end

function modifier_pulverize_cleave:IsHidden()
	return true
end

function modifier_pulverize_cleave:IsPurgable()
	return false
end

function modifier_pulverize_cleave:IsDebuff()
	return false
end

function modifier_pulverize_cleave:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_pulverize_cleave:AllowIllusionDuplicate()
	return false -- this does nothing apparently
end

function modifier_pulverize_cleave:OnCreated()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.cleave_chance = ability:GetSpecialValueFor("cleave_chance")
		self.cleave_damage_percent = ability:GetSpecialValueFor("cleave_damage")
		self.cleave_start_radius = ability:GetSpecialValueFor("cleave_start_radius")
		self.cleave_distance = ability:GetSpecialValueFor("cleave_distance")
		self.cleave_end_radius = ability:GetSpecialValueFor("cleave_end_radius")
	end
end

modifier_pulverize_cleave.OnRefresh = modifier_pulverize_cleave.OnCreated

function modifier_pulverize_cleave:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then	
	function modifier_pulverize_cleave:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		if parent == event.attacker then
			-- If break is applied don't do anything
			if parent:PassivesDisabled() then
				return
			end

			local target = event.target
			
			-- To prevent crashes:
			if not target or target:IsNull() then
				return
			end

			-- Prevent building up the proc chance (or crashing) when attacking items
			if target.GetUnitName == nil then
				return
			end

			-- Prevent building up the proc chance on buildings, wards and allies
			if target:GetTeamNumber() == parent:GetTeamNumber() or target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
				return
			end

			if not ability or ability:IsNull() then
				return
			end
			
			if not ability:XNGRandom(self.cleave_chance) then
				return
			end

			local cleave_origin = parent:GetAbsOrigin()
			local start_radius = self.cleave_start_radius
			local end_radius = self.cleave_end_radius
			local distance = self.cleave_distance
			local particle_cleave = "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave.vpcf"

			local main_damage
			local damage_percent

			if parent:IsIllusion() then
				main_damage = 0
				damage_percent = 0
			else
				main_damage = event.damage
				damage_percent = self.cleave_damage_percent
			end

			CustomCleaveAttack(parent, target, ability, main_damage, damage_percent, cleave_origin, start_radius, end_radius, distance, particle_cleave)

			-- Sound from caster (parent)
			parent:EmitSound("Hero_Spirit_Breaker.GreaterBash")
		end
	end
end
