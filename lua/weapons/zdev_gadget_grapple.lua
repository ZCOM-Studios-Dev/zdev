--[[
	ZDEV Grapple Hook Gadget

	A grappling hook weapon that allows players to attach a cable to surfaces
	and pull themselves towards the target position.
]]

-- ============================================================================
-- SWEP METADATA
-- ============================================================================

SWEP.Base = "weapon_base"

-- Spawn Menu Information
SWEP.PrintName = "Grapple Hook"
SWEP.Author = "ZDEV"
SWEP.Contact = ""
SWEP.Purpose = "Generic hacking tool framework"
SWEP.Instructions = "Left click to use, Right click for secondary function"
SWEP.Category = "ZDEV"
SWEP.Spawnable = true
SWEP.AdminOnly = false

-- ============================================================================
-- MODELS AND VIEWMODEL
-- ============================================================================

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.UseHands = true

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

SWEP.Primary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false
}

-- ============================================================================
-- SECONDARY ATTACK SETTINGS
-- ============================================================================

SWEP.Secondary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false
}

SWEP.NextThinkFloat = 0

-- ============================================================================
-- PERFORMANCE OPTIMIZATIONS
-- ============================================================================

-- Cache frequently used functions for performance
local CurTime = CurTime
local IsValid = IsValid
local IsFirstTimePredicted = IsFirstTimePredicted
local Vector = Vector

-- ============================================================================
-- GRAPPLE CONFIGURATION
-- ============================================================================

local GrappleConfig = {
	MaxDistance = 2000,       -- Maximum grapple range
	PullForce = 1800,          -- Force applied to pull player (units/sec)
	MinDistance = 100,        -- Distance at which grapple auto-releases
	CableWidth = 2,           -- Width of the cable beam
	CableColor = Color(100, 200, 255, 255), -- Cable color (light blue)
	HandBone = "ValveBiped.Bip01_R_Hand",   -- Right hand bone name
}

-- ============================================================================
-- NETWORKED VARIABLES (for grapple state sync)
-- ============================================================================

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Grappling")
	self:NetworkVar("Vector", 0, "GrappleTarget")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SWEP:Initialize()
	self:SetHoldType("pistol")

	-- Initialize weapon state
	self.NextThinkFloat = 0
	self.IsActive = false

	-- Initialize grapple state
	self:SetGrappling(false)
	self:SetGrappleTarget(Vector(0, 0, 0))
end

-- ============================================================================
-- DEPLOYMENT AND HOLSTERING
-- ============================================================================

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)

	return true
end

function SWEP:Holster()
	-- Release grapple on holster
	self:ReleaseGrapple()
	self.IsActive = false

	return true
end

function SWEP:OnRemove()
	-- Clean up resources
	self:Holster()
end

-- ============================================================================
-- THINK LOGIC
-- ============================================================================

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Handle grapple pulling (runs every frame for smooth movement)
	if self:GetGrappling() then
		self:HandleGrapplePull()
	end

	self:NextThink(CurTime())
	return true
end

function SWEP:HandleGrapplePull()
	local owner = self:GetOwner()
	if not IsValid(owner) then
		self:ReleaseGrapple()
		return
	end

	local targetPos = self:GetGrappleTarget()
	local playerPos = owner:GetPos()
	local direction = targetPos - playerPos
	local distance = direction:Length()

	-- Auto-release if close enough to target
	if distance < GrappleConfig.MinDistance then
		self:ReleaseGrapple()
		return
	end

	-- Calculate pull velocity
	direction:Normalize()
	local pullVelocity = direction * GrappleConfig.PullForce

	-- Apply velocity on server
	if SERVER then
		owner:SetVelocity(pullVelocity * FrameTime())
	end
end

-- ============================================================================
-- PRIMARY ATTACK
-- ============================================================================

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Set next attack time
	self:SetNextPrimaryFire(CurTime() + 0.5)

	-- Play animation
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	owner:SetAnimation(PLAYER_ATTACK1)

	-- Add your primary attack logic here
	if SERVER then
		-- Server-side logic
		self:DoPrimaryAction()
	end
end

function SWEP:DoPrimaryAction()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Already grappling? Don't fire again
	if self:GetGrappling() then return end

	-- Trace from player's eyes
	local trace = util.TraceLine({
		start = owner:EyePos(),
		endpos = owner:EyePos() + owner:GetAimVector() * GrappleConfig.MaxDistance,
		filter = owner,
		mask = MASK_SOLID
	})

	-- If we hit something, start grappling
	if trace.Hit and not trace.HitSky then
		self:SetGrappling(true)
		self:SetGrappleTarget(trace.HitPos)

		-- Play fire sound
		self:EmitSound("weapons/crossbow/bolt_fly4.wav", 75, 100)
	else
		-- Play miss sound
		self:EmitSound("buttons/button10.wav", 50, 100)
	end
end

-- ============================================================================
-- SECONDARY ATTACK
-- ============================================================================

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Set next attack time
	self:SetNextSecondaryFire(CurTime() + 1.0)

	-- Play animation
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	-- Add your secondary attack logic here
	if SERVER then
		-- Server-side logic
		self:DoSecondaryAction()
	end
