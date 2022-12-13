modifier_sona_crescendo = class({})

function modifier_sona_crescendo:IsHidden()
	return true
end

function modifier_sona_crescendo:IsDebuff()
	return false
end

function modifier_sona_crescendo:IsPurgable()
	return false
end

function modifier_sona_crescendo:IsAura()
	return not self:GetParent():PassivesDisabled()
end

function modifier_sona_crescendo:GetModifierAura()
	return self.current_aura
end

function modifier_sona_crescendo:GetAuraRadius()
	return self.radius
end

function modifier_sona_crescendo:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_sona_crescendo:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_sona_crescendo:GetAuraDuration()
	return 0.1
end

function modifier_sona_crescendo:OnCreated( kv )
	-- references
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.valor_duration = self:GetAbility():GetSpecialValueFor( "valor_duration" )
	self.celerity_duration = self:GetAbility():GetSpecialValueFor( "celerity_duration" )
	self.perseverance_duration = self:GetAbility():GetSpecialValueFor( "perseverance_duration" )

	self.current_aura = self.aura["sona_hymn_of_valor"]
end

function modifier_sona_crescendo:OnRefresh( kv )
	-- references
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.valor_duration = self:GetAbility():GetSpecialValueFor( "valor_duration" )
	self.celerity_duration = self:GetAbility():GetSpecialValueFor( "celerity_duration" )
	self.perseverance_duration = self:GetAbility():GetSpecialValueFor( "perseverance_duration" )
end

function modifier_sona_crescendo:OnDestroy( kv )

end

function modifier_sona_crescendo:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
	}
end

function modifier_sona_crescendo:OnAbilityFullyCast( params )
	if IsServer() then
		if params.unit~=self:GetParent() or params.ability:IsItem() then return end

		-- set aura
		self.current_aura = self.aura[params.ability:GetAbilityName()] or "modifier_sona_crescendo_valor"
		self.current_attack = self.attack[params.ability:GetAbilityName()] or self.attack["sona_hymn_of_valor"]
	end
end

function modifier_sona_crescendo:GetModifierProcAttack_Feedback( params )
	if IsServer() then
		if params.target:IsMagicImmune() or self:GetParent():PassivesDisabled() then return end
		self:current_attack( params )
	end
end

--------------------------------------------------------------------------------
-- Helper tables
modifier_sona_crescendo.aura = {
	["sona_hymn_of_valor"] = "modifier_sona_crescendo_valor",
	["sona_song_of_celerity"] = "modifier_sona_crescendo_celerity",
	["sona_aria_of_perseverance"] = "modifier_sona_crescendo_perseverance",
}

modifier_sona_crescendo.attack = {}
modifier_sona_crescendo.attack["sona_hymn_of_valor"] = function ( self, params )
	params.target:AddNewModifier(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		self.current_aura .. "_attack", -- modifier name
		{ duration = self.valor_duration } -- kv
	)
end

modifier_sona_crescendo.attack["sona_song_of_celerity"] = function ( self, params )
	params.target:AddNewModifier(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		self.current_aura .. "_attack", -- modifier name
		{ duration = self.celerity_duration } -- kv
	)
end

modifier_sona_crescendo.attack["sona_aria_of_perseverance"] = function ( self, params )
	params.target:AddNewModifier(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		self.current_aura .. "_attack", -- modifier name
		{ duration = self.perseverance_duration } -- kv
	)
end
