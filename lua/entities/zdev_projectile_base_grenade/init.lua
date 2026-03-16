--[[
	INIT.LUA - Basic Grenade Entity (Server-side)

	Server-side initialization and behavior for the basic grenade.
	By ZCOM Studios
	Copyright (c) 2020-2026 by ZCOM Studios, All rights reserved.
]]

-- ============================================================================
-- FILE INCLUDES
-- ============================================================================
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ============================================================================
-- LOCALIZED GLOBALS (Performance)
-- ============================================================================
local CurTime = CurTime
local IsValid = IsValid
local math = math

-- ============================================================================
-- SERVER-SIDE INITIALIZATION
-- ============================================================================
function ENT:Initialize()
	zdev.log("D", "[BaseGrenade] Initialize() - Class: " .. self:GetClass())

	-- Call base initialization
	local baseClass = baseclass.Get("zdev_ent_base_projectile")
	if baseClass and baseClass.Initialize then
		baseClass.Initialize(self)
	end

	-- Initialize beep state
	self.NextBeepTime = 0
	self.CurrentBeepInterval = self.BeepInterval

	-- Grenade is not deployed/attachable
	self.IsDeployable = false
	self.IsAttachable = false

	zdev.log("I", "[BaseGrenade] Initialized - Fuse: " .. self.ActivationTime .. "s, Radius: " .. self.ExplosionRadius .. ", Damage: " .. self.ExplosionDamage)
end

-- ============================================================================
-- GRENADE HOOKS (Override base)
-- ============================================================================

--- Called when the grenade is thrown
function ENT:OnThrow(thrower, velocity)
	local throwerName = IsValid(thrower) and (thrower:IsPlayer() and thrower:Nick() or thrower:GetClass()) or "UNKNOWN"
	zdev.log("D", "[BaseGrenade] OnThrow() - Thrower: " .. throwerName .. " Speed: " .. math.Round(velocity:Length()) .. " u/s")

	-- Arm immediately on throw
	self:Arm()

	-- Play pin pull sound
	if self.PinPullSound and self.PinPullSound ~= "" then
		self:EmitSound(self.PinPullSound, 75, 100, 0.8)
	end

	-- Debug: Draw throw arc preview
	debugoverlay.Line(self:GetPos(), self:GetPos() + velocity:GetNormalized() * 150, 3, Color(255, 100, 100), true)

	zdev.log("I", "[BaseGrenade] Grenade thrown! Fuse active.")
end

--- Called when the grenade is armed
function ENT:OnArm()
	zdev.log("D", "[BaseGrenade] OnArm() - BeepInterval: " .. self.BeepInterval .. "s, MinInterval: " .. self.BeepMinInterval .. "s")

	-- Reset beep timer
	self.NextBeepTime = CurTime() + self.BeepInterval
	self.CurrentBeepInterval = self.BeepInterval

	-- Play initial arm sound
	self:EmitSound(self.BeepSound, 60, 100, 0.5)

	-- Debug: Draw arm indicator
	debugoverlay.Cross(self:GetPos(), 15, 2, Color(255, 200, 0), true)
	debugoverlay.Text(self:GetPos() + Vector(0, 0, 20), "GRENADE ARMED", 2)

	zdev.log("I", "[BaseGrenade] Armed - Beeping started")
end

--- Called when the grenade impacts something
function ENT:OnImpact(hitEntity, colData)
	local hitName = IsValid(hitEntity) and (hitEntity:IsWorld() and "WORLD" or hitEntity:GetClass()) or "UNKNOWN"
	local speed = colData.Speed or 0

	zdev.log("D", "[BaseGrenade] OnImpact() - Hit: " .. hitName .. " Speed: " .. math.Round(speed) .. " u/s")

	-- Debug: Draw bounce point
	if colData.HitPos then
		debugoverlay.Cross(colData.HitPos, 6, 1.5, Color(200, 150, 0), true)
		if colData.HitNormal then
			debugoverlay.Line(colData.HitPos, colData.HitPos + colData.HitNormal * 20, 1.5, Color(200, 200, 0), true)
		end
	end

	-- Play bounce sound based on impact speed
	if speed > 50 then
		local volume = math.Clamp(speed / 500, 0.2, 0.8)
		self:EmitSound("physics/metal/metal_canister_impact_soft" .. math.random(1, 3) .. ".wav", 60, 100, volume)
	end
