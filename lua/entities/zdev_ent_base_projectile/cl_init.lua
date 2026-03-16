--[[
	CL_INIT.LUA - Base Throwable Projectile (Client-side)

	Client-side rendering, effects, and HUD for throwable projectiles.
	Reference: https:--wiki.facepunch.com/gmod/ENTITY_Hooks
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
local MAT_GLOW = Material("sprites/light_glow02_add")
local MAT_TRAIL = Material("trails/laser")

-- ============================================================================
-- CLIENT-SIDE INITIALIZATION
-- ============================================================================
function ENT:Initialize()
	-- Initialize client state
	self.LastPos = self:GetPos()
	self.TrailPoints = {}
	self.MaxTrailPoints = 32

	-- Cache glow material if needed
	if self.GlowEffect then
		self.GlowMaterial = MAT_GLOW
	end

	-- Initialize trail if configured
	if self.TrailEffect ~= "" then
		self:SetupTrail()
	end
end

--- Set up trail effect
function ENT:SetupTrail()
	-- Create trail using util.SpriteTrail for simple trails
	if self.TrailWidth > 0 then
		util.SpriteTrail(
			self,
			0, -- attachment
			self.TrailColor,
			false, -- additive
			self.TrailWidth,
			0, -- end width
			self.TrailDuration,
			1 / (self.TrailWidth * 2), -- texture resolution
			self.TrailEffect ~= "" and self.TrailEffect or "trails/laser.vmt"
		)
	end
end

-- ============================================================================
-- RENDERING
-- ============================================================================
function ENT:Draw(flags)
	-- Draw the model
	self:DrawModel()

	-- Draw glow effect if enabled
	if self.GlowEffect then
		self:DrawGlow()
	end
end

function ENT:DrawTranslucent(flags)
	-- Draw any translucent effects
	if self.GlowEffect then
		self:DrawGlow()
	end
end

--- Draw glow sprite effect
function ENT:DrawGlow()
	if not self.GlowEffect then return end

	local pos = self:GetPos()
	local size = self.GlowSize
	local color = self.GlowColor

	-- Pulsing effect when armed
	if self:GetArmed() then
		local pulse = math.sin(CurTime() * 8) * 0.3 + 0.7
		size = size * pulse
	end

	render.SetMaterial(self.GlowMaterial or MAT_GLOW)
	render.DrawSprite(pos, size, size, color)
end

-- ============================================================================
-- CLIENT THINK
-- ============================================================================
function ENT:Think()
	if ( self.TrailPoints ) then
		-- Update trail points for custom trail rendering
		if self.TrailEffect ~= "" and #self.TrailPoints < self.MaxTrailPoints then
			local curPos = self:GetPos()
			if curPos:DistToSqr(self.LastPos) > 16 then
				table.insert(self.TrailPoints, 1, {
					pos = curPos,
					time = CurTime()
				})
				self.LastPos = curPos

				-- Limit trail length
				while #self.TrailPoints > self.MaxTrailPoints do
					table.remove(self.TrailPoints)
				end
			end
		end

		-- Clean up old trail points
		local maxAge = self.TrailDuration
		for i = #self.TrailPoints, 1, -1 do
			if CurTime() - self.TrailPoints[i].time > maxAge then
				table.remove(self.TrailPoints, i)
			end
		end
	end
end

-- ============================================================================
-- HUD OVERLAY (When looking at entity)
-- ============================================================================

--- Check if local player is looking at this entity
function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end

	local view = ply:GetViewEntity()
	local maxDist = 256

	if view:EyePos():Distance(self:GetPos()) > maxDist then
		return false
	end

	local tr = ply:GetEyeTrace()
	return tr.Entity == self
end

--- Draw world HUD info when looking at entity
function ENT:DrawWorldHUD()
	if not self:BeingLookedAtByLocalPlayer() then return end

	local pos = self:GetPos() + Vector(0, 0, 10)
	local ang = (LocalPlayer():EyePos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.1)
		-- Background
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(-100, -30, 200, 60)

		-- Status text
		local status = "INACTIVE"
		local statusColor = Color(150, 150, 150)

		if self:GetActivated() then
			status = "ACTIVATED"
			statusColor = Color(255, 100, 100)
		elseif self:GetArmed() then
			status = "ARMED"
			statusColor = Color(255, 200, 100)

			-- Timer display
			local timeLeft = self:GetTimeUntilActivation()
			if timeLeft > 0 then
				status = string.format("ARMED: %.1fs", timeLeft)
			end
		elseif self:GetDeployed() then
			status = "DEPLOYED"
			statusColor = Color(100, 200, 100)
		elseif self:GetAttached() then
			status = "ATTACHED"
			statusColor = Color(100, 150, 255)
		end

		draw.SimpleText(status, "DermaDefault", 0, 0, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

-- ============================================================================
-- CLEANUP
-- ============================================================================
function ENT:OnRemove()
	-- Clear trail points
	self.TrailPoints = nil
end