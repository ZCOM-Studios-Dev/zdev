--[[
	ZDEV Flashbang Grenade Entity (Single-file SENT)

	A tactical flashbang grenade derived from zdev_ent_grenade.
	Blinds and deafens players/NPCs within range instead of dealing damage.

	By ZCOM Studios
	Copyright (c) 2020-2026 by ZCOM Studios, All rights reserved.
]]

AddCSLuaFile()

-- ============================================================================
-- ENT STRUCTURE PROPERTIES
-- ============================================================================
ENT.Base 						= "zdev_projectile_base_grenade"
ENT.Type 						= "anim"

-- ============================================================================
-- SPAWNMENU PROPERTIES
-- ============================================================================
ENT.PrintName 					= "Flashbang Grenade"
ENT.Author 						= "ZCOM Studios"
ENT.Contact 					= "dev@zcom-studios.com"
ENT.Purpose 					= "A tactical flashbang grenade"
ENT.Instructions 				= "Throw to blind and deafen nearby targets"
ENT.Category 					= "ZDEV Projectiles"
ENT.Spawnable 					= true
ENT.AdminOnly 					= false -- Only admins can spawn this entity	

-- ============================================================================
-- FLASHBANG CONFIGURATION (Override grenade values)
-- ============================================================================
ENT.Model           			= "models/weapons/w_eq_flashbang.mdl"
ENT.Mass 						= 0.4
ENT.ActivationTime 				= 1.5
ENT.IsExplosive 				= false

-- Effect radius
ENT.FlashRadius 				= 800
ENT.FlashInnerRadius 			= 200

-- Effect durations (seconds)
ENT.MaxBlindDuration 			= 5.0
ENT.MaxDeafDuration 			= 8.0
ENT.MinBlindDuration 			= 0.5

-- Effect modifiers
ENT.LookingAtMultiplier 		= 1.5
ENT.BackTurnedMultiplier 		= 0.3

-- Visual/Audio
ENT.FlashSound 					= "weapons/flashbang/flashbang_explode1.wav"
ENT.FlashEffect 				= "cball_explode"
ENT.BeepSound 					= "buttons/button17.wav"
ENT.BeepInterval 				= 0.3

-- ============================================================================
-- NETWORKED DATA TABLES
-- ===========================================	=================================
function ENT:SetupDataTables()
	-- Call base SetupDataTables using direct reference to avoid recursion
	local baseClass = baseclass.Get("zdev_projectile_base_grenade")
	if baseClass and baseClass.SetupDataTables then
		baseClass.SetupDataTables(self)
	end
	self:NetworkVar("Float", 3, "FlashTime")
end

