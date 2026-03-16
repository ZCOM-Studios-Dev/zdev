--[[
	CL_INIT.LUA - Basic Grenade Entity (Client-side)

	Client-side rendering and effects for the basic grenade.
	By ZCOM Studios
	Copyright (c) 2020-2026 by ZCOM Studios, All rights reserved.
]]

-- Include shared file
include("shared.lua")

-- ============================================================================
-- LOCALIZED GLOBALS (Performance)
-- ============================================================================
local CurTime = CurTime
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local render = render
local cam = cam
local draw = draw
local surface = surface
local math = math

-- ============================================================================
-- CACHED MATERIALS
-- ============================================================================
local MAT_BLINK = Material("sprites/redglow1")

-- ============================================================================
-- CLIENT-SIDE INITIALIZATION
-- ============================================================================
function ENT:Initialize()
	-- Call base initialization using direct reference to avoid recursion
	local baseClass = baseclass.Get("zdev_ent_base_projectile")
	if baseClass and baseClass.Initialize then
		baseClass.Initialize(self)
	end

	-- Blink state for armed indicator
	self.BlinkState = false
	self.NextBlinkTime = 0
	self.BlinkInterval = 0.5
end

-- ============================================================================
-- RENDERING
-- ============================================================================
function ENT:Draw(flags)
	-- Draw the grenade model
	self:DrawModel()

	-- Draw armed indicator light
	if self:GetArmed() and not self:GetActivated() then
		self:DrawArmedIndicator()
	end
end

--- Draw blinking red light when armed
function ENT:DrawArmedIndicator()
	-- Calculate blink rate based on time remaining
	local timeLeft = self:GetTimeUntilActivation()
	if timeLeft <= 0 then return end

	local progress = 1 - (timeLeft / self.ActivationTime)
	local blinkRate = Lerp(progress, 0.5, 0.08)

	-- Update blink state
	if CurTime() >= self.NextBlinkTime then
		self.BlinkState = not self.BlinkState
		self.NextBlinkTime = CurTime() + blinkRate
	end

	if not self.BlinkState then return end

	-- Draw red glow sprite at top of grenade
	local pos = self:GetPos() + self:GetUp() * 4
	local size = 8 + math.sin(CurTime() * 20) * 2

	render.SetMaterial(MAT_BLINK)
	render.DrawSprite(pos, size, size, Color(255, 50, 50, 255))
end

-- ============================================================================
-- CLIENT THINK
-- ============================================================================
function ENT:Think()
	-- Call base think using direct reference to avoid recursion
	local baseClass = baseclass.Get("zdev_ent_base_projectile")
	if baseClass and baseClass.Think then
		baseClass.Think(self)
	end
end

-- ============================================================================
-- HUD OVERLAY
-- ============================================================================

--- Draw world HUD info when looking at grenade
function ENT:DrawWorldHUD()
	if not self:BeingLookedAtByLocalPlayer() then return end

	local pos = self:GetPos() + Vector(0, 0, 12)
	local ang = (LocalPlayer():EyePos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.08)
		-- Background
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(-120, -40, 240, 80)

		-- Title
		draw.SimpleText("GRENADE", "DermaDefaultBold", 0, -20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		-- Status
		local status, statusColor

		if self:GetActivated() then
			status = "DETONATED"
			statusColor = Color(255, 50, 50)
		elseif self:GetArmed() then
			local timeLeft = self:GetTimeUntilActivation()
			status = string.format("FUSE: %.1fs", timeLeft)

			-- Color shifts from yellow to red as time runs out
			local danger = 1 - (timeLeft / self.ActivationTime)
			statusColor = Color(255, 255 * (1 - danger), 50)
		else
			status = "SAFE"
			statusColor = Color(100, 255, 100)
		end

		draw.SimpleText(status, "DermaDefault", 0, 10, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