end

function SWEP:DoSecondaryAction()
	-- Release/retract the grapple
	self:ReleaseGrapple()
end

function SWEP:ReleaseGrapple()
	if self:GetGrappling() then
		self:SetGrappling(false)
		self:SetGrappleTarget(Vector(0, 0, 0))

		-- Play retract sound
		self:EmitSound("weapons/crossbow/bolt_load2.wav", 75, 120)
	end
end

-- ============================================================================
-- RELOAD
-- ============================================================================

function SWEP:Reload()
	-- No reload needed for this weapon type
	-- Override if you need reload functionality
end

-- ============================================================================
-- CLIENT-SIDE RENDERING
-- ============================================================================

if CLIENT then

	-- Cache the cable material
	local CableMaterial = Material("cable/cable2")

	function SWEP:DrawHUD()
		-- Draw grapple status indicator
		if self:GetGrappling() then
			local scrW, scrH = ScrW(), ScrH()
			draw.SimpleText("GRAPPLING", "DermaLarge", scrW * 0.5, scrH * 0.85, GrappleConfig.CableColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	function SWEP:DoDrawCrosshair(x, y)
		-- Draw custom crosshair with grapple indicator
		local color = self:GetGrappling() and GrappleConfig.CableColor or Color(255, 255, 255, 255)

		surface.DrawCircle(x, y, 4, color.r, color.g, color.b, color.a)

		return true -- Suppress default crosshair
	end

	function SWEP:DrawWorldModel()
		-- Draw world model only (no cable here to avoid duplicates)
		self:DrawModel()
	end

	-- Use PreDrawOpaqueRenderables for cable rendering (works in both first and third person)
	hook.Add("PreDrawOpaqueRenderables", "ZDEV_GrappleCable", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then return end
		if wep:GetClass() ~= "zdev_gadget_grapple" then return end

		if wep.GetGrappling and wep:GetGrappling() and wep.DrawGrappleCable then
			wep:DrawGrappleCable()
		end
	end)

	function SWEP:GetHandPosition()
		-- Get the cable start position from viewmodel muzzle attachment
		local owner = self:GetOwner()
		if not IsValid(owner) then return nil end

		-- Use viewmodel muzzle attachment
		local vm = owner:GetViewModel()
		if IsValid(vm) then
			local attachment = vm:LookupAttachment("muzzle")
			if attachment and attachment > 0 then
				local attachData = vm:GetAttachment(attachment)
				if attachData then
					return attachData.Pos
				end
			end
		end

		-- Fallback: offset from eye position
		return owner:EyePos() + owner:GetAimVector() * 20 + owner:GetRight() * 5 - Vector(0, 0, 5)
	end

	function SWEP:DrawGrappleCable()
		local handPos = self:GetHandPosition()
		if not handPos then return end

		local targetPos = self:GetGrappleTarget()
		if targetPos == Vector(0, 0, 0) then return end

		-- Set up rendering
		render.SetMaterial(CableMaterial)

		-- Draw the beam from hand to target
		render.DrawBeam(
			handPos,
			targetPos,
			GrappleConfig.CableWidth,
			0,
			(handPos - targetPos):Length() / 32, -- Texture tiling
			GrappleConfig.CableColor
		)
	end

end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function SWEP:GetTargetEntity()
	-- Helper function to get the entity we're looking at
	local owner = self:GetOwner()
	if not IsValid(owner) then return nil end

	local trace = owner:GetEyeTrace()
	return trace.Entity
end

function SWEP:GetTargetPosition()
	-- Helper function to get the position we're looking at
	local owner = self:GetOwner()
	if not IsValid(owner) then return Vector(0, 0, 0) end

	local trace = owner:GetEyeTrace()
	return trace.HitPos
end

-- ============================================================================
-- NOTES
-- ============================================================================

--[[
	PERFORMANCE TIPS:

	1. Cache global functions locally (CurTime, IsValid, etc.)
	2. Use IsFirstTimePredicted() in attack functions to prevent duplicate calls
	3. Throttle Think() calls with a timer
	4. Minimize table allocations in frequently called functions
	5. Use SERVER/CLIENT checks to separate realm-specific code
	6. Avoid unnecessary trace calls - cache results when possible

	EXTENSION POINTS:

	- Override DoPrimaryAction() for custom primary attack behavior
	- Override DoSecondaryAction() for custom secondary attack behavior
	- Override Think() for continuous logic (remember to throttle)
	- Override DrawHUD() for custom HUD elements (CLIENT only)
	- Add custom networked variables in SetupDataTables()

	COMMON MODIFICATIONS:

	- Change hold type: self:SetHoldType("pistol"|"smg"|"ar2"|"shotgun"|"rpg"|"melee"|"grenade"|"slam")
	- Add sounds: self:EmitSound("sound/path.wav")
	- Add effects: util.Effect("effect_name", effectdata)
	- Network data: Use self:NetworkVar() in SetupDataTables()
]]