-- ============================================================================
-- SERVER-SIDE CODE
-- ============================================================================
if SERVER then

	util.AddNetworkString("ZDEV_Flashbang_Effect")

	local CurTime = CurTime
	local IsValid = IsValid
	local ents = ents
	local util = util
	local math = math

	function ENT:Initialize()
		zdev.log("D", "[Flashbang] Initialize() - Class: " .. self:GetClass())

		-- Call base grenade initialization
		local baseClass = baseclass.Get("zdev_projectile_base_grenade")
		if baseClass and baseClass.Initialize then
			baseClass.Initialize(self)
		end

		self.IsExplosive = false

		zdev.log("I", "[Flashbang] Initialized - FlashRadius: " .. self.FlashRadius .. ", InnerRadius: " .. self.FlashInnerRadius)
	end

	function ENT:OnActivate()
		zdev.log("D", "[Flashbang] OnActivate() - FLASH DETONATING!")

		self:EmitSound(self.FlashSound, 100, 100, 1)

		local effectData = EffectData()
		effectData:SetOrigin(self:GetPos())
		effectData:SetScale(2)
		util.Effect(self.FlashEffect, effectData, true, true)

		-- Debug: Draw flash radius spheres (inner = full effect, outer = falloff zone)
		local pos = self:GetPos()
		debugoverlay.Sphere(pos, self.FlashInnerRadius, 3, Color(255, 255, 255, 150), true)
		debugoverlay.Sphere(pos, self.FlashRadius, 3, Color(200, 220, 255, 50), true)
		debugoverlay.Cross(pos, 30, 3, Color(255, 255, 255), true)
		debugoverlay.Text(pos + Vector(0, 0, 40), "FLASHBANG! Inner=" .. self.FlashInnerRadius .. " Outer=" .. self.FlashRadius, 3)

		self:SetFlashTime(CurTime())
		self:ApplyFlashEffect()

		zdev.log("I", "[Flashbang] Flash activated at " .. tostring(pos))

		timer.Simple(0.1, function()
			if IsValid(self) then self:Remove() end
		end)
	end

	function ENT:ApplyFlashEffect()
		local pos = self:GetPos()
		local targetsFound = 0
		local targetsAffected = 0

		for _, target in ipairs(ents.FindInSphere(pos, self.FlashRadius)) do
			if IsValid(target) and target ~= self and (target:IsPlayer() or target:IsNPC()) then
				targetsFound = targetsFound + 1
				local wasAffected = self:FlashTarget(target, pos)
				if wasAffected then
					targetsAffected = targetsAffected + 1
				end
			end
		end

		zdev.log("D", "[Flashbang] ApplyFlashEffect() - Found: " .. targetsFound .. " targets, Affected: " .. targetsAffected)
	end

	function ENT:FlashTarget(target, flashPos)
		local targetPos = target:EyePos()
		local distance = flashPos:Distance(targetPos)
		local targetName = target:IsPlayer() and target:Nick() or target:GetClass()

		zdev.log("D", "[Flashbang] FlashTarget() - Target: " .. targetName .. " Distance: " .. math.Round(distance))

		-- Debug: Draw line to target
		debugoverlay.Line(flashPos, targetPos, 2, Color(255, 255, 100), true)

		local tr = util.TraceLine({
			start = flashPos, endpos = targetPos,
			filter = {self, target}, mask = MASK_OPAQUE
		})
		if tr.Hit and not tr.HitSky then
			-- Debug: Draw blocked LOS
			debugoverlay.Line(flashPos, tr.HitPos, 2, Color(255, 0, 0), true)
			debugoverlay.Cross(tr.HitPos, 8, 2, Color(255, 0, 0), true)
			debugoverlay.Text(tr.HitPos + Vector(0, 0, 10), "LOS BLOCKED", 2)
			zdev.log("D", "[Flashbang] Target " .. targetName .. " - LOS blocked by " .. (tr.Entity and tr.Entity:GetClass() or "world"))
			return false
		end

		local intensity = 1.0
		if distance > self.FlashInnerRadius then
			intensity = 1 - ((distance - self.FlashInnerRadius) / (self.FlashRadius - self.FlashInnerRadius))
		end
		intensity = math.Clamp(intensity, 0, 1)

		local facingMod = 1.0
		local facingStr = "SIDE"
		if target:IsPlayer() then
			local dot = target:EyeAngles():Forward():Dot((flashPos - targetPos):GetNormalized())
			if dot > 0.5 then
				facingMod = self.LookingAtMultiplier
				facingStr = "LOOKING"
			elseif dot < -0.5 then
				facingMod = self.BackTurnedMultiplier
				facingStr = "BACK"
			end
		end

		local blindDuration = Lerp(intensity, self.MinBlindDuration, self.MaxBlindDuration) * facingMod
		local deafDuration = self.MaxDeafDuration * intensity * facingMod

		-- Debug: Draw effect on target
		local effectColor = Color(255, 255, math.floor(255 * intensity), 200)
		debugoverlay.Cross(targetPos, 12, 2, effectColor, true)
		debugoverlay.Text(targetPos + Vector(0, 0, 20), string.format("%s: %.0f%% %s", targetName, intensity * 100, facingStr), 2)
		debugoverlay.Text(targetPos + Vector(0, 0, 10), string.format("Blind: %.1fs Deaf: %.1fs", blindDuration, deafDuration), 2)

		zdev.log("I", "[Flashbang] Flashed " .. targetName .. " - Intensity: " .. string.format("%.0f%%", intensity * 100) .. " Facing: " .. facingStr .. " Blind: " .. string.format("%.1f", blindDuration) .. "s Deaf: " .. string.format("%.1f", deafDuration) .. "s")

		if target:IsPlayer() then
			net.Start("ZDEV_Flashbang_Effect")
				net.WriteFloat(blindDuration)
				net.WriteFloat(deafDuration)
				net.WriteFloat(intensity)
			net.Send(target)
		elseif target:IsNPC() then
			local oldEnemy = target:GetEnemy()
			target:SetEnemy(nil)
			target:SetSchedule(SCHED_COMBAT_STAND)
			timer.Simple(blindDuration, function()
				if IsValid(target) and IsValid(oldEnemy) then target:SetEnemy(oldEnemy) end
			end)
		end

		return true
	end

