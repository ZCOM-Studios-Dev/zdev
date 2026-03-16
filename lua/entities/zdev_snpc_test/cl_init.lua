local _f = 'entities/zdev_snpc_test/cl_init.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - Test NPC (Client)
----------------------------------------------------------
	A Citizen NPC that searches for chairs to sit in
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

include('shared.lua')

local glowMat = Material('sprites/light_glow02_add')

function ENT:Draw()
	self:DrawModel()
	
	-- Draw status indicator
	if LocalPlayer():GetPos():Distance(self:GetPos()) < 500 then
		self:DrawStatusIndicator()
	end
end

function ENT:DrawStatusIndicator()
	local pos = self:GetPos() + Vector(0, 0, 80)
	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)
	
	local state = self:GetBehaviorState()
	local stateName = self:GetStateName()
	local stateColor = self:GetStateColor(state)
	
	cam.Start3D2D(pos, ang, 0.1)
		-- Background
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(-80, -15, 160, 30)
		
		-- State text
		draw.SimpleText(
			stateName,
			'DermaDefaultBold',
			0, 0,
			stateColor,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
		
		-- Chair target indicator
		if self:GetIsSitting() then
			draw.SimpleText(
				'🪑 Relaxing...',
				'DermaDefault',
				0, 20,
				Color(100, 255, 100),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		elseif IsValid(self:GetTargetChair()) then
			draw.SimpleText(
				'→ Chair Found!',
				'DermaDefault',
				0, 20,
				Color(255, 255, 100),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	cam.End3D2D()
	
	-- Glow based on state
	render.SetMaterial(glowMat)
	render.DrawSprite(self:GetPos() + Vector(0, 0, 70), 24, 24, ColorAlpha(stateColor, 100))
end

function ENT:GetStateColor(state)
	local colors = {
		[self.STATE_IDLE] = Color(150, 150, 150),
		[self.STATE_SEARCHING] = Color(255, 200, 50),
		[self.STATE_WALKING_TO_CHAIR] = Color(50, 200, 255),
		[self.STATE_SITTING] = Color(50, 255, 100),
		[self.STATE_WANDERING] = Color(255, 150, 50),
		[self.STATE_LOOKING_AROUND] = Color(200, 100, 255),
	}
	return colors[state] or Color(255, 255, 255)
end

function ENT:Think()
	-- Draw line to target chair if walking to one
	if IsValid(self:GetTargetChair()) and not self:GetIsSitting() then
		local startPos = self:GetPos() + Vector(0, 0, 40)
		local endPos = self:GetTargetChair():GetPos() + Vector(0, 0, 20)
		
		debugoverlay.Line(startPos, endPos, 0.1, Color(50, 200, 255), true)
	end
	
	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:GetMaxHealth()
	return self:GetNWInt('MaxHealth', 100)
end

