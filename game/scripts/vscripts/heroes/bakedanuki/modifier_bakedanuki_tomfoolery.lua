modifier_bakedanuki_tomfoolery = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_bakedanuki_tomfoolery:IsHidden()
	return true
end

function modifier_bakedanuki_tomfoolery:IsPurgable()
	return false
end

function modifier_bakedanuki_tomfoolery:DestroyOnExpire()
	return false
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_bakedanuki_tomfoolery:OnCreated( kv )
	-- references
	self.illusion_incoming = self:GetAbility():GetSpecialValueFor( "illusion_incoming" )
	self.illusion_outgoing = self:GetAbility():GetSpecialValueFor( "illusion_outgoing" )

	-- Start interval
	if IsServer() then
		self:StartIntervalThink( kv.duration )
	end
end

function modifier_bakedanuki_tomfoolery:OnRefresh( kv )
	
end

function modifier_bakedanuki_tomfoolery:OnDestroy()

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_bakedanuki_tomfoolery:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION,
		-- MODIFIER_PROPERTY_INCOMING_DAMAGE_ILLUSION,

		-- MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,

		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
	}

	return funcs
end

function modifier_bakedanuki_tomfoolery:GetModifierDamageOutgoing_Percentage_Illusion()
-- function modifier_bakedanuki_tomfoolery:GetModifierDamageOutgoing_Percentage()
	return self.illusion_outgoing-100
end

-- function modifier_bakedanuki_tomfoolery:GetModifierIncomingDamage_Percentage_Illusion()
function modifier_bakedanuki_tomfoolery:GetModifierIncomingDamage_Percentage()
	return self.illusion_incoming-100
end

function modifier_bakedanuki_tomfoolery:OnAbilityFullyCast( params )
	if IsServer() then
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
end

function modifier_bakedanuki_tomfoolery:GetMinHealth()
	return 1
end
if IsServer() then
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

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_bakedanuki_tomfoolery:OnIntervalThink()
	self:GetAbility():StopTrick()
end
