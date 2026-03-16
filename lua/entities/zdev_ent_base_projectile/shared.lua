--[[
	SHARED.LUA - Base Throwable Projectile Entity

	A base SENT for throwable projectiles supporting Physical, Ballistic, and Energy types.
	Supports deployable gadgets, attachable devices, and explosive ordnance.

	Reference: https:--wiki.facepunch.com/gmod/Structures/ENT
	Reference: https:--wiki.facepunch.com/gmod/ENTITY_Hooks
]]

-- ============================================================================
-- LOCALIZED GLOBALS (Performance)
-- ============================================================================
local CurTime = CurTime
local IsValid = IsValid
local Vector = Vector
local Angle = Angle
local math = math
local bit = bit

-- ============================================================================
-- PROJECTILE TYPE ENUM
-- ============================================================================
-- Define projectile behavior types
ZDEV_PROJECTILE_PHYSICAL = 1  -- Grenades, rocks - affected by gravity
ZDEV_PROJECTILE_BALLISTIC = 2 -- Bullets, missiles, rockets - fast, minimal drop
ZDEV_PROJECTILE_ENERGY = 3    -- plasma, ion bolts - near-instant travel, no gravity 
ZDEV_PROJECTILE_LASER = 4 -- instant travel, no gravity
-- ============================================================================
-- ACTIVATION TRIGGER ENUM
-- ============================================================================
ZDEV_TRIGGER_TIMER = 1     -- Activates after ActivationTime seconds
ZDEV_TRIGGER_IMPACT = 2    -- Activates on collision
ZDEV_TRIGGER_PROXIMITY = 3 -- Activates when entity enters radius
ZDEV_TRIGGER_REMOTE = 4    -- Activates via external signal

-- ============================================================================
-- ENT STRUCTURE PROPERTIES
-- ============================================================================
ENT.Base = "base_anim"
ENT.Type = "anim"

-- ============================================================================
-- SPAWNMENU PROPERTIES
-- ============================================================================
ENT.PrintName = "Base Throwable"
ENT.Author = "ZCOM Studios"
ENT.Contact = "dev@zcom-studios.com"
ENT.Purpose = "Base entity for throwable projectiles, deployables, and attachables"
ENT.Instructions = "Do not spawn directly - derive from this base"
ENT.Category = "ZDEV Projectiles"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.DisableDuplicator = true

-- ============================================================================
-- PROJECTILE CONFIGURATION
-- ============================================================================
-- Projectile Type: ZDEV_PROJECTILE_PHYSICAL, ZDEV_PROJECTILE_BALLISTIC, ZDEV_PROJECTILE_ENERGY
ENT.ProjectileType = ZDEV_PROJECTILE_PHYSICAL

-- Model and Physics
ENT.Model = Model("models/Combine_Helicopter/helicopter_bomb01.mdl")
ENT.Mass = 100           -- Physics mass in kg
ENT.Drag = 0.1           -- Drag coefficient for air resistance (used by PhysObj:SetDragCoefficient)
ENT.Gravity = 1.0        -- Gravity multiplier (1.0 = normal) - NOTE: Only enable/disable works in Source
ENT.Elasticity = 0.3     -- Bounce coefficient (0 = no bounce, 1 = full bounce) - uses Entity:SetElasticity
ENT.PhysMaterial = nil   -- Physics surface material (e.g., "metal", "rubber", "wood") - controls friction/sounds

-- Health and Destruction
ENT.Health = 100              -- Health for deployables/attachables (0 = invulnerable)
ENT.DestroyOnImpact = false   -- If true, destroys on first collision
ENT.ImpactDamageThreshold = 0 -- Minimum impact speed to take damage

-- ============================================================================
-- DEPLOYABLE/ATTACHABLE CONFIGURATION
-- ============================================================================
ENT.IsDeployable = false		-- Deployable: Becomes static after first touch (sensors, mines, gadgets)
ENT.IsAttachable = false		-- Attachable: Sticks to valid entities after collision
ENT.AttachableEntities = {		-- Valid entity classes for attachment (empty = all entities)
	["player"] = true,
	["npc_*"] = true,        -- Wildcard support
	["prop_vehicle_*"] = true,
	["prop_physics"] = true,
}
ENT.AttachDuration = 0			-- How long the entity remains attached before detaching (0 = permanent)

-- ============================================================================
-- ACTIVATION CONFIGURATION
-- ============================================================================
-- Activation Trigger: ZDEV_TRIGGER_TIMER, ZDEV_TRIGGER_IMPACT, ZDEV_TRIGGER_PROXIMITY, ZDEV_TRIGGER_REMOTE
ENT.ActivationTriggerType = ZDEV_TRIGGER_TIMER
ENT.ActivationTime = 3.0		-- Time before activation (for TIMER trigger or arm delay)
ENT.ActiveDuration = 0		-- Duration entity remains active (0 = instant effect like explosions)
ENT.ActivationRadius = 100		-- Radius for proximity trigger and effect range

