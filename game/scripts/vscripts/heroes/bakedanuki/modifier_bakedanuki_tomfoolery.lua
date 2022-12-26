modifier_bakedanuki_tomfoolery = class({})

function modifier_bakedanuki_tomfoolery:IsHidden()
	return true
end

function modifier_bakedanuki_tomfoolery:IsPurgable()
	return false
end

function modifier_bakedanuki_tomfoolery:DestroyOnExpire()
	return false
end

function modifier_bakedanuki_tomfoolery:OnCreated( kv )
	self:OnRefresh(kv)

	-- Start interval
	if IsServer() then
		self:StartIntervalThink( kv.duration )
	end
end

function modifier_bakedanuki_tomfoolery:OnRefresh( kv )
	self.illusion_incoming = self:GetAbility():GetSpecialValueFor("illusion_incoming")
	self.illusion_outgoing = self:GetAbility():GetSpecialValueFor("illusion_outgoing")
end

function modifier_bakedanuki_tomfoolery:DeclareFunctions()
	return {
		-- MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION,    -- GetModifierDamageOutgoing_Percentage_Illusion
		-- MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,             -- GetModifierDamageOutgoing_Percentage
		MODIFIER_PROPERTY_BONUSDAMAGEOUTGOING_PERCENTAGE,           -- GetModifierBonusDamageOutgoing_Percentage
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,            -- GetModifierBaseDamageOutgoing_Percentage
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

--function modifier_bakedanuki_tomfoolery:GetModifierDamageOutgoing_Percentage_Illusion()
	--return self.illusion_outgoing-100
--end

--function modifier_bakedanuki_tomfoolery:GetModifierDamageOutgoing_Percentage()
	--return self.illusion_outgoing-100
--end

function modifier_bakedanuki_tomfoolery:GetModifierBonusDamageOutgoing_Percentage()
	return -100
end

function modifier_bakedanuki_tomfoolery:GetModifierBaseDamageOutgoing_Percentage()
	return self.illusion_outgoing
end

function modifier_bakedanuki_tomfoolery:GetModifierIncomingDamage_Percentage()
	return self.illusion_incoming-100
end

if IsServer() then
	function modifier_bakedanuki_tomfoolery:OnAbilityFullyCast( params )
		-- filter
		local pass = false
		if params.unit==self:GetCaster() then
			if params.ability~=self:GetAbility().tomfoolery.ability1 and params.ability~=self:GetAbility().tomfoolery.ability2 then
				pass = true
			end
		end

		-- logic
		if pass then
			self:GetAbility():StopTrick()
		end
	end

	function modifier_bakedanuki_tomfoolery:GetMinHealth()
		return 1
	end

	function modifier_bakedanuki_tomfoolery:OnTakeDamage( params )
		-- filter
		local pass = false
		if params.unit==self:GetCaster() then
			pass = true
		end

		-- logic
		if pass then
			if self:GetParent():GetHealth()<=2 then
				self:GetAbility():StopTrick()
			end
		end
	end

	function modifier_bakedanuki_tomfoolery:OnDeath( params )
		local ability = self:GetAbility()
		-- filter
		local pass = false
		if params.unit == ability.tomfoolery.illusion then
			pass = true
		end

		-- logic
		if pass then
			self:GetAbility():StopTrick()
		end
	end
end

function modifier_bakedanuki_tomfoolery:OnIntervalThink()
	self:GetAbility():StopTrick()
end
