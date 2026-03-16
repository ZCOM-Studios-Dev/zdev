--[[
    Flashbang Grenade SWEP
    Inherits from zdev_grenade_base.
    Blinds and deafens players within its radius on detonation.
]]

AddCSLuaFile()

SWEP.Base               = "zdev_grenade_base"

SWEP.PrintName          = "Flashbang"
SWEP.Author             = "Adrian"
SWEP.Instructions       = "Primary: Hold to charge throw power, release to throw. Secondary: Drop at feet."
SWEP.Category           = "ZDEV Weapons: Grenades"

SWEP.Spawnable          = true
SWEP.AdminOnly          = false

SWEP.SlotPos            = 2

-- Grenade configuration overrides
SWEP.FuseTime           = 2.5       -- Shorter fuse for flashbangs
SWEP.ThrowForceMax      = 1000      -- Slightly less max force
SWEP.ThrowForceMin      = 250
SWEP.ProjectileClass    = "zdev_ent_grenade_flashbang"
SWEP.ProjectileWorldModel = "models/weapons/w_eq_flashbang.mdl"
SWEP.ProjectileViewModel = "models/weapons/w_eq_flashbang.mdl"

-- Trajectory visual override (white/blue for flashbang)
SWEP.TrajectoryGravity  = 650

-- Viewmodel element overrides
SWEP.ViewModelData = {}
SWEP.ViewModelData.SpriteMaterial = "sprites/light_glow02"
SWEP.ViewModelData.SpriteScale = 0.8
SWEP.ViewModelData.SpriteColor = Color(200, 220, 255, 200) -- Light blue glow

-- Bone modifications for flashbang model
SWEP.ViewModelBoneMods = {
    ["v_weapon.Flashbang_Parent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

-- World model elements
SWEP.WElements = {
    ["mdl_projectile_w"] = { type = "Model", model = SWEP.ProjectileWorldModel, bone = "ValveBiped.Anim_Attachment_RH", rel = "", pos = Vector(1.271, 1.21, -0.129), angle = Angle(-2.178, 20.454, -75.255), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

-- View model elements
SWEP.VElements = {
    ["mdl_projectile"] = { type = "Model", model = SWEP.ProjectileViewModel,  bone = "v_weapon.Flashbang_Parent", rel = "", pos = Vector(0.45, -5.019, 0.109), angle = Angle(32.35, 8.298, 90.22), size = Vector(0.66, 0.66, 0.66), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}},
    ["spr_projectile_fx"] = {type = "Sprite", sprite = SWEP.ViewModelData.SpriteMaterial, bone = "ValveBiped.Bip01_R_Hand", rel = "mdl_projectile", pos = Vector(-0.042, 0.962, 5.59), size = { x = 0.8, y = 0.8 }, color = Color(200, 220, 255, 200), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}