-- ============================================================================
-- EXPLOSIVE CONFIGURATION
-- ============================================================================
ENT.IsExplosive = false          -- Whether this projectile explodes
ENT.ExplosionEffect = "Explosion" -- Particle effect name
ENT.ExplosionSound = "BaseExplosionEffect.Sound"
ENT.ExplosionForce = 3000        -- Physics push force
ENT.ExplosionRadius = 300        -- Damage/effect radius
ENT.ExplosionDamage = 100        -- Maximum damage at center

-- ============================================================================
-- VISUAL EFFECTS CONFIGURATION
-- ============================================================================
ENT.TrailEffect = ""             -- Trail particle effect name (empty = none)
ENT.TrailColor = Color(255, 255, 255)
ENT.TrailWidth = 8
ENT.TrailDuration = 0.5
ENT.GlowEffect = false           -- Whether to render a glow
ENT.GlowColor = Color(255, 200, 100)
ENT.GlowSize = 32

-- ============================================================================
-- RENDERING PROPERTIES
-- ============================================================================
ENT.AutomaticFrameAdvance = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

-- ============================================================================
-- NETWORKED DATA TABLES
-- ============================================================================
function ENT:SetupDataTables()
	-- State networking
	self:NetworkVar("Bool", 0, "Deployed")      -- Has the entity been deployed/placed
	self:NetworkVar("Bool", 1, "Attached")      -- Is the entity attached to something
	self:NetworkVar("Bool", 2, "Armed")         -- Is the entity armed/active
	self:NetworkVar("Bool", 3, "Activated")     -- Has the entity been activated (exploded/triggered)

	-- Timing
	self:NetworkVar("Float", 0, "ActivateTime") -- When the entity will activate
	self:NetworkVar("Float", 1, "DeployTime")   -- When the entity was deployed
	self:NetworkVar("Float", 2, "DetachTime")   -- When the entity will detach

	-- References
	self:NetworkVar("Entity", 0, "Thrower")     -- Who threw this projectile
	self:NetworkVar("Entity", 1, "AttachParent") -- What entity we're attached to

	-- Runtime state (not saved/restored)
	self:NetworkVar("Int", 0, "CurrentHealth")  -- Current health
end

-- ============================================================================
-- ACCESSOR FUNCTIONS
-- ============================================================================
-- Provide type-safe accessors for configuration (used by derived entities)
AccessorFunc(ENT, "m_ProjectileType", "ProjectileType", FORCE_NUMBER)
AccessorFunc(ENT, "m_ActivationTriggerType", "ActivationTrigger", FORCE_NUMBER)

-- ============================================================================
-- SHARED UTILITY FUNCTIONS
-- ============================================================================

--- Check if an entity class matches our attachable list (supports wildcards)
-- @param entClass string The entity class to check
-- @return boolean True if the entity can be attached to
function ENT:CanAttachToClass(entClass)
	if not entClass then return false end
	if table.IsEmpty(self.AttachableEntities) then return true end

	-- Direct match first
	if self.AttachableEntities[entClass] then return true end

	-- Wildcard matching
	for pattern, allowed in pairs(self.AttachableEntities) do
		if allowed and string.find(pattern, "*") then
			local regexPattern = string.gsub(pattern, "%*", ".*")
			if string.match(entClass, "^" .. regexPattern .. "$") then
				return true
			end
		end
	end

	return false
end

--- Check if this projectile should activate based on its trigger type
-- @return boolean True if activation conditions are met
function ENT:ShouldActivate()
	if self:GetActivated() then return false end
	if not self:GetArmed() then return false end

	local triggerType = self:GetActivationTrigger() or self.ActivationTriggerType

	if triggerType == ZDEV_TRIGGER_TIMER then
		return CurTime() >= self:GetActivateTime()
	elseif triggerType == ZDEV_TRIGGER_PROXIMITY then
		return self:CheckProximityTrigger()
	end

	-- IMPACT and REMOTE are handled by events, not Think
	return false
end

--- Check if any valid targets are within proximity radius
-- @return boolean True if a valid target is in range
function ENT:CheckProximityTrigger()
	if not self:GetDeployed() then return false end

	local pos = self:GetPos()
	local radius = self.ActivationRadius

	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if IsValid(ent) and ent ~= self then
			if ent:IsPlayer() or ent:IsNPC() then
				-- Line of sight check
				local tr = util.TraceLine({
					start = pos,
					endpos = ent:WorldSpaceCenter(),
					filter = self,
					mask = MASK_SHOT
				})
				if tr.Entity == ent then
					return true
				end
			end
		end
	end

	return false
end

--- Get the effective projectile type
-- @return number The projectile type enum value
function ENT:GetEffectiveProjectileType()
	return self:GetProjectileType() or self.ProjectileType or ZDEV_PROJECTILE_PHYSICAL
end

