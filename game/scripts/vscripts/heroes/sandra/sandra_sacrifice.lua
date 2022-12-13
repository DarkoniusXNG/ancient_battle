sandra_sacrifice = class({})

LinkLuaModifier( "modifier_sandra_sacrifice", "heroes/sandra/modifier_sandra_sacrifice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_sacrifice_master", "heroes/sandra/modifier_sandra_sacrifice_master", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_sacrifice_pull", "heroes/sandra/modifier_sandra_sacrifice_pull", LUA_MODIFIER_MOTION_HORIZONTAL )

local tempTable = {}
tempTable.table = {}

function tempTable:GetATEmptyKey()
	local i = 1
	while self.table[i]~=nil do
		i = i+1
	end
	return i
end

function tempTable:AddATValue( value )
	local i = self:GetATEmptyKey()
	self.table[i] = value
	return i
end

function tempTable:RetATValue( key )
	local ret = self.table[key]
	self.table[key] = nil
	return ret
end

function tempTable:GetATValue( key )
	return self.table[key]
end

function tempTable:Print()
	for k,v in pairs(self.table) do
		print(k,v)
	end
end

--------------------------------------------------------------------------------
-- Ability Cast Filter
function sandra_sacrifice:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		0,
		self:GetCaster():GetTeamNumber()
	)
	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function sandra_sacrifice:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return ""
end

function sandra_sacrifice:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetSpecialValueFor("leash_duration")

	-- destroy previous cast
	local modifier = caster:FindModifierByNameAndCaster( "modifier_sandra_sacrifice", caster )
	if modifier then
		modifier:Destroy()
	end

	-- add slave modifier
	local master = tempTable:AddATValue( target )
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_sandra_sacrifice", -- modifier name
		{
			duration = duration,
			master = master,
		} -- kv
	)
end