end -- SERVER

-- ============================================================================
-- CLIENT-SIDE CODE
-- ============================================================================
if CLIENT then

	local CurTime = CurTime
	local LocalPlayer = LocalPlayer
	local render = render
	local surface = surface
	local math = math
	local Lerp = Lerp

	local MAT_WHITE = Material("vgui/white")
	local MAT_GLOW = Material("sprites/light_glow02_add")

	local FlashState = {
		Active = false,
		StartTime = 0,
		BlindDuration = 0,
		DeafDuration = 0,
		Intensity = 0
	}

	net.Receive("ZDEV_Flashbang_Effect", function()
		FlashState.Active = true
		FlashState.StartTime = CurTime()
		FlashState.BlindDuration = net.ReadFloat()
		FlashState.DeafDuration = net.ReadFloat()
		FlashState.Intensity = net.ReadFloat()

		zdev.log("D", "[Flashbang:CL] Received flash effect - Blind: " .. string.format("%.1f", FlashState.BlindDuration) .. "s, Deaf: " .. string.format("%.1f", FlashState.DeafDuration) .. "s, Intensity: " .. string.format("%.0f%%", FlashState.Intensity * 100))

		if FlashState.DeafDuration > 0 then
			surface.PlaySound("ambient/machines/thumper_dust.wav")
		end

		zdev.log("I", "[Flashbang:CL] FLASHED! Screen effect active for " .. string.format("%.1f", FlashState.BlindDuration) .. "s")
	end)

	hook.Add("RenderScreenspaceEffects", "ZDEV_Flashbang_Blind", function()
		if not FlashState.Active then return end

		local elapsed = CurTime() - FlashState.StartTime
		if elapsed > FlashState.BlindDuration then
			FlashState.Active = false
			return
		end

		local progress = elapsed / FlashState.BlindDuration
		local alpha = progress < 0.1 and 255 or Lerp((progress - 0.1) / 0.9, 255, 0) * FlashState.Intensity

		render.SetMaterial(MAT_WHITE)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end)

	hook.Add("Think", "ZDEV_Flashbang_Deaf", function()
		if not FlashState.Active then return end

		local elapsed = CurTime() - FlashState.StartTime
		if elapsed > FlashState.DeafDuration then return end

		local deafIntensity = (1 - elapsed / FlashState.DeafDuration) * FlashState.Intensity
		LocalPlayer():SetDSP(deafIntensity > 0.3 and 31 or 0)
	end)

	function ENT:Initialize()
		zdev.log("D", "[Flashbang:CL] Initialize() - Setting up client-side entity")

		-- Call base Initialize using direct reference to avoid recursion
		local baseClass = baseclass.Get("zdev_projectile_base_grenade")
		if baseClass and baseClass.Initialize then
			baseClass.Initialize(self)
		end
		self.BlinkState = false
		self.NextBlinkTime = 0

		zdev.log("I", "[Flashbang:CL] Client-side initialized")
	end

	function ENT:Draw()
		self:DrawModel()
		if self:GetArmed() and not self:GetActivated() then
			self:DrawArmedIndicator()
		end
	end

	function ENT:DrawArmedIndicator()
		local timeLeft = self:GetTimeUntilActivation()
		if timeLeft <= 0 then return end

		local progress = 1 - (timeLeft / self.ActivationTime)
		local blinkRate = Lerp(progress, 0.3, 0.05)

		if CurTime() >= self.NextBlinkTime then
			self.BlinkState = not self.BlinkState
			self.NextBlinkTime = CurTime() + blinkRate

			-- Debug: Log blink state changes (only when state changes, not every frame)
			if self.BlinkState then
				zdev.log("D", "[Flashbang:CL] Blink ON - TimeLeft: " .. string.format("%.2f", timeLeft) .. "s, Rate: " .. string.format("%.3f", blinkRate) .. "s")
			end
		end

		if not self.BlinkState then return end

		local pos = self:GetPos() + self:GetUp() * 3
		local size = 10 + math.sin(CurTime() * 25) * 3
		render.SetMaterial(MAT_GLOW)
		render.DrawSprite(pos, size, size, Color(200, 220, 255, 255))
	end

end -- CLIENT

