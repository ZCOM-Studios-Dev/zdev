--[[
	ZDEV SWEP HACKER - Basic Generic Framework

	A lightweight, performance-optimized SWEP framework for Garry's Mod.
	Designed for minimal overhead and maximum extensibility.
]]


-- ============================================================================
-- SWEP METADATA
-- ============================================================================

SWEP.Base = "weapon_base"

-- Spawn Menu Information
SWEP.PrintName = "ZDEV Hacker Tool"
SWEP.Author = "ZCOM Studios"
SWEP.Contact = ""
SWEP.Purpose = "Generic hacking tool framework"
SWEP.Instructions = "Left click to use, Right click for secondary function"
SWEP.Category = "ZDEV"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HoldType = "knife"

-- ============================================================================
-- MODELS AND VIEWMODEL
-- ============================================================================
SWEP.ViewModelFOV = 90.854271356784
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_c4.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false

-- ============================================================================
-- WEAPON BEHAVIOR
-- ============================================================================
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

-- ============================================================================
-- WEAPON SELECTION (HUD)
-- ============================================================================
SWEP.Slot = 1
SWEP.SlotPos = 1

-- ============================================================================
-- HUD DISPLAY OPTIONS
-- ============================================================================
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.DrawWeaponInfoBox = true

-- ============================================================================
-- PRIMARY ATTACK SETTINGS
-- ============================================================================
SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false


-- ============================================================================
-- SECONDARY ATTACK SETTINGS
-- ============================================================================
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false


