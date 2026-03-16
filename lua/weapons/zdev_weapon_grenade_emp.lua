--[[
	ZDEV Flashbang Grenade Weapon (Single-file SWEP)

	An EMP grenade weapon derived from zdev_weapon_base_throwable.
	Spawns zdev_grenade_emp  entities when thrown.

	By ZCOM Studios
	Copyright (c) 2020-2026 by ZCOM Studios, All rights reserved.
]]

AddCSLuaFile()

SWEP.Base 							= "zdev_weapon_base_throwable"
SWEP.PrintName 						= "EMP Grenade"
SWEP.Author 						= "ZCOM Studios"
SWEP.Contact 						= "dev@zcom-studios.com"
SWEP.Purpose 						= "EMP grenade that disables electronics and blinds targets within its radius"
SWEP.Instructions 					= "Left-click to throw. Right-click to drop at your feet."
SWEP.Category           			= "ZDEV Weapons: Grenades"
SWEP.Spawnable 						= true
SWEP.AdminOnly 						= false

-- ============================================================================
-- WEAPON SLOT CONFIGURATION
-- ============================================================================

SWEP.HoldType 						= "slam"
SWEP.ViewModelFOV 					= 59.675891726405
SWEP.ViewModelFlip 					= true
SWEP.UseHands 						= true
SWEP.ViewModel 						= "models/weapons/cstrike/c_eq_flashbang.mdl"
SWEP.WorldModel 					= "models/weapons/w_eq_flashbang.mdl"
SWEP.ShowViewModel 					= true
SWEP.ShowWorldModel 				= false

SWEP.Weight 						= 3				-- Higher weight = higher priority-- Default  5
SWEP.AutoSwitchTo 					= true			-- Can auto-switch TO this weapon when picked up-- Default  true-- Can auto-switch TO this weapon when picked up-- Default  true
SWEP.AutoSwitchFrom 				= true				-- Can auto-switch FROM this weapon when out of ammo-- Default  true

SWEP.m_WeaponDeploySpeed 			= 1.0			-- Does not change internal deployment speed-- Default  GetConVar('sv_defaultdeployspeed'):GetFloat()
SWEP.DisableDuplicator 				= false			-- Disable duplicator support for this weapon-- Default  false
SWEP.m_bPlayPickupSound 			= true			-- Play weapon pickup sound when picked up-- Default  true

SWEP.BobScale 						= 1	-- Viewmodel bob scale (left-right movement when walking)-- Default  1
SWEP.SwayScale 						= 1	-- Viewmodel sway scale (position lerp when looking around)-- Default  1

SWEP.Slot 							= 4			-- Explosives slot
SWEP.SlotPos 						= 2		-- Position within slot

SWEP.DrawAmmo 						= true-- Draw default HL2 ammo counter Default: true
SWEP.DrawCrosshair 					= true-- Draw default crosshair Default: true
SWEP.DrawWeaponInfoBox 				= true-- Draw weapon selection info box (instructions, etc.) Default: true
SWEP.BounceWeaponIcon 				= false -- Bounce weapon icon in weapon selection Default: true

SWEP.AccurateCrosshair 				= false	-- Crosshair positioned in 3D space (like Jeep) Instead of center of screen-- Default  false
SWEP.CSMuzzleFlashes 				= false	-- Required for CS:S/DoD:S view models-- Default  false
SWEP.CSMuzzleX 						= false 

SWEP.Primary.Ammo 					= "grenade"
SWEP.Primary.ClipSize 				= 1
SWEP.Primary.DefaultClip 			= 3
SWEP.Primary.Automatic 				= false

SWEP.Secondary.Ammo 				= "none"
SWEP.Secondary.ClipSize 			= -1
SWEP.Secondary.DefaultClip 			= -1
SWEP.Secondary.Automatic 			= false

SWEP.Projectile                     = {}
SWEP.Projectile.WorldModel          = "models/conviction/empnade.mdl"
SWEP.Projectile.ViewModel           = "models/conviction/empnade.mdl"
SWEP.Projectile.VMSpriteMaterial    = "sprites/glow04"
SWEP.Projectile.VMSpriteScale       = 1
SWEP.Projectile.VMSpriteColor       = Color(180, 200, 255, 255)	-- Blue-white glow for flashbang
SWEP.Projectile.Entity              = "zdev_ent_grenade_emp"			-- The flashbang entity class
SWEP.Projectile.Velocity            = 1000

SWEP.ViewModelBoneMods = {
	["v_weapon.Flashbang_Parent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
SWEP.WElements = {
	["mdl_projectile_w"] = { type = "Model", model = SWEP.Projectile.WorldModel, bone = "ValveBiped.Anim_Attachment_RH", rel = "", pos = Vector(1.271, 1.21, -0.129), angle = Angle(-2.178, 20.454, -75.255), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["mdl_projectile"] = { type = "Model", model = SWEP.Projectile.ViewModel, bone = "v_weapon.Flashbang_Parent", rel = "", pos = Vector(1.866, 6.019, -0.509), angle = Angle(6.35, 14.298, -80.22), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["spr_projectile_fx"] = { type = "Sprite", sprite = SWEP.Projectile.VMSpriteMaterial, bone = "ValveBiped.Bip01_R_Hand", rel = "mdl_projectile", pos = Vector(-0.042, 0.962, 5.59), size = { x = SWEP.Projectile.VMSpriteScale, y = SWEP.Projectile.VMSpriteScale }, color = SWEP.Projectile.VMSpriteColor, nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}