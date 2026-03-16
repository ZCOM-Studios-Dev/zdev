local _f = 'entities/zdev_snpc_test/init.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - Test NPC (Server)
----------------------------------------------------------
	A Citizen NPC that searches for chairs to sit in
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:Initialize()
	-- Set random citizen model
	local model = self.CitizenModels[math.random(#self.CitizenModels)]
	self:SetModel(model)
	
	-- Setup NPC
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_IDLE)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(CAP_MOVE_GROUND + CAP_OPEN_DOORS + CAP_TURN_HEAD + CAP_ANIMATEDFACE)
	self:SetUseType(SIMPLE_USE)
	self:DropToFloor()
	
	-- Set health
	self:SetHealth(self.StartHealth)
	self:SetMaxHealth(self.MaxHealthValue)
	
	-- Friendly to players
	self:AddRelationship('player D_LI 99')

	-- Initialize behavior state (not NPC_STATE, our custom state)
	self:SetBehaviorState(self.STATE_IDLE)
	self:SetIsSitting(false)
	
	-- Timing
	self.NextThinkTime = 0
	self.NextSearchTime = 0
	self.SitEndTime = 0
	self.LookEndTime = 0
	self.WanderTarget = nil
	
	-- Start searching after short delay
	timer.Simple(1, function()
		if IsValid(self) then
			self:StartSearching()
		end
	end)
end

function ENT:Think()
	if CurTime() < self.NextThinkTime then
		self:NextThink(CurTime() + 0.1)
		return true
	end
	--self.NextThinkTime = CurTime() + 0.5
	
	local state = self:GetBehaviorState()
	
	if state == self.STATE_SEARCHING then
		self:DoSearch()
	elseif state == self.STATE_WALKING_TO_CHAIR then
		self:DoWalkToChair()
	elseif state == self.STATE_SITTING then
		self:DoSitting()
	elseif state == self.STATE_WANDERING then
		self:DoWander()
	elseif state == self.STATE_LOOKING_AROUND then
		self:DoLookAround()
	elseif state == self.STATE_IDLE then
		self:StartSearching()
	end
	
	--self:NextThink(CurTime() + 0.5)
	return true
end

function ENT:StartSearching()
	self:SetBehaviorState(self.STATE_SEARCHING)
	self.NextSearchTime = CurTime()
end

function ENT:DoSearch()
	if CurTime() < self.NextSearchTime then return end
	self.NextSearchTime = CurTime() + 2
	
	local chair = self:FindNearestChair()
	
	if IsValid(chair) then
		-- Found a chair!
		self:SetTargetChair(chair)
		self:SetBehaviorState(self.STATE_WALKING_TO_CHAIR)
		self:EmitSound(self.Sounds.FoundChair)
		self:SetLastPosition(self:GetChairSitPos(chair))
		self:SetSchedule(SCHED_FORCED_GO)
	else
		-- No chair found, wander and look
		self:StartWandering()
	end
end

function ENT:FindNearestChair()
	local myPos = self:GetPos()
	local nearestChair = nil
	local nearestDist = self.SearchRadius
	
	for _, ent in ipairs(ents.FindInSphere(myPos, self.SearchRadius)) do
		if self:IsChair(ent) and self:CanSitInChair(ent) then
			local dist = myPos:Distance(ent:GetPos())
			if dist < nearestDist then
				nearestDist = dist
				nearestChair = ent
			end
		end
	end
	
	return nearestChair
end

function ENT:IsChair(ent)
	if not IsValid(ent) then return false end
	
	local model = ent:GetModel()
	if not model then return false end
	model = string.lower(model)
	
	for _, pattern in ipairs(self.ChairPatterns) do
		if string.find(model, pattern) then
			return true
		end
	end
	
	-- Also check entity class for prop_physics chairs
	local class = ent:GetClass()
	if class == 'prop_vehicle_prisoner_pod' then return true end
	
	return false
end

function ENT:CanSitInChair(chair)
	if not IsValid(chair) then return false end
	
	-- Check line of sight
	local tr = util.TraceLine({
		start = self:GetPos() + Vector(0, 0, 40),
		endpos = chair:GetPos() + Vector(0, 0, 20),
		filter = self
	})
	
	if tr.Entity ~= chair and tr.Hit then return false end
	
	-- Check if chair is occupied (simple check)
	for _, npc in ipairs(ents.FindByClass('zdev_snpc_test')) do
		if npc ~= self and IsValid(npc:GetTargetChair()) then
			if npc:GetTargetChair() == chair and npc:GetIsSitting() then
				return false
			end
		end
	end
	
	return true
end

function ENT:GetChairSitPos(chair)
	if not IsValid(chair) then return self:GetPos() end
	return chair:GetPos() + chair:GetForward() * 30
end

function ENT:DoWalkToChair()
	local chair = self:GetTargetChair()

	if not IsValid(chair) then
		self:StartSearching()
		return
	end

	local dist = self:GetPos():Distance(chair:GetPos())

	if dist < 60 then
		-- Arrived at chair, sit down
		self:SitInChair(chair)
	elseif dist > self.SearchRadius then
		-- Chair too far, search again
		self:SetTargetChair(NULL)
		self:StartSearching()
	end
end

function ENT:SitInChair(chair)
	if not IsValid(chair) then return end

	self:SetBehaviorState(self.STATE_SITTING)
	self:SetIsSitting(true)
	self.SitEndTime = CurTime() + self.SitDuration

	-- Position NPC at chair
	local sitPos = chair:GetPos() + Vector(0, 0, 20)
	local sitAng = chair:GetAngles()

	self:SetPos(sitPos)
	self:SetAngles(Angle(0, sitAng.y + 180, 0))

	-- Play sitting animation
	self:SetSequence(self:LookupSequence('sitchair1'))

	-- Disable movement
	self:SetMoveType(MOVETYPE_NONE)

	self:EmitSound(self.Sounds.Sitting)
end

function ENT:DoSitting()
	if CurTime() > self.SitEndTime then
		self:StandUp()
	end
end

function ENT:StandUp()
	self:SetIsSitting(false)
	self:SetTargetChair(NULL)
	self:SetMoveType(MOVETYPE_STEP)

	-- Move away from chair slightly
	local moveDir = self:GetForward() * 50
	self:SetPos(self:GetPos() + moveDir)

	-- Return to searching
	self:StartWandering()
end

function ENT:StartWandering()
	self:SetBehaviorState(self.STATE_WANDERING)

	-- Pick random wander point
	local wanderPos = self:GetPos() + VectorRand() * self.WanderRadius
	wanderPos.z = self:GetPos().z

	-- Validate position with trace
	local tr = util.TraceLine({
		start = wanderPos + Vector(0, 0, 50),
		endpos = wanderPos - Vector(0, 0, 100),
		mask = MASK_NPCSOLID
	})

	if tr.Hit then
		wanderPos = tr.HitPos + Vector(0, 0, 5)
	end

	self.WanderTarget = wanderPos
	self:SetLastPosition(wanderPos)
	self:SetSchedule(SCHED_FORCED_GO)

	self:EmitSound(self.Sounds.Searching)
end

function ENT:DoWander()
	if not self.WanderTarget then
		self:StartLookingAround()
		return
	end

	local dist = self:GetPos():Distance(self.WanderTarget)

	if dist < 50 then
		self.WanderTarget = nil
		self:StartLookingAround()
	end
end

function ENT:StartLookingAround()
	self:SetBehaviorState(self.STATE_LOOKING_AROUND)
	self.LookEndTime = CurTime() + self.LookAroundTime
end

function ENT:DoLookAround()
	-- Turn head to look around
	local lookAngle = CurTime() * 60
	local lookDir = Vector(math.cos(math.rad(lookAngle)), math.sin(math.rad(lookAngle)), 0)
	self:SetEyeTarget(self:GetPos() + lookDir * 200 + Vector(0, 0, 50))

	if CurTime() > self.LookEndTime then
		-- Done looking, search for chairs again
		self:StartSearching()
	end
end

function ENT:OnTakeDamage(dmg)
	self:SetHealth(self:Health() - dmg:GetDamage())

	-- Stand up if sitting
	if self:GetIsSitting() then
		self:StandUp()
	end

	if self:Health() <= 0 then
		self:OnKilled(dmg)
	end
end

function ENT:OnKilled(dmg)
	self:EmitSound('vo/npc/male01/no02.wav')
	self:BecomeRagdoll(dmg)
end

function ENT:AcceptInput(name, activator, caller, data)
	if name == 'Use' and IsValid(activator) and activator:IsPlayer() then
		self:OnUse(activator)
		return true
	end
	return false
end

function ENT:OnUse(activator)
	if not IsValid(activator) then return end

	-- Tell player what we're doing
	local state = self:GetStateName()
	activator:ChatPrint('NPC Status: ' .. state)

	if self:GetIsSitting() then
		activator:ChatPrint('Time until standing: ' .. math.Round(self.SitEndTime - CurTime(), 1) .. 's')
	end

	self:EmitSound(self.Sounds.Idle)
end

