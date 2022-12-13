modifier_bakedanuki_futatsuiwas_curse = class({})

function modifier_bakedanuki_futatsuiwas_curse:IsHidden()
	return false
end

function modifier_bakedanuki_futatsuiwas_curse:IsDebuff()
	return true
end

function modifier_bakedanuki_futatsuiwas_curse:IsPurgable()
	return false
end

function modifier_bakedanuki_futatsuiwas_curse:OnCreated()
	-- references
	self.base_speed = self:GetAbility():GetSpecialValueFor( "hex_base_speed" )
	self.model = "models/props_gameplay/frog.vmdl"

	if IsServer() then
		-- play effects
		self:PlayEffects( true )

		local parent = self:GetParent()
		-- instantly destroy illusions (but not strong illusions)
		if parent:IsIllusion() and not parent:IsStrongIllusionCustom() then
			parent:Kill( self:GetAbility(), self:GetCaster() )
		end
	end
end

function modifier_bakedanuki_futatsuiwas_curse:OnRefresh()
	-- references
	self.base_speed = self:GetAbility():GetSpecialValueFor( "hex_base_speed" )
	if IsServer() then
		-- play effects
		self:PlayEffects( true )
	end
end

function modifier_bakedanuki_futatsuiwas_curse:OnRemoved()
	if IsServer() then
		-- play effects
		self:PlayEffects( false )
	end
end

function modifier_bakedanuki_futatsuiwas_curse:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
		MODIFIER_PROPERTY_MODEL_CHANGE,
	}
end

function modifier_bakedanuki_futatsuiwas_curse:GetModifierMoveSpeedOverride()
	return self.base_speed
end

function modifier_bakedanuki_futatsuiwas_curse:GetModifierModelChange()
	return self.model
end

function modifier_bakedanuki_futatsuiwas_curse:CheckState()
	return {
		[MODIFIER_STATE_HEXED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	}
end

function modifier_bakedanuki_futatsuiwas_curse:PlayEffects( bStart )
	local parent = self:GetParent()
	local sound_cast = "Hero_DarkWillow.Ley.Stun"
	local particle_cast = "particles/units/heroes/hero_lion/lion_spell_voodoo.vpcf"

	if not bStart then
		sound_cast = "Hero_DarkWillow.WillOWisp.Damage"
	end

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, parent )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	parent:EmitSound(sound_cast)
end