-- ============================================================================
-- VIEWMODEL BONE MODIFICATIONS AND ELEMENTS
-- ============================================================================
SWEP.ViewModelBoneMods = {
	["v_weapon.Right_Arm"] = { scale = Vector(1, 1, 1), pos = Vector(1.61, 5.738, 4.738), angle = Angle(51.721, -61.41, -117.393) },
	["v_weapon.Right_Thumb03"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-4.432, 26.319, 27.034) },
	["v_weapon.Left_Arm"] = { scale = Vector(1, 1, 1), pos = Vector(11.666, -30, 10.185), angle = Angle(0, 0, 0) },
	["v_weapon.Right_Thumb02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-3.164, -1.813, -2.597) },
	["v_weapon.Right_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(5.282, 23.893, -15.377) },
	["v_weapon.Right_Thumb01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 2.624, 0) },
	["v_weapon.c4"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["v_weapon"] = { scale = Vector(1.016, 1.016, 1.016), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
local ViewSceen = {
	w = 270, h = 170,
	x = 0, y = 0,
	color = Color(0,0,0,255)
}

-- ============================================================================
-- MENU SYSTEM CONFIGURATION
-- ============================================================================

-- Animation durations for each action
local AnimationDurations = {
	scan = 4.0,
	decrypt = 5.0,
	exploit = 4.5,
	backdoor = 5.5,
	logs = 3.0,
	disconnect = 2.5,
	-- Target command animations
	target_scan = 3.0,
	target_exploit = 2.5,
	target_convert = 2.0,
	target_overload = 1.5
}

-- Target Commands submenu (shown when target is locked)
local TargetCommandsMenu = {
	{
		id = "target_scan",
		name = "◈ SCAN TARGET",
		icon = "►",
		action = function(self)
			if not self.LockedTarget then
				self.StatusMessage = "ERROR: NO TARGET LOCKED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			self:StartAnimation("target_scan", AnimationDurations.target_scan)
			self.TargetCommandEntity = self.LockedTarget.entity
		end
	},
	{
		id = "target_exploit",
		name = "◈ DEPLOY EXPLOIT",
		icon = "►",
		requires_scan = true,
		action = function(self)
			if not self.LockedTarget then
				self.StatusMessage = "ERROR: NO TARGET LOCKED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			local ent = self.LockedTarget.entity
			if not self:IsTargetScanned(ent) then
				self.StatusMessage = "ERROR: TARGET NOT SCANNED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			self:StartAnimation("target_exploit", AnimationDurations.target_exploit)
			self.TargetCommandEntity = ent
		end
	},
	{
		id = "target_convert",
		name = "◈ CONVERT TARGET",
		icon = "►",
		requires_exploit = true,
		action = function(self)
			if not self.LockedTarget then
				self.StatusMessage = "ERROR: NO TARGET LOCKED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			local ent = self.LockedTarget.entity
			if not self:IsTargetExploited(ent) then
				self.StatusMessage = "ERROR: EXPLOIT NOT DEPLOYED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			self:StartAnimation("target_convert", AnimationDurations.target_convert)
			self.TargetCommandEntity = ent
		end
	},
	{
		id = "target_overload",
		name = "◈ CORE OVERLOAD",
		icon = "►",
		requires_exploit = true,
		action = function(self)
			if not self.LockedTarget then
				self.StatusMessage = "ERROR: NO TARGET LOCKED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			local ent = self.LockedTarget.entity
			if not self:IsTargetExploited(ent) then
				self.StatusMessage = "ERROR: EXPLOIT NOT DEPLOYED"
				self.StatusMessageTime = RealTime() + 2
				self:EmitSound("buttons/button8.wav", 60, 80)
				return
			end
			self:StartAnimation("target_overload", AnimationDurations.target_overload)
			self.TargetCommandEntity = ent
		end
	}
}

-- Menu structure: supports nested menus
local MenuData = {
	{
		id = "scan",
		name = "◈ SCAN NETWORK",
		icon = "►",
		action = function(self)
			self:StartAnimation("scan", AnimationDurations.scan)
		end
	},
	{
		id = "decrypt",
		name = "◈ DECRYPT DATA",
		icon = "►",
		action = function(self)
			self:StartAnimation("decrypt", AnimationDurations.decrypt)
		end
	},
	{
		id = "exploit",
		name = "◈ RUN EXPLOIT",
		icon = "►",
		action = function(self)
			self:StartAnimation("exploit", AnimationDurations.exploit)
		end
	},
	{
		id = "backdoor",
		name = "◈ INSTALL BACKDOOR",
		icon = "►",
		action = function(self)
			self:StartAnimation("backdoor", AnimationDurations.backdoor)
		end
	},
	{
		id = "logs",
		name = "◈ CLEAR LOGS",
		icon = "►",
		action = function(self)
			self:StartAnimation("logs", AnimationDurations.logs)
		end
	},
	{
		id = "target_commands",
		name = "◈ TARGET COMMANDS",
		icon = "►",
		dynamic = true, -- Only show when target is locked
		submenu = TargetCommandsMenu
	},
	{
		id = "disconnect",
		name = "◈ DISCONNECT",
		icon = "►",
		action = function(self)
			self:StartAnimation("disconnect", AnimationDurations.disconnect)
		end
	}
}

-- Target state tracking
SWEP.ScannedTargets = {}
SWEP.ExploitedTargets = {}
SWEP.TargetLog = {}

function SWEP:IsTargetScanned(ent)
	if not IsValid(ent) then return false end
	return self.ScannedTargets[ent:EntIndex()] ~= nil
end

function SWEP:IsTargetExploited(ent)
	if not IsValid(ent) then return false end
	return self.ExploitedTargets[ent:EntIndex()] ~= nil
end

function SWEP:MarkTargetScanned(ent, data)
	if not IsValid(ent) then return end
	self.ScannedTargets[ent:EntIndex()] = data or true
	-- Add to target log
	table.insert(self.TargetLog, {
		entity = ent,
		entIndex = ent:EntIndex(),
		class = ent:GetClass(),
		scanTime = RealTime(),
		data = data
	})
end

function SWEP:MarkTargetExploited(ent)
	if not IsValid(ent) then return end
	self.ExploitedTargets[ent:EntIndex()] = true
end

function SWEP:GetTargetLog()
	-- Clean up invalid entries
	for i = #self.TargetLog, 1, -1 do
		if not IsValid(self.TargetLog[i].entity) then
			table.remove(self.TargetLog, i)
		end
	end
	return self.TargetLog
end

-- Input timing to prevent rapid scrolling
local InputCooldown = 0.15

-- ============================================================================
-- ANIMATION SYSTEM
-- ============================================================================

-- Start an animation
function SWEP:StartAnimation(animId, duration)
	self.ActiveAnimation = animId
	self.AnimationStartTime = RealTime()
	self.AnimationDuration = duration
	self.AnimationProgress = 0
	self.AnimationData = {} -- For storing animation-specific data

	-- Play start sound
	self:EmitSound("buttons/button17.wav", 60, 100)
end

-- Check if animation is playing
function SWEP:IsAnimationPlaying()
	if not self.ActiveAnimation then return false end
	return RealTime() < (self.AnimationStartTime + self.AnimationDuration)
end

-- Get animation progress (0 to 1)
function SWEP:GetAnimationProgress()
	if not self.ActiveAnimation then return 0 end
	local elapsed = RealTime() - self.AnimationStartTime
	return math.Clamp(elapsed / self.AnimationDuration, 0, 1)
end

-- End animation
function SWEP:EndAnimation()
	local anim = self.ActiveAnimation
	local targetEnt = self.TargetCommandEntity

	self.ActiveAnimation = nil
	self.AnimationStartTime = nil
	self.AnimationDuration = nil
	self.AnimationProgress = 0
	self.AnimationData = {}

	-- Handle target command completions
	if CLIENT and anim and targetEnt and IsValid(targetEnt) then
		self:OnTargetCommandComplete(anim, targetEnt)
	end
end

-- Handle target command completion (CLIENT)
function SWEP:OnTargetCommandComplete(animId, targetEnt)
	if not IsValid(targetEnt) then return end

	if animId == "target_scan" then
		-- Mark target as scanned
		self:MarkTargetScanned(targetEnt, {
			scanTime = RealTime(),
			ip = self.LockedTarget and self.LockedTarget.ip or "0.0.0.0",
			mac = self.LockedTarget and self.LockedTarget.mac or "00:00:00:00:00:00"
		})
		self.StatusMessage = "TARGET SCANNED SUCCESSFULLY"
		self.StatusMessageTime = RealTime() + 3
		self:EmitSound("buttons/button4.wav", 60, 100)

	elseif animId == "target_exploit" then
		-- Mark target as exploited
		self:MarkTargetExploited(targetEnt)
		self.StatusMessage = "EXPLOIT DEPLOYED - TARGET HACKED"
		self.StatusMessageTime = RealTime() + 3
		self:EmitSound("buttons/button4.wav", 60, 90)

		-- Trigger glitch effect on HUD (set a flag for the HUD system)
		self.TargetHackedTime = RealTime()
		self.TargetHackedEntity = targetEnt

	elseif animId == "target_convert" then
		-- Send network message to server
		net.Start("ZDEVHacker_ConvertTarget")
			net.WriteEntity(targetEnt)
		net.SendToServer()
		self.StatusMessage = "TARGET CONVERTED TO ALLY"
		self.StatusMessageTime = RealTime() + 3
		self:EmitSound("buttons/button4.wav", 60, 80)

		-- Mark as converted locally
		self.ConvertedTargets = self.ConvertedTargets or {}
		self.ConvertedTargets[targetEnt:EntIndex()] = true

	elseif animId == "target_overload" then
		-- Send network message to server
		net.Start("ZDEVHacker_CoreOverload")
			net.WriteEntity(targetEnt)
		net.SendToServer()
		self.StatusMessage = "CORE OVERLOAD INITIATED"
		self.StatusMessageTime = RealTime() + 3
		self:EmitSound("buttons/button4.wav", 60, 120)

		-- Mark as overloading locally for HUD effects
		self.OverloadingTargets = self.OverloadingTargets or {}
		self.OverloadingTargets[targetEnt:EntIndex()] = RealTime()
	end

	-- Clear target command reference
	self.TargetCommandEntity = nil
end

-- ============================================================================
-- CLIENT-SIDE FULLSCREEN ANIMATION RENDERING
-- ============================================================================

if CLIENT then

-- Generate random IP address
local function RandomIP()
	return string.format("%d.%d.%d.%d", math.random(1,255), math.random(0,255), math.random(0,255), math.random(1,254))
end

-- Generate random MAC address
local function RandomMAC()
	local hex = "0123456789ABCDEF"
	local mac = ""
	for i = 1, 6 do
		if i > 1 then mac = mac .. ":" end
		mac = mac .. hex[math.random(1,16)] .. hex[math.random(1,16)]
	end
	return mac
end

-- Generate random hex string
local function RandomHex(length)
	local hex = "0123456789ABCDEF"
	local str = ""
	for i = 1, length do
		str = str .. hex[math.random(1,16)]
	end
	return str
end

-- Animation: Network Scan (scaled for viewmodel screen)
local function DrawScanAnimation(weapon, w, h, progress, rt)
	-- Initialize scan data
	if not weapon.AnimationData.nodes then
		weapon.AnimationData.nodes = {}
		local centerX, centerY = w * 0.5, h * 0.5 + 10
		for i = 1, 8 do
			local angle = (i / 8) * math.pi * 2
			local radius = 25 + math.random(10, 30)
			table.insert(weapon.AnimationData.nodes, {
				x = centerX + math.cos(angle) * radius,
				y = centerY + math.sin(angle) * radius,
				ip = RandomIP(),
				discovered = math.random() * 0.7
			})
		end
	end

	local data = weapon.AnimationData
	local centerX, centerY = w * 0.5, h * 0.5 + 10

	-- Draw radar sweep
	local sweepAngle = rt * 2
	for i = 0, 20 do
		local alpha = 255 - (i * 12)
		local angle = sweepAngle - (i * 0.03)
		surface.SetDrawColor(0, 255, 100, alpha * 0.4)
		surface.DrawLine(centerX, centerY, centerX + math.cos(angle) * 60, centerY + math.sin(angle) * 50)
	end

	-- Draw concentric circles
	for i = 1, 3 do
		local radius = i * 20
		local alpha = 80 + math.sin(rt * 3 + i) * 40
		surface.SetDrawColor(0, 200, 255, alpha)
		local segments = 32
		for j = 0, segments do
			local a1 = (j / segments) * math.pi * 2
			local a2 = ((j + 1) / segments) * math.pi * 2
			surface.DrawLine(
				centerX + math.cos(a1) * radius, centerY + math.sin(a1) * radius,
				centerX + math.cos(a2) * radius, centerY + math.sin(a2) * radius
			)
		end
	end

	-- Draw nodes
	for i, node in ipairs(data.nodes) do
		if progress > node.discovered then
			surface.SetDrawColor(0, 255, 100, 80)
			surface.DrawLine(centerX, centerY, node.x, node.y)
			local nodeComplete = progress > node.discovered + 0.15
			local col = nodeComplete and Color(0, 255, 100) or Color(255, 200, 0)
			surface.SetDrawColor(col.r, col.g, col.b, 255)
			surface.DrawRect(node.x - 2, node.y - 2, 4, 4)
		end
	end

	-- Header
	draw.SimpleText("◢ NETWORK SCAN", "DefaultSmall", w / 2, 3, Color(0, 255, 255), TEXT_ALIGN_CENTER)
	draw.SimpleText(string.format("NODES: %d/%d", math.floor(progress * #data.nodes), #data.nodes), "DefaultSmall", w / 2, 14, Color(0, 200, 255), TEXT_ALIGN_CENTER)

	-- Progress bar
	local barW, barH = w - 20, 8
	local barX, barY = 10, h - 12
	surface.SetDrawColor(0, 50, 60, 200)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(0, 255, 100, 255)
	surface.DrawRect(barX, barY, barW * progress, barH)
	surface.SetDrawColor(0, 255, 255, 255)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	draw.SimpleText(math.floor(progress * 100) .. "%", "DefaultSmall", w / 2, barY - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Animation: Decrypt Data (scaled for viewmodel screen)
local function DrawDecryptAnimation(weapon, w, h, progress, rt)
	-- Initialize decrypt data
	if not weapon.AnimationData.blocks then
		weapon.AnimationData.blocks = {}
		for row = 0, 7 do
			weapon.AnimationData.blocks[row] = {}
			for col = 0, 15 do
				weapon.AnimationData.blocks[row][col] = {
					decrypted = string.char(math.random(65, 90)),
					decryptTime = math.random() * 0.9
				}
			end
		end
	end

	local data = weapon.AnimationData
	local startX, startY = 5, 28
	local blockW, blockH = 16, 13

	-- Header
	draw.SimpleText("◢ DECRYPTING", "DefaultSmall", w / 2, 3, Color(0, 255, 255), TEXT_ALIGN_CENTER)
	draw.SimpleText("AES-256", "DefaultSmall", w / 2, 14, Color(0, 200, 255), TEXT_ALIGN_CENTER)

	-- Draw decryption matrix
	for row = 0, 7 do
		for col = 0, 15 do
			local block = data.blocks[row][col]
			local x = startX + col * blockW
			local y = startY + row * blockH
			local isDecrypted = progress > block.decryptTime

			if isDecrypted then
				surface.SetDrawColor(0, 60, 30, 200)
				surface.DrawRect(x, y, blockW - 1, blockH - 1)
				draw.SimpleText(block.decrypted, "DefaultSmall", x + 4, y, Color(0, 255, 100), TEXT_ALIGN_LEFT)
			else
				local displayHex = RandomHex(2)
				surface.SetDrawColor(40, 25, 0, 180)
				surface.DrawRect(x, y, blockW - 1, blockH - 1)
				draw.SimpleText(displayHex, "DefaultSmall", x + 1, y, Color(255, 150, 0, 180), TEXT_ALIGN_LEFT)
			end
		end
	end

	-- Progress bar
	local barW, barH = w - 20, 8
	local barX, barY = 10, h - 12
	surface.SetDrawColor(0, 50, 60, 200)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(0, 255, 100, 255)
	surface.DrawRect(barX, barY, barW * progress, barH)
	surface.SetDrawColor(0, 255, 255, 255)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	draw.SimpleText(math.floor(progress * 100) .. "%", "DefaultSmall", w / 2, barY - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Animation: Run Exploit (scaled for viewmodel screen)
local function DrawExploitAnimation(weapon, w, h, progress, rt)
	-- Initialize exploit data
	if not weapon.AnimationData.exploitStages then
		weapon.AnimationData.exploitStages = {
			{ name = "SCANNING...", threshold = 0.15 },
			{ name = "CVE FOUND", threshold = 0.30 },
			{ name = "PAYLOAD", threshold = 0.50 },
			{ name = "INJECTING", threshold = 0.70 },
			{ name = "ESCALATE", threshold = 0.85 },
			{ name = "SUCCESS!", threshold = 0.98 }
		}
	end

	local data = weapon.AnimationData
	local centerX = w / 2

	-- Header with warning flash
	local headerAlpha = 200 + math.sin(rt * 8) * 55
	draw.SimpleText("⚠ EXPLOIT ⚠", "DefaultSmall", centerX, 3, Color(255, 100, 0, headerAlpha), TEXT_ALIGN_CENTER)

	-- Scrolling hex on left side
	for i = 0, 8 do
		local offset = ((rt * 40 + i * 15) % 120)
		local y = 18 + offset
		if y < h - 20 then
			local alpha = 200 - offset * 1.5
			draw.SimpleText(RandomHex(8), "DefaultSmall", 5, y, Color(255, 150, 0, alpha), TEXT_ALIGN_LEFT)
		end
	end

	-- Exploit stages in center
	local stageY = 20
	for i, stage in ipairs(data.exploitStages) do
		local isComplete = progress >= stage.threshold
		local isActive = progress >= stage.threshold - 0.15 and progress < stage.threshold

		local col
		if isComplete then
			col = Color(0, 255, 100)
		elseif isActive then
			col = Color(255, 200, 0, 150 + math.sin(rt * 10) * 100)
		else
			col = Color(100, 100, 100, 150)
		end

		local prefix = isComplete and "✓" or (isActive and "►" or "○")
		draw.SimpleText(prefix .. " " .. stage.name, "DefaultSmall", centerX + 20, stageY + (i - 1) * 14, col, TEXT_ALIGN_LEFT)
	end

	-- Memory addresses on right
	for i = 0, 6 do
		local addr = string.format("%04X", 0x7FFE + i * 0x10)
		local isInjected = progress > 0.5 and i >= 2 and i <= 4
		local col = isInjected and Color(255, 0, 0, 150 + math.sin(rt * 5 + i) * 100) or Color(0, 150, 100, 80)
		draw.SimpleText(addr, "DefaultSmall", w - 35, 18 + i * 12, col, TEXT_ALIGN_LEFT)
	end

	-- Progress bar
	local barW, barH = w - 20, 8
	local barX, barY = 10, h - 12
	surface.SetDrawColor(50, 20, 0, 200)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(255, math.floor(100 + progress * 100), 0, 255)
	surface.DrawRect(barX, barY, barW * progress, barH)
	surface.SetDrawColor(255, 150, 0, 255)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	draw.SimpleText(math.floor(progress * 100) .. "%", "DefaultSmall", centerX, barY - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Animation: Install Backdoor (scaled for viewmodel screen)
local function DrawBackdoorAnimation(weapon, w, h, progress, rt)
	if not weapon.AnimationData.files then
		weapon.AnimationData.files = {
			{ name = "/etc/passwd", infected = 0.15 },
			{ name = "/bin/sudo", infected = 0.30 },
			{ name = "/bin/bash", infected = 0.50 },
			{ name = "/usr/sshd", infected = 0.70 },
			{ name = "/boot/vmlinuz", infected = 0.85 }
		}
	end

	local data = weapon.AnimationData
	local centerX = w / 2

	-- Header
	local headerFlash = math.sin(rt * 4) > 0
	draw.SimpleText("☠ BACKDOOR", "DefaultSmall", centerX, 3, headerFlash and Color(255, 0, 100) or Color(200, 0, 80), TEXT_ALIGN_CENTER)
	draw.SimpleText("IMPLANTING SHELL", "DefaultSmall", centerX, 14, Color(255, 100, 100), TEXT_ALIGN_CENTER)

	-- File infection visualization
	local fileY = 28
	for i, file in ipairs(data.files) do
		local isInfected = progress >= file.infected
		local isInfecting = progress >= file.infected - 0.1 and not isInfected

		local statusChar, statusCol
		if isInfected then
			statusChar = "☠"
			statusCol = Color(255, 0, 100)
		elseif isInfecting then
			statusChar = "►"
			statusCol = Color(255, 200, 0, 150 + math.sin(rt * 12) * 100)
		else
			statusChar = "○"
			statusCol = Color(100, 100, 100)
		end

		draw.SimpleText(statusChar, "DefaultSmall", 8, fileY, statusCol, TEXT_ALIGN_LEFT)
		draw.SimpleText(file.name, "DefaultSmall", 22, fileY, isInfected and Color(255, 100, 100) or Color(150, 150, 150), TEXT_ALIGN_LEFT)
		fileY = fileY + 13
	end

	-- Payload hex on right side
	for i = 0, 6 do
		local hexLine = RandomHex(8)
		local lineProgress = (i / 6)
		local lineAlpha = progress > lineProgress and 200 or 40
		draw.SimpleText(hexLine, "DefaultSmall", w - 55, 28 + i * 12, Color(255, 0, 100, lineAlpha), TEXT_ALIGN_LEFT)
	end

	-- C2 status
	local shellAlpha = 150 + math.sin(rt * 3) * 100
	draw.SimpleText("C2: ACTIVE", "DefaultSmall", centerX, h - 25, Color(0, 255, 100, shellAlpha), TEXT_ALIGN_CENTER)

	-- Progress bar
	local barW, barH = w - 20, 8
	local barX, barY = 10, h - 12
	surface.SetDrawColor(50, 0, 30, 200)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(255, 0, 100, 255)
	surface.DrawRect(barX, barY, barW * progress, barH)
	surface.SetDrawColor(255, 100, 150, 255)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	draw.SimpleText(math.floor(progress * 100) .. "%", "DefaultSmall", centerX, barY - 1, Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Animation: Clear Logs (scaled for viewmodel screen)
local function DrawLogsAnimation(weapon, w, h, progress, rt)
	if not weapon.AnimationData.logFiles then
		weapon.AnimationData.logFiles = {
			{ name = "auth.log", lines = math.random(500, 2000) },
			{ name = "syslog", lines = math.random(1000, 5000) },
			{ name = "kern.log", lines = math.random(200, 800) },
			{ name = "secure", lines = math.random(100, 500) },
			{ name = ".history", lines = math.random(100, 1000) }
		}
		weapon.AnimationData.totalLines = 0
		for _, f in ipairs(weapon.AnimationData.logFiles) do
			weapon.AnimationData.totalLines = weapon.AnimationData.totalLines + f.lines
		end
	end

	local data = weapon.AnimationData
	local centerX = w / 2

	-- Header
	draw.SimpleText("◢ CLEAR LOGS", "DefaultSmall", centerX, 3, Color(255, 200, 0), TEXT_ALIGN_CENTER)
	draw.SimpleText("SANITIZING...", "DefaultSmall", centerX, 14, Color(255, 150, 0), TEXT_ALIGN_CENTER)

	-- Log file deletion visualization
	local fileY = 28
	local clearedLines = 0

	for i, logFile in ipairs(data.logFiles) do
		local fileProgress = (i - 1) / #data.logFiles
		local nextFileProgress = i / #data.logFiles
		local isCleared = progress >= nextFileProgress
		local isClearing = progress >= fileProgress and progress < nextFileProgress
		local localProgress = isClearing and ((progress - fileProgress) / (1 / #data.logFiles)) or (isCleared and 1 or 0)

		if isCleared then
			clearedLines = clearedLines + logFile.lines
		elseif isClearing then
			clearedLines = clearedLines + math.floor(logFile.lines * localProgress)
		end

		local statusChar, statusCol
		if isCleared then
			statusChar = "✗"
			statusCol = Color(100, 100, 100)
		elseif isClearing then
			statusChar = "►"
			statusCol = Color(255, 200, 0, 150 + math.sin(rt * 15) * 100)
		else
			statusChar = "○"
			statusCol = Color(200, 200, 200)
		end

		draw.SimpleText(statusChar, "DefaultSmall", 8, fileY, statusCol, TEXT_ALIGN_LEFT)
		local nameCol = isCleared and Color(80, 80, 80) or Color(255, 200, 100)
		draw.SimpleText(logFile.name, "DefaultSmall", 22, fileY, nameCol, TEXT_ALIGN_LEFT)

		-- Strikethrough for cleared
		if isCleared then
			surface.SetDrawColor(100, 100, 100)
			surface.DrawLine(22, fileY + 5, 80, fileY + 5)
		end

		fileY = fileY + 13
	end

	-- Scrolling deleted log entries on right
	for i = 0, 5 do
		local yOff = (rt * 60 + i * 15) % 90
		local alpha = 180 - yOff * 2
		if alpha > 0 then
			local fakeTime = string.format("%02d:%02d", math.random(0, 23), math.random(0, 59))
			draw.SimpleText(fakeTime, "DefaultSmall", w - 45, 28 + yOff, Color(255, 100, 100, alpha), TEXT_ALIGN_LEFT)
		end
	end

	-- Lines removed counter
	draw.SimpleText(string.format("%d/%d", clearedLines, data.totalLines), "DefaultSmall", centerX, h - 25, Color(255, 200, 0), TEXT_ALIGN_CENTER)

	-- Progress bar
	local barW, barH = w - 20, 8
	local barX, barY = 10, h - 12
	surface.SetDrawColor(50, 40, 0, 200)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(255, 200, 0, 255)
	surface.DrawRect(barX, barY, barW * progress, barH)
	surface.SetDrawColor(255, 220, 100, 255)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	draw.SimpleText(math.floor(progress * 100) .. "%", "DefaultSmall", centerX, barY - 1, Color(0, 0, 0), TEXT_ALIGN_CENTER)
end

-- Animation: Disconnect (scaled for viewmodel screen)
local function DrawDisconnectAnimation(weapon, w, h, progress, rt)
	local centerX, centerY = w / 2, h / 2 + 5

	-- Glitch effect intensifies with progress
	local glitchIntensity = progress * 5

	-- Draw disconnecting visualization
	if progress < 0.8 then
		-- Header with glitch chromatic aberration
		local glitchOff = math.random(-1, 1) * glitchIntensity
		draw.SimpleText("DISCONNECT", "DefaultSmall", centerX + glitchOff, 3, Color(255, 0, 0, 150), TEXT_ALIGN_CENTER)
		draw.SimpleText("DISCONNECT", "DefaultSmall", centerX - glitchOff, 3, Color(0, 0, 255, 150), TEXT_ALIGN_CENTER)
		draw.SimpleText("DISCONNECT", "DefaultSmall", centerX, 3, Color(255, 100, 100), TEXT_ALIGN_CENTER)

		draw.SimpleText("CLOSING...", "DefaultSmall", centerX, 14, Color(255, 200, 0), TEXT_ALIGN_CENTER)

		-- Connection lines breaking apart
		local numLines = 6
		local breakApart = progress * 15
		for i = 1, numLines do
			local angle = (i / numLines) * math.pi * 2 + rt
			local innerR = 10 + progress * 10
			local outerR = 40 - progress * 20

			local x1 = centerX + math.cos(angle) * innerR
			local y1 = centerY + math.sin(angle) * innerR
			local x2 = centerX + math.cos(angle) * outerR + math.random(-1, 1) * breakApart
			local y2 = centerY + math.sin(angle) * outerR + math.random(-1, 1) * breakApart

			local alpha = 255 - progress * 250
			surface.SetDrawColor(0, 255, 255, alpha)
			surface.DrawLine(x1, y1, x2, y2)
			surface.DrawRect(x2 - 1, y2 - 1, 3, 3)
		end

		-- Center dot
		local dotSize = math.max(1, 4 - progress * 4)
		surface.SetDrawColor(255, 100, 100, 200)
		surface.DrawRect(centerX - dotSize, centerY - dotSize, dotSize * 2, dotSize * 2)

		-- IP being obscured
		local ipParts = {"192", "168", "1", "1"}
		local ipStr = ""
		for i, part in ipairs(ipParts) do
			local showPart = progress < (i / 5) * 0.7
			ipStr = ipStr .. (showPart and part or "***")
			if i < 4 then ipStr = ipStr .. "." end
		end
		draw.SimpleText(ipStr, "DefaultSmall", centerX, h - 25, Color(0, 255, 100, 200 - progress * 200), TEXT_ALIGN_CENTER)
	else
		-- Final disconnect - screen going dark with static
		local fadeProgress = (progress - 0.8) / 0.2

		-- Fade background
		surface.SetDrawColor(0, 0, 0, fadeProgress * 220)
		surface.DrawRect(0, 0, w, h)

		-- Static noise
		for i = 1, 80 do
			local x = math.random(0, w)
			local y = math.random(0, h)
			local brightness = math.random(0, 80) * (1 - fadeProgress)
			surface.SetDrawColor(brightness, brightness, brightness, 255)
			surface.DrawRect(x, y, 1, 1)
		end

		-- Terminal message
		local alpha = math.sin(rt * 5) * 100 + 155
		draw.SimpleText("TERMINATED", "DefaultSmall", centerX, centerY, Color(255, 0, 0, alpha * (1 - fadeProgress * 0.5)), TEXT_ALIGN_CENTER)
	end

	-- Progress bar (fading out)
	local barAlpha = math.floor(255 - progress * 200)
	if barAlpha > 0 then
		local barW, barH = w - 20, 8
		local barX, barY = 10, h - 12
		surface.SetDrawColor(30, 30, 30, barAlpha)
		surface.DrawRect(barX, barY, barW, barH)
		surface.SetDrawColor(255, 100, 100, barAlpha)
		surface.DrawRect(barX, barY, barW * progress, barH)
		surface.SetDrawColor(255, 150, 150, barAlpha)
		surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	end
end

-- Main animation dispatcher - stored on SWEP so draw_func can access it
SWEP.AnimationDrawFuncs = {
	scan = DrawScanAnimation,
	decrypt = DrawDecryptAnimation,
	exploit = DrawExploitAnimation,
	backdoor = DrawBackdoorAnimation,
	logs = DrawLogsAnimation,
	disconnect = DrawDisconnectAnimation
}

-- DrawHUD hook - only used to detect animation completion
function SWEP:DrawHUD()
	-- Check if animation just completed
	if self.ActiveAnimation and not self:IsAnimationPlaying() then
		self:EndAnimation()
		self.StatusMessage = "OPERATION COMPLETE"
		self.StatusMessageTime = RealTime() + 2
		self:EmitSound("buttons/button15.wav", 60, 120)
	end
end

end -- End CLIENT block

SWEP.VElements = {
	["quad_screen"] = { type = "Quad", bone = "v_weapon.Right_Hand", rel = "mdl_console", pos = Vector(-0.626, 1.615, 0.252), angle = Angle(0, 90, 0), size = 0.01, draw_func = function( weapon )

			-- Screen dimensions
			local w, h = 270, 170
			local rt = RealTime()

			-- ============================================================
			-- CHECK FOR ANIMATION - RENDER ANIMATION INSTEAD OF MENU
			-- ============================================================
			if weapon:IsAnimationPlaying() then
				local progress = weapon:GetAnimationProgress()

				-- Dark background
				surface.SetDrawColor(0, 8, 12, 240)
				surface.DrawRect(0, 0, w, h)

				-- Grid overlay
				surface.SetDrawColor(0, 60, 80, 25)
				for i = 0, w, 20 do
					surface.DrawLine(i, 0, i, h)
				end
				for i = 0, h, 20 do
					surface.DrawLine(0, i, w, i)
				end

				-- Scanline
				local scanY = (rt * 40) % h
				surface.SetDrawColor(0, 255, 255, 30)
				surface.DrawRect(0, scanY, w, 2)

				-- Draw the specific animation
				local drawFunc = weapon.AnimationDrawFuncs and weapon.AnimationDrawFuncs[weapon.ActiveAnimation]
				if drawFunc then
					drawFunc(weapon, w, h, progress, rt)
				end

				-- Border glow
				local glowAlpha = 150 + math.sin(rt * 4) * 50
				surface.SetDrawColor(0, 255, 255, glowAlpha)
				surface.DrawOutlinedRect(0, 0, w, h, 2)

				-- Corner decorations
				surface.SetDrawColor(0, 255, 255, 200)
				surface.DrawLine(0, 0, 10, 0)
				surface.DrawLine(0, 0, 0, 10)
				surface.DrawLine(w - 10, 0, w, 0)
				surface.DrawLine(w, 0, w, 10)
				surface.DrawLine(0, h - 10, 0, h)
				surface.DrawLine(0, h, 10, h)
				surface.DrawLine(w - 10, h, w, h)
				surface.DrawLine(w, h - 10, w, h)

				-- Draw HUD overlay even during animations
				if ZDEV_DrawHackerScreenHUD then
					ZDEV_DrawHackerScreenHUD(weapon, w, h, rt)
				end

				return -- Don't draw menu when animation is playing
			end

			-- ============================================================
			-- NORMAL MENU RENDERING
			-- ============================================================

			-- Get menu state from weapon
			local selectedIndex = weapon.MenuSelectedIndex or 1
			local menuStack = weapon.MenuStack or { MenuData }
			local rawMenu = menuStack[#menuStack] or MenuData
			local currentMenu = weapon:GetFilteredMenu(rawMenu)
			local statusMessage = weapon.StatusMessage or "READY"
			local statusTime = weapon.StatusMessageTime or 0

			-- Background with animated noise
			local bgAlpha = 220 + math.sin(rt * 3) * 20
			surface.SetDrawColor( 0, 12, 18, bgAlpha )
			surface.DrawRect( 0, 0, w, h )

			-- Animated grid overlay (subtle)
			surface.SetDrawColor( 0, 80, 100, 20 + math.sin(rt * 2) * 8 )
			for i = 0, w, 25 do
				surface.DrawLine( i, 0, i, h )
			end
			for i = 0, h, 25 do
				surface.DrawLine( 0, i, w, i )
			end

			-- Glitch effect bars (random horizontal lines)
			if math.random() > 0.85 then
				local glitchY = math.random(0, h)
				local glitchH = math.random(1, 4)
				surface.SetDrawColor( 0, 255, 200, math.random(30, 100) )
				surface.DrawRect( 0, glitchY, w, glitchH )
			end

			-- Top header bar
			surface.SetDrawColor( 0, 150, 180, 200 )
			surface.DrawRect( 0, 0, w, 16 )
			surface.SetDrawColor( 0, 255, 255, 255 )
			surface.DrawOutlinedRect( 0, 0, w, 16, 1 )

			-- Header text
			draw.SimpleText( "◢ HACKER TERMINAL v3.7", "DefaultSmall", 5, 1, Color(0, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

			-- Status indicator (pulsing)
			local pulseAlpha = 150 + math.sin(rt * 5) * 105
			draw.SimpleText( "●", "DefaultSmall", w - 12, 1, Color(0, 255, 100, pulseAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

			-- Main content area border
			surface.SetDrawColor( 0, 180, 200, 120 )
			surface.DrawOutlinedRect( 4, 20, w - 8, h - 38, 1 )

			-- Menu title bar
			local menuTitle = #menuStack > 1 and "◄ SUBMENU" or "MAIN MENU"
			surface.SetDrawColor( 0, 100, 120, 150 )
			surface.DrawRect( 5, 21, w - 10, 12 )
			draw.SimpleText( menuTitle, "DefaultSmall", 10, 22, Color(0, 200, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

			-- ============================================================
			-- MENU ITEMS
			-- ============================================================
			local menuStartY = 35
			local itemHeight = 16
			local maxVisibleItems = 6

			-- Calculate scroll offset if needed
			local scrollOffset = 0
			if selectedIndex > maxVisibleItems then
				scrollOffset = selectedIndex - maxVisibleItems
			end

			for i = 1, math.min(#currentMenu, maxVisibleItems) do
				local menuIndex = i + scrollOffset
				local item = currentMenu[menuIndex]
				if not item then break end

				local itemY = menuStartY + (i - 1) * itemHeight
				local isSelected = (menuIndex == selectedIndex)

				-- Item background
				if isSelected then
					-- Selected item - dark background with green glow
					surface.SetDrawColor( 0, 80, 60, 180 )
					surface.DrawRect( 8, itemY, w - 16, itemHeight - 2 )

					-- Animated green border (selected highlight)
					local borderAlpha = 200 + math.sin(rt * 8) * 55
					surface.SetDrawColor( 0, 255, 100, borderAlpha )
					surface.DrawOutlinedRect( 8, itemY, w - 16, itemHeight - 2, 2 )

					-- Selection indicator arrow
					draw.SimpleText( "►", "DefaultSmall", 12, itemY + 1, Color(0, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

					-- Item text (bright green when selected)
					draw.SimpleText( item.name, "DefaultSmall", 24, itemY + 1, Color(0, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				else
					-- Non-selected item - subtle background
					surface.SetDrawColor( 0, 40, 50, 100 )
					surface.DrawRect( 8, itemY, w - 16, itemHeight - 2 )

					-- Subtle border
					surface.SetDrawColor( 0, 100, 120, 80 )
					surface.DrawOutlinedRect( 8, itemY, w - 16, itemHeight - 2, 1 )

					-- Item text (cyan when not selected)
					draw.SimpleText( item.name, "DefaultSmall", 24, itemY + 1, Color(0, 180, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				end
			end

			-- Scroll indicators if needed
			if scrollOffset > 0 then
				draw.SimpleText( "▲", "DefaultSmall", w - 15, menuStartY - 2, Color(0, 255, 255, 150 + math.sin(rt * 4) * 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			end
			if #currentMenu > maxVisibleItems + scrollOffset then
				draw.SimpleText( "▼", "DefaultSmall", w - 15, menuStartY + maxVisibleItems * itemHeight - 12, Color(0, 255, 255, 150 + math.sin(rt * 4) * 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			end

			-- Animated scanline
			local scanY = (rt * 60) % h
			surface.SetDrawColor( 0, 255, 255, 40 )
			surface.DrawRect( 5, scanY, w - 10, 1 )

			-- ============================================================
			-- BOTTOM STATUS BAR
			-- ============================================================
			local bottomY = h - 16
			surface.SetDrawColor( 0, 80, 100, 180 )
			surface.DrawRect( 0, bottomY, w, 16 )
			surface.SetDrawColor( 0, 200, 220, 150 )
			surface.DrawLine( 0, bottomY, w, bottomY )

			-- Show status message or controls hint
			local displayText
			if statusTime > RealTime() then
				displayText = statusMessage
				local msgColor = Color(0, 255, 100, 255)
				draw.SimpleText( displayText, "DefaultSmall", w / 2, bottomY + 2, msgColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			else
				-- Controls hint
				draw.SimpleText( "[E]▲ [R]▼ [LMB]SELECT [RMB]BACK", "DefaultSmall", w / 2, bottomY + 2, Color(0, 150, 180, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			end

			-- Corner decorations (cyberpunk style)
			surface.SetDrawColor( 0, 255, 255, 180 )
			surface.DrawLine( 0, 0, 8, 0 )
			surface.DrawLine( 0, 0, 0, 8 )
			surface.DrawLine( w - 8, 0, w, 0 )
			surface.DrawLine( w, 0, w, 8 )
			surface.DrawLine( 0, h - 8, 0, h )
			surface.DrawLine( 0, h, 8, h )
			surface.DrawLine( w - 8, h, w, h )
			surface.DrawLine( w, h - 8, w, h )

			-- Chromatic aberration effect on edges (subtle)
			surface.SetDrawColor( 255, 0, 0, 15 )
			surface.DrawOutlinedRect( -1, -1, w + 2, h + 2, 1 )
			surface.SetDrawColor( 0, 0, 255, 15 )
			surface.DrawOutlinedRect( 1, 1, w - 2, h - 2, 1 )

			-- ============================================================
			-- DRAW HUD OVERLAY (lock status, signal, target info)
			-- ============================================================
			if ZDEV_DrawHackerScreenHUD then
				ZDEV_DrawHackerScreenHUD(weapon, w, h, rt)
			end

		end },
	["mdl_console"] = { type = "Model", model = "models/lt_c/sci_fi/holo_tablet.mdl", bone = "v_weapon.Right_Hand", rel = "", pos = Vector(-2.875, 0.625, 2.407), angle = Angle(-5.317, 101.666, 28.955), size = Vector(0.307, 0.307, 0.307), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 1, bodygroup = {[1] = 1} }
}

-- ============================================================================
-- PERFORMANCE OPTIMIZATIONS
-- ============================================================================

-- Cache frequently used functions for performance
local CurTime = CurTime
local IsValid = IsValid
local IsFirstTimePredicted = IsFirstTimePredicted

-- ============================================================================
-- MENU INPUT HANDLING
-- ============================================================================

-- Get filtered menu (handles dynamic items like TARGET COMMANDS)
function SWEP:GetFilteredMenu(menu)
	local filtered = {}
	for _, item in ipairs(menu) do
		local show = true
		-- Check if item is dynamic (only show when locked)
		if item.dynamic then
			show = self.LockedTarget ~= nil
		end
		if show then
			table.insert(filtered, item)
		end
	end
	return filtered
end

-- Menu navigation: Move selection up
function SWEP:MenuNavigateUp()
	if not self.MenuSelectedIndex then self.MenuSelectedIndex = 1 end
	local rawMenu = self.MenuStack and self.MenuStack[#self.MenuStack] or MenuData
	local currentMenu = self:GetFilteredMenu(rawMenu)

	self.MenuSelectedIndex = self.MenuSelectedIndex - 1
	if self.MenuSelectedIndex < 1 then
		self.MenuSelectedIndex = #currentMenu -- Wrap to bottom
	end

	self:EmitSound("buttons/button14.wav", 50, 150)
end

-- Menu navigation: Move selection down
function SWEP:MenuNavigateDown()
	if not self.MenuSelectedIndex then self.MenuSelectedIndex = 1 end
	local rawMenu = self.MenuStack and self.MenuStack[#self.MenuStack] or MenuData
	local currentMenu = self:GetFilteredMenu(rawMenu)

	self.MenuSelectedIndex = self.MenuSelectedIndex + 1
	if self.MenuSelectedIndex > #currentMenu then
		self.MenuSelectedIndex = 1 -- Wrap to top
	end

	self:EmitSound("buttons/button14.wav", 50, 150)
end

-- Menu navigation: Select current item
function SWEP:MenuSelect()
	if not self.MenuSelectedIndex then self.MenuSelectedIndex = 1 end
	if not self.MenuStack then self.MenuStack = { MenuData } end

	local rawMenu = self.MenuStack[#self.MenuStack]
	local currentMenu = self:GetFilteredMenu(rawMenu)
	local selectedItem = currentMenu[self.MenuSelectedIndex]

	if not selectedItem then return end

	self:EmitSound("buttons/button9.wav", 50, 120)

	-- Check if item has a submenu
	if selectedItem.submenu then
		table.insert(self.MenuStack, selectedItem.submenu)
		self.MenuSelectedIndex = 1
		self.StatusMessage = "ENTERING: " .. selectedItem.name
		self.StatusMessageTime = RealTime() + 1.5
	-- Otherwise execute the action
	elseif selectedItem.action then
		selectedItem.action(self)
		self.StatusMessage = "EXECUTING: " .. selectedItem.name
		self.StatusMessageTime = RealTime() + 2
	end
end

-- Menu navigation: Go back / Cancel
function SWEP:MenuBack()
	if not self.MenuStack then self.MenuStack = { MenuData } end

	if #self.MenuStack > 1 then
		table.remove(self.MenuStack)
		self.MenuSelectedIndex = 1
		self:EmitSound("buttons/button10.wav", 50, 100)
		self.StatusMessage = "◄ BACK"
		self.StatusMessageTime = RealTime() + 1
	else
		self:EmitSound("buttons/button8.wav", 50, 80)
		self.StatusMessage = "CANNOT GO BACK - ROOT MENU"
		self.StatusMessageTime = RealTime() + 1
	end
end

-- ============================================================================
-- THINK - Input Processing
-- ============================================================================

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if not owner:IsPlayer() then return end

	-- Block menu navigation during animation playback
	if self:IsAnimationPlaying() then return end

	-- Initialize menu state if needed
	if not self.MenuSelectedIndex then self.MenuSelectedIndex = 1 end
	if not self.MenuStack then self.MenuStack = { MenuData } end
	if not self.NextInputTime then self.NextInputTime = 0 end

	local ct = CurTime()

	-- Check for input (only process if cooldown has passed)
	if ct >= self.NextInputTime then
		-- E key = Navigate Up
		if owner:KeyDown(IN_USE) then
			self:MenuNavigateUp()
			self.NextInputTime = ct + InputCooldown
		-- R key = Navigate Down
		elseif owner:KeyDown(IN_RELOAD) then
			self:MenuNavigateDown()
			self.NextInputTime = ct + InputCooldown
		end
	end
end

-- ============================================================================
-- PRIMARY ATTACK - Select Menu Item
-- ============================================================================

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.3)

	-- Block input during animation
	if self:IsAnimationPlaying() then return end

	self:MenuSelect()
end

-- ============================================================================
-- SECONDARY ATTACK - Go Back / Cancel
-- ============================================================================

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.3)

	-- Allow canceling animation with right click
	if self:IsAnimationPlaying() then
		self:EndAnimation()
		self.StatusMessage = "OPERATION CANCELLED"
		self.StatusMessageTime = RealTime() + 2
		self:EmitSound("buttons/button10.wav", 60, 80)
		return
	end

	self:MenuBack()
end

-- ============================================================================
-- RELOAD - Override to prevent default behavior
-- ============================================================================

function SWEP:Reload()
	-- Reload is used for menu navigation (down), so prevent default reload
	return false
end

-- ============================================================================
-- DEPLOYMENT AND HOLSTERING
-- ============================================================================

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

	-- Reset menu state on deploy
	self.MenuSelectedIndex = 1
	self.MenuStack = { MenuData }
	self.StatusMessage = "SYSTEM READY"
	self.StatusMessageTime = RealTime() + 2

	return true
end

function SWEP:Holster()
	-- Clean up menu state
	self.MenuSelectedIndex = 1
	self.MenuStack = { MenuData }

	return true
end

function SWEP:OnRemove()
	self:Holster()
end

--[[
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378

	DESCRIPTION:
		This script is meant for experienced scripters
		that KNOW WHAT THEY ARE DOING. Don't come to me
		with basic Lua questions.

		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.

		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
]]

function SWEP:Initialize()
	-- Set hold type
	self:SetHoldType(self.HoldType or "pistol")

	-- Initialize menu state
	self.MenuSelectedIndex = 1
	self.MenuStack = { MenuData }
	self.NextInputTime = 0
	self.StatusMessage = "INITIALIZING..."
	self.StatusMessageTime = RealTime() + 2

	if CLIENT then
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels

		-- init view model bone build function
		local owner = self:GetOwner()
		if IsValid(owner) then
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)

				-- Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					-- stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency
					-- however for some reason the view model resets to render mode 0 every frame so we apply a debug material
					vm:SetMaterial("Debug/hsv")
				end
			end
		end
	end
end

function SWEP:Holster()
	-- Clean up menu state
	self.MenuSelectedIndex = 1
	self.MenuStack = { MenuData }

	if CLIENT then
		local owner = self:GetOwner()
		if IsValid(owner) then
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
			end
		end
	end

	return true
end

function SWEP:OnRemove()
	self:Holster()
end

