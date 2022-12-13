modifier_sandra_sacrifice_pull = class({})

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

function modifier_sandra_sacrifice_pull:IsHidden()
	return false
end

function modifier_sandra_sacrifice_pull:IsDebuff()
	return true
end

function modifier_sandra_sacrifice_pull:IsPurgable()
	return false
end

function modifier_sandra_sacrifice_pull:SetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH
end

function modifier_sandra_sacrifice_pull:OnCreated( kv )
	if IsServer() then
		-- get reference
		self.modifier = tempTable:RetATValue( kv.modifier )
		self.master = self.modifier.master:GetParent()
		self.minimum_radius = self.modifier.buffer_radius

		-- try apply
		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end
	end
end

function modifier_sandra_sacrifice_pull:OnDestroy( kv )
	if IsServer() then
		self.modifier.dragged = false

		self:GetParent():RemoveHorizontalMotionController(self)
	end
end

function modifier_sandra_sacrifice_pull:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_sandra_sacrifice_pull:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_sandra_sacrifice_pull:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_sandra_sacrifice_pull:UpdateHorizontalMotion( me, dt )
	if IsServer() then
		-- get pull direction
		local masterVec = self.master:GetOrigin() - self:GetParent():GetOrigin()
		local direction = masterVec:Normalized()
		local distance = masterVec:Length2D()

		-- pull acceleration and speed
		local accel = 0.1*(distance - self.minimum_radius)/10 + 0.9
		local speed = self.master:GetIdealSpeed()

		-- set next pos
		local nextPos = self:GetParent():GetOrigin() + direction*speed*accel*dt
		self:GetParent():SetOrigin( nextPos )

		-- set facing
		-- this interrupts, therefore unused.
		-- self:GetParent():SetForwardVector(-direction)

		-- if reached minimum, destroy
		if distance < self.minimum_radius then
			self:Destroy()
		end
	end
end

function modifier_sandra_sacrifice_pull:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_sandra_sacrifice_pull:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_sandra_sacrifice_pull:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end