if modifier_client_convars == nil then
	modifier_client_convars = class({})
end

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        SendToConsole("dota_player_add_summoned_to_selection 0")
		--SendToConsole("dota_hud_disable_damage_numbers 1")
		--SendToConsole("dota_hud_healthbar_disable_status_display 0")
    end
end

function modifier_client_convars:IsHidden()
    return true
end

function modifier_client_convars:IsPurgable()
    return false
end

function modifier_client_convars:AllowIllusionDuplicate() 
	return false
end