--- Get the effective activation trigger type
-- @return number The activation trigger enum value
function ENT:GetEffectiveActivationTrigger()
	return self:GetActivationTrigger() or self.ActivationTriggerType or ZDEV_TRIGGER_TIMER
end

--- Calculate remaining time until activation
-- @return number Seconds until activation (0 if already activated or not armed)
function ENT:GetTimeUntilActivation()
	if self:GetActivated() or not self:GetArmed() then return 0 end
	return math.max(0, self:GetActivateTime() - CurTime())
end

--- Check if this projectile has expired its attach duration
-- @return boolean True if should detach
function ENT:HasAttachExpired()
	if not self:GetAttached() then return false end
	if self.AttachDuration <= 0 then return false end

	local detachTime = self:GetDetachTime()
	return detachTime > 0 and CurTime() >= detachTime
end

-- ============================================================================
-- SANDBOX INTERACTION HOOKS
-- ============================================================================

--- Prevent physics gun manipulation when deployed/attached
function ENT:PhysgunPickup(ply)
	if self:GetDeployed() or self:GetAttached() then
		return false
	end
	return true
end

--- Prevent gravity gun pickup when armed
function ENT:GravGunPickupAllowed(ply)
	if self:GetArmed() then
		return false
	end
	return true
end

--- Prevent gravity gun punt when deployed
function ENT:GravGunPunt(ply)
	if self:GetDeployed() or self:GetAttached() then
		return false
	end
	return true
end

--- Restrict tool usage on active projectiles
function ENT:CanTool(ply, tr, toolname, tool, button)
	if self:GetArmed() or self:GetActivated() then
		return false
	end
	return true
end

-- ============================================================================
-- OVERRIDABLE HOOKS (Shared for client-side effects)
-- ============================================================================
-- These hooks are called from the server but defined in shared.lua so derived
-- entities can override them with client-side effects (particles, sounds, etc.)

--[[
	OnThrow(thrower, velocity)

	OVERRIDABLE HOOK: Called when the entity is thrown.
	Use this to play throw sounds, spawn trail effects, or arm the device.

	@param thrower Entity The entity that threw this projectile
	@param velocity Vector The initial velocity of the throw
]]
function ENT:OnThrow(thrower, velocity)
	-- Override in derived entities
end

--[[
	OnDeploy(hitPos, hitNormal)

	OVERRIDABLE HOOK: Called when the entity is deployed (placed on a surface).
	Use this to play sounds, spawn effects, or modify behavior on deployment.

	@param hitPos Vector The world position where deployed
	@param hitNormal Vector The surface normal at deployment point
]]
function ENT:OnDeploy(hitPos, hitNormal)
	-- Override in derived entities
end

--[[
	OnAttach(target, hitPos, hitNormal)

	OVERRIDABLE HOOK: Called when the entity attaches to another entity.
	Use this to play sounds, spawn effects, or apply effects to the target.

	@param target Entity The entity we attached to
	@param hitPos Vector The world position of attachment
	@param hitNormal Vector The surface normal at attachment point
]]
function ENT:OnAttach(target, hitPos, hitNormal)
	-- Override in derived entities
end

--[[
	OnDetach(previousParent)

	OVERRIDABLE HOOK: Called when the entity detaches from its parent.
	Use this to play sounds, spawn effects, or clean up.

	@param previousParent Entity The entity we were attached to (may be NULL)
]]
function ENT:OnDetach(previousParent)
	-- Override in derived entities
end

--[[
	OnArm()

	OVERRIDABLE HOOK: Called when the entity is armed.
	Use this to play arming sounds, start beeping, or enable proximity detection.
]]
function ENT:OnArm()
	-- Override in derived entities
end

--[[
	OnActivate()

	OVERRIDABLE HOOK: Called when the entity activates (before explosion/effect).
	Use this to play activation sounds, spawn pre-explosion effects, or
	perform custom activation logic.

	For explosives, this is called immediately before Explode().
	For non-explosives, this is called when the activation triggers.
]]
function ENT:OnActivate()
	-- Override in derived entities
end

--[[
	OnImpact(hitEntity, colData)

	OVERRIDABLE HOOK: Called when the entity collides with something.
	Use this to play impact sounds, spawn sparks, or apply effects.

	@param hitEntity Entity The entity that was hit (may be NULL for world)
	@param colData table The collision data containing:
		- HitPos: Vector - The collision position
		- HitNormal: Vector - The surface normal
		- Speed: number - The impact speed
		- DeltaTime: number - Time since last collision
]]
function ENT:OnImpact(hitEntity, colData)
	-- Override in derived entities
end

--[[
	OnExplode(pos, radius, damage)

	OVERRIDABLE HOOK: Called when the entity explodes, just before removal.
	Use this to spawn additional effects, apply custom damage, or trigger events.

	@param pos Vector The explosion center position
	@param radius number The explosion radius
	@param damage number The explosion damage
]]
function ENT:OnExplode(pos, radius, damage)
	-- Override in derived entities
end