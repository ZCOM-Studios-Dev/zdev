--[[
	SHARED.LUA - Basic Grenade Entity

	A throwable explosive grenade derived from zdev_ent_base_throwable.
	Explodes after a configurable timer (default 3 seconds).

	By ZCOM Studios
	Copyright (c) 2020-2026 by ZCOM Studios, All rights reserved.
]]

-- ============================================================================
-- ENT STRUCTURE PROPERTIES
-- ============================================================================
ENT.Base = "zdev_ent_base_projectile"
ENT.Type = "anim"

-- ============================================================================
-- SPAWNMENU PROPERTIES
-- ============================================================================
ENT.PrintName = "Grenade"
ENT.Author = "ZCOM Studios"
ENT.Contact = "dev@zcom-studios.com"
ENT.Purpose = "A basic explosive grenade"
ENT.Instructions = "Throw at enemies - explodes after 3 seconds"
ENT.Category = "ZDEV Projectiles"
ENT.Spawnable = true
ENT.AdminOnly = false

-- ============================================================================
-- GRENADE CONFIGURATION (Override base values)
-- ============================================================================
-- Model
ENT.Model = Model("models/weapons/w_grenade.mdl")

-- Physics - lighter and bouncier than base
ENT.Mass = 0.5
ENT.Drag = 0.05
ENT.Elasticity = 0.4
ENT.Friction = 0.6

-- Projectile Type - affected by gravity
ENT.ProjectileType = ZDEV_PROJECTILE_PHYSICAL

-- Activation - timer trigger
ENT.ActivationTriggerType = ZDEV_TRIGGER_TIMER
ENT.ActivationTime = 3.0 -- Fuse time in seconds

-- Explosive settings
ENT.IsExplosive = true
ENT.ExplosionEffect = "Explosion"
ENT.ExplosionSound = "BaseExplosionEffect.Sound"
ENT.ExplosionForce = 5000
ENT.ExplosionRadius = 350
ENT.ExplosionDamage = 150

-- Visual effects
ENT.GlowEffect = false
ENT.TrailEffect = ""

-- ============================================================================
-- GRENADE-SPECIFIC PROPERTIES
-- ============================================================================
-- Beep settings for armed state
ENT.BeepSound = "buttons/button17.wav"
ENT.BeepInterval = 0.5       -- Starting interval
ENT.BeepMinInterval = 0.1    -- Fastest beep rate
ENT.BeepAcceleration = 1.5   -- How much faster beeping gets

-- Pin pull sound
ENT.PinPullSound = "weapons/slam/throw.wav"

-- Cooking ability (hold to reduce fuse time before throwing)
ENT.CanCook = true
ENT.MinFuseTime = 0.3 -- Minimum fuse time when fully cooked

-- ============================================================================
-- NETWORKED DATA TABLES
-- ============================================================================
function ENT:SetupDataTables()
	-- Call base SetupDataTables
	local baseClass = baseclass.Get("zdev_ent_base_projectile")
	if baseClass and baseClass.SetupDataTables then
		baseClass.SetupDataTables(self)
	end
end