end

--- Called just before explosion
function ENT:OnActivate()
	zdev.log("D", "[BaseGrenade] OnActivate() - DETONATING!")

	-- Debug: Draw final position
	debugoverlay.Cross(self:GetPos(), 25, 3, Color(255, 0, 0), true)
	debugoverlay.Sphere(self:GetPos(), self.ExplosionRadius, 3, Color(255, 50, 0, 80), true)
	debugoverlay.Text(self:GetPos() + Vector(0, 0, 35), "BOOM!", 3)

	-- Final beep before explosion
	self:EmitSound(self.BeepSound, 80, 150, 1.0)

	zdev.log("I", "[BaseGrenade] Detonating at " .. tostring(self:GetPos()))
end

-- ============================================================================
-- THINK LOGIC (Beeping)
-- ============================================================================

-- Debug throttle for grenade Think
ENT.NextGrenadeDebugTime = 0

function ENT:Think()
	-- Call base think first using direct reference to avoid recursion
	local baseClass = baseclass.Get("zdev_ent_base_projectile")
	local ret
	if baseClass and baseClass.Think then
		ret = baseClass.Think(self)
	end

	-- Handle beeping when armed
	if self:GetArmed() and not self:GetActivated() then
		self:UpdateBeeping()

		-- Debug: Draw fuse countdown (throttled)
		if CurTime() >= (self.NextGrenadeDebugTime or 0) then
			self.NextGrenadeDebugTime = CurTime() + 0.25

			local timeLeft = self:GetTimeUntilActivation()
			local progress = 1 - (timeLeft / self.ActivationTime)

			-- Color transitions from green to red as fuse burns
			local r = math.floor(progress * 255)
			local g = math.floor((1 - progress) * 255)

			debugoverlay.Sphere(self:GetPos(), 20, 0.25, Color(r, g, 0, 100), true)
			debugoverlay.Text(self:GetPos() + Vector(0, 0, 25), string.format("FUSE: %.2fs (%.0f%%)", timeLeft, progress * 100), 0.25)
		end
	end

	return ret
end

--- Update beeping sound with accelerating frequency
function ENT:UpdateBeeping()
	if CurTime() < self.NextBeepTime then return end

	-- Play beep
	self:EmitSound(self.BeepSound, 60, 100 + (self.BeepInterval - self.CurrentBeepInterval) * 100, 0.6)

	-- Calculate next beep (accelerating)
	local timeLeft = self:GetTimeUntilActivation()
	local progress = 1 - (timeLeft / self.ActivationTime)

	-- Interpolate beep interval based on progress
	self.CurrentBeepInterval = Lerp(progress, self.BeepInterval, self.BeepMinInterval)
	self.NextBeepTime = CurTime() + self.CurrentBeepInterval

	-- Debug: Log beep with timing info
	zdev.log("D", "[BaseGrenade] BEEP! TimeLeft: " .. string.format("%.2f", timeLeft) .. "s, Interval: " .. string.format("%.3f", self.CurrentBeepInterval) .. "s")

	-- Debug: Flash indicator on beep
	debugoverlay.Cross(self:GetPos(), 8, 0.15, Color(255, 100, 100), true)
end

-- ============================================================================
-- COOKING SUPPORT
-- ============================================================================

--- Set a custom fuse time (for cooking)
-- @param fuseTime number Time until explosion
function ENT:SetFuseTime(fuseTime)
	if not self.CanCook then return end

	local clampedTime = math.Clamp(fuseTime, self.MinFuseTime, self.ActivationTime)
	self:SetActivateTime(CurTime() + clampedTime)
end

--- Get remaining fuse time
-- @return number Seconds until explosion
function ENT:GetFuseTime()
	return self:GetTimeUntilActivation()
end

