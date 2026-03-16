--[[
	INIT.LUA - Base Throwable Projectile (Server-side)

	Server-side initialization, physics, collision, attachment, and activation logic.
	Reference: https:--wiki.facepunch.com/gmod/ENTITY_Hooks
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
local Vector = Vector
local ents = ents
local util = util
local math = math
local constraint = constraint

-- ============================================================================
-- SERVER-SIDE INITIALIZATION
-- ============================================================================
function ENT:Initialize()
	zdev.log("D", "[BaseProjectile] Initialize() - Entity: " .. tostring(self) .. " Class: " .. self:GetClass())

	-- Set model
	if (type(self.Model) == "string") then
		self:SetModel(self.Model)
	elseif (type(self.Model) == "table" and #self.Model > 0) then
		self:SetModel(self.Model[math.random(1, #self.Model)])
	else
		zdev.log("E", "Invalid model configuration!")
	end

	-- Initialize physics based on projectile type
	self:SetupPhysics()

	-- Set collision group for projectiles
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

	-- Initialize health
	if self:Health() > 0 then
		self:SetMaxHealth(self:Health())
		self:SetCurrentHealth(self:Health())
	end

	-- Initialize state
	self:SetDeployed(false)
	self:SetAttached(false)
	self:SetArmed(false)
	self:SetActivated(false)

	-- Start motion controller for custom physics if needed
	if self.ProjectileType == ZDEV_PROJECTILE_BALLISTIC then
		self:StartMotionController()
	end

	-- Set next think
	self:NextThink(CurTime())

	-- Debug: Draw spawn position marker
	debugoverlay.Cross(self:GetPos(), 10, 3, Color(0, 255, 0), true)
	debugoverlay.Text(self:GetPos() + Vector(0, 0, 15), "SPAWN: " .. self:GetClass(), 3)

	zdev.log("I", "[BaseProjectile] Initialized at " .. tostring(self:GetPos()))
end

--- Configure physics based on projectile type
--- @note Based on PhysObj wiki: https:--wiki.facepunch.com/gmod/PhysObj
--- - SetDragCoefficient: controls air resistance (valid)
--- - SetDamping: controls linear/angular velocity decay (valid)
--- - SetMass: sets mass in kg (valid)
--- - EnableGravity: only enables/disables, cannot set custom gravity vector
--- - Elasticity: use Entity:SetElasticity(), NOT PhysObj method
--- - Friction: controlled via PhysObj:SetMaterial() surface properties
function ENT:SetupPhysics()
	local projType = self:GetEffectiveProjectileType()
	local projTypeName = projType == ZDEV_PROJECTILE_ENERGY and "ENERGY" or (projType == ZDEV_PROJECTILE_BALLISTIC and "BALLISTIC" or "PHYSICAL")

	zdev.log("D", "[BaseProjectile] SetupPhysics() - Type: " .. projTypeName)

	if projType == ZDEV_PROJECTILE_ENERGY then
		-- Energy projectiles: no physics, move via Think
		self:SetMoveType(MOVETYPE_FLY)
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(Vector(-2, -2, -2), Vector(2, 2, 2))
		zdev.log("D", "[BaseProjectile] Physics: ENERGY mode (MOVETYPE_FLY, SOLID_BBOX)")
	else
		-- Physical and Ballistic: VPhysics
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		-- Set elasticity on the Entity (NOT PhysObj - that method doesn't exist)
		self:SetElasticity(self.Elasticity or 0.3)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(self.Mass or 1)

			-- Drag coefficient controls air resistance
			-- Note: self.AirResistance is redundant with self.Drag
			local drag = self.Drag or 0.1
			if drag > 0 then
				phys:EnableDrag(true)
				phys:SetDragCoefficient(drag)
			else
				phys:EnableDrag(false)
			end

			-- SetDamping controls velocity decay over time (linear, angular)
			-- This provides realistic slowdown without requiring custom Think logic
			local linearDamp = drag * 0.5  -- Derive from drag for consistency
			local angularDamp = drag * 0.25
			phys:SetDamping(linearDamp, angularDamp)

			-- Friction is controlled via surface material properties
			-- Use SetMaterial for physics surface properties (friction, bounciness, etc.)
			-- Common materials: "metal", "wood", "concrete", "rubber", "flesh", "default"
			if self.PhysMaterial then
				phys:SetMaterial(self.PhysMaterial)
			end

			-- Gravity: can only enable/disable, cannot set custom gravity vector
			-- For custom gravity effects, use PhysObj:ApplyForceCenter in Think
			phys:EnableGravity(projType == ZDEV_PROJECTILE_PHYSICAL)

			zdev.log("D", "[BaseProjectile] Physics: Mass=" .. (self.Mass or 1) .. " Drag=" .. drag .. " Elasticity=" .. (self.Elasticity or 0.3))
			zdev.log("D", "[BaseProjectile] Physics: Damping(linear=" .. linearDamp .. ", angular=" .. angularDamp .. ") Gravity=" .. tostring(projType == ZDEV_PROJECTILE_PHYSICAL))
		else
			zdev.log("W", "[BaseProjectile] SetupPhysics() - PhysObj is INVALID!")
		end
	end
end

-- ============================================================================
-- SPAWN FUNCTION
-- ============================================================================
function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end

	local ent = ents.Create(ClassName)
	if not IsValid(ent) then return end

	ent:SetPos(tr.HitPos + tr.HitNormal * 16)
	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:Spawn()
	ent:Activate()
	ent:SetThrower(ply)

	return ent
end

-- ============================================================================
-- THROW LOGIC
-- ============================================================================

--- Throw the projectile with the given velocity
-- @param thrower Entity The entity throwing this projectile
-- @param velocity Vector The initial velocity
-- @param angVelocity Angle Optional angular velocity
function ENT:Throw(thrower, velocity, angVelocity)
	if not IsValid(thrower) then
		zdev.log("W", "[BaseProjectile] Throw() - Invalid thrower!")
		return
	end

	zdev.log("D", "[BaseProjectile] Throw() - Thrower: " .. tostring(thrower) .. " Velocity: " .. tostring(velocity))

	self:SetThrower(thrower)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(velocity)
		if angVelocity then
			phys:SetAngleVelocity(Vector(angVelocity.p, angVelocity.y, angVelocity.r))
		end
	else
		-- For energy projectiles without physics
		self.EnergyVelocity = velocity
	end

	-- Debug: Draw velocity vector
	local startPos = self:GetPos()
	local endPos = startPos + velocity:GetNormalized() * 100
	debugoverlay.Line(startPos, endPos, 3, Color(255, 255, 0), true)
	debugoverlay.Text(endPos, "VEL: " .. math.Round(velocity:Length()) .. " u/s", 3)

	-- Arm on throw if using impact trigger
	if self:GetEffectiveActivationTrigger() == ZDEV_TRIGGER_IMPACT then
		self:Arm()
	end

	-- Hook for derived entities
	self:OnThrow(thrower, velocity)

	zdev.log("I", "[BaseProjectile] Thrown with speed " .. math.Round(velocity:Length()) .. " u/s")
end

-- ============================================================================
-- THINK LOGIC
-- ============================================================================

-- Debug throttle for Think (avoid spam)
ENT.NextDebugThinkTime = 0
ENT.DebugThinkInterval = 0.5

function ENT:Think()
	-- Debug: Periodic position/state logging (throttled)
	if CurTime() >= (self.NextDebugThinkTime or 0) then
		self.NextDebugThinkTime = CurTime() + (self.DebugThinkInterval or 0.5)

		local phys = self:GetPhysicsObject()
		local vel = IsValid(phys) and phys:GetVelocity() or (self.EnergyVelocity or Vector(0, 0, 0))
		local speed = vel:Length()

		-- Only log if moving significantly
		if speed > 10 then
			zdev.log("D", "[BaseProjectile] Think() - Pos: " .. tostring(self:GetPos()) .. " Speed: " .. math.Round(speed))

			-- Debug: Draw current trajectory
			debugoverlay.Line(self:GetPos(), self:GetPos() + vel:GetNormalized() * 50, 0.5, Color(0, 150, 255), true)
		end

		-- Debug: Draw entity bounding box
		local mins, maxs = self:GetCollisionBounds()
		debugoverlay.Box(self:GetPos(), mins, maxs, 0.5, Color(100, 100, 255, 50))

		-- Debug: Show armed state
		if self:GetArmed() and not self:GetActivated() then
			local timeLeft = self:GetTimeUntilActivation()
			debugoverlay.Text(self:GetPos() + Vector(0, 0, 10), "ARMED: " .. string.format("%.1f", timeLeft) .. "s", 0.5)
		end
	end

	-- Check for activation
	if self:ShouldActivate() then
		self:Activate()
	end

	-- Check for attach expiration
	if self:HasAttachExpired() then
		self:Detach()
	end

	-- Energy projectile movement
	if self:GetEffectiveProjectileType() == ZDEV_PROJECTILE_ENERGY then
		self:UpdateEnergyMovement()
	end

	self:NextThink(CurTime())
	return true
end

--- Update position for energy-type projectiles
function ENT:UpdateEnergyMovement()
	if self:GetDeployed() or self:GetAttached() then return end

	local velocity = self.EnergyVelocity or Vector(0, 0, 0)
	if velocity:LengthSqr() < 1 then return end

	local dt = FrameTime()
	local newPos = self:GetPos() + velocity * dt

	-- Trace for collision
	local tr = util.TraceLine({
		start = self:GetPos(),
		endpos = newPos,
		filter = {self, self:GetThrower()},
		mask = MASK_SHOT
	})

	if tr.Hit then
		self:SetPos(tr.HitPos)
		self:OnImpact(tr.Entity, tr)
	else
		self:SetPos(newPos)
	end
end

-- ============================================================================
-- PHYSICS COLLISION HANDLING
-- ============================================================================
function ENT:PhysicsCollide(colData, collider)
	-- Skip if already deployed/attached
	if self:GetDeployed() or self:GetAttached() then return end

	local hitEntity = colData.HitEntity
	local hitSpeed = colData.Speed
	local hitPos = colData.HitPos
	local hitNormal = colData.HitNormal

	-- Debug: Log collision
	local hitName = IsValid(hitEntity) and (hitEntity:IsWorld() and "WORLD" or hitEntity:GetClass()) or "UNKNOWN"
	zdev.log("D", "[BaseProjectile] PhysicsCollide() - Hit: " .. hitName .. " Speed: " .. math.Round(hitSpeed) .. " u/s")

	-- Debug: Draw collision point and normal
	debugoverlay.Cross(hitPos, 8, 2, Color(255, 100, 0), true)
	debugoverlay.Line(hitPos, hitPos + hitNormal * 30, 2, Color(255, 200, 0), true)
	debugoverlay.Text(hitPos + Vector(0, 0, 12), "IMPACT: " .. math.Round(hitSpeed) .. " u/s", 2)

	-- Handle impact trigger
	if self:GetEffectiveActivationTrigger() == ZDEV_TRIGGER_IMPACT and self:GetArmed() then
		zdev.log("I", "[BaseProjectile] Impact trigger activated!")
		self:OnImpact(hitEntity, colData)
		self:Activate()
		return
	end

	-- Handle destroy on impact
	if self.DestroyOnImpact then
		zdev.log("D", "[BaseProjectile] DestroyOnImpact triggered")
		self:OnImpact(hitEntity, colData)
		self:Remove()
		return
	end

	-- Handle attachment to entities
	if self.IsAttachable and IsValid(hitEntity) and not hitEntity:IsWorld() then
		local hitClass = hitEntity:GetClass()
		if self:CanAttachToClass(hitClass) then
			self:AttachTo(hitEntity, colData.HitPos, colData.HitNormal)
			return
		end
	end

	-- Handle deployment on world collision
	if self.IsDeployable and (hitEntity:IsWorld() or not IsValid(hitEntity)) then
		self:Deploy(colData.HitPos, colData.HitNormal)
		return
	end

	-- Play impact sound for significant collisions
	if hitSpeed > 100 then
		self:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 60, 100, 0.5)
	end

	-- Call hook for derived entities
	self:OnImpact(hitEntity, colData)
end

-- ============================================================================
-- DAMAGE HANDLING
-- ============================================================================
function ENT:OnTakeDamage(dmginfo)
	if self:Health() <= 0 then return end -- Invulnerable

	local damage = dmginfo:GetDamage()
	local newHealth = self:GetCurrentHealth() - damage
	self:SetCurrentHealth(math.max(0, newHealth))

	-- Apply physics force
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceCenter(dmginfo:GetDamageForce() * 0.1)
	end

	-- Check for destruction
	if newHealth <= 0 then
		self:OnDestroyed(dmginfo:GetAttacker(), dmginfo:GetInflictor())
	end
end

-- ============================================================================
-- DEPLOYMENT LOGIC
-- ============================================================================

--- Deploy the entity (make it static on a surface)
-- @param hitPos Vector The position to deploy at
-- @param hitNormal Vector The surface normal
function ENT:Deploy(hitPos, hitNormal)
	if self:GetDeployed() then return end

	zdev.log("D", "[BaseProjectile] Deploy() - Pos: " .. tostring(hitPos))

	self:SetDeployed(true)
	self:SetDeployTime(CurTime())

	-- Stop physics
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	-- Align to surface
	local ang = hitNormal:Angle()
	ang:RotateAroundAxis(ang:Right(), 90)
	self:SetAngles(ang)
	self:SetPos(hitPos + hitNormal * 1)

	-- Debug: Draw deployment marker
	debugoverlay.Cross(hitPos, 15, 5, Color(0, 255, 100), true)
	debugoverlay.Line(hitPos, hitPos + hitNormal * 40, 5, Color(0, 255, 100), true)
	debugoverlay.Text(hitPos + Vector(0, 0, 20), "DEPLOYED", 5)

	-- Arm if using timer or proximity trigger
	local trigger = self:GetEffectiveActivationTrigger()
	if trigger == ZDEV_TRIGGER_TIMER or trigger == ZDEV_TRIGGER_PROXIMITY then
		self:Arm()
	end

	-- Hook for derived entities
	self:OnDeploy(hitPos, hitNormal)

	zdev.log("I", "[BaseProjectile] Deployed at " .. tostring(hitPos))
end

-- ============================================================================
-- ATTACHMENT LOGIC
-- ============================================================================

--- Attach the entity to another entity
-- @param target Entity The entity to attach to
-- @param hitPos Vector The attachment position
-- @param hitNormal Vector The surface normal at attachment point
function ENT:AttachTo(target, hitPos, hitNormal)
	if self:GetAttached() then return end
	if not IsValid(target) then return end

	zdev.log("D", "[BaseProjectile] AttachTo() - Target: " .. target:GetClass() .. " Pos: " .. tostring(hitPos))

	self:SetAttached(true)
	self:SetAttachParent(target)

	-- Calculate local offset
	local localPos = target:WorldToLocal(hitPos)
	local localAng = target:WorldToLocalAngles(hitNormal:Angle())

	-- Parent to target
	self:SetParent(target)
	self:SetLocalPos(localPos)
	self:SetLocalAngles(localAng)

	-- Disable physics
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	-- Set detach time if duration is specified
	if self.AttachDuration > 0 then
		self:SetDetachTime(CurTime() + self.AttachDuration)
	end

	-- Debug: Draw attachment line
	debugoverlay.Line(self:GetPos(), target:GetPos(), 5, Color(255, 0, 255), true)
	debugoverlay.Cross(hitPos, 10, 5, Color(255, 0, 255), true)
	debugoverlay.Text(hitPos + Vector(0, 0, 15), "ATTACHED TO: " .. target:GetClass(), 5)

	-- Arm the device
	self:Arm()

	-- Hook for derived entities
	self:OnAttach(target, hitPos, hitNormal)

	zdev.log("I", "[BaseProjectile] Attached to " .. target:GetClass())
end

--- Detach from parent entity
function ENT:Detach()
	if not self:GetAttached() then return end

	local parent = self:GetAttachParent()

	self:SetAttached(false)
	self:SetAttachParent(NULL)
	self:SetParent(nil)

	-- Re-enable physics
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
	end

	-- Hook for derived entities
	self:OnDetach(parent)
end

-- ============================================================================
-- ARMING AND ACTIVATION
-- ============================================================================

--- Arm the projectile (start activation countdown)
function ENT:Arm()
	if self:GetArmed() then return end

	zdev.log("D", "[BaseProjectile] Arm() - ActivationTime: " .. self.ActivationTime .. "s")

	self:SetArmed(true)
	self:SetActivateTime(CurTime() + self.ActivationTime)

	-- Debug: Draw arm indicator
	debugoverlay.Cross(self:GetPos(), 12, 2, Color(255, 200, 0), true)
	debugoverlay.Text(self:GetPos() + Vector(0, 0, 25), "ARMED! Fuse: " .. self.ActivationTime .. "s", 2)

	-- Hook for derived entities
	self:OnArm()

	zdev.log("I", "[BaseProjectile] Armed - Detonation in " .. self.ActivationTime .. "s")
end

--- Trigger remote activation (for ZDEV_TRIGGER_REMOTE type)
function ENT:RemoteActivate()
	if self:GetEffectiveActivationTrigger() ~= ZDEV_TRIGGER_REMOTE then return end
	if not self:GetArmed() then return end

	self:Activate()
end

--- Main activation handler - triggers the entity's effect
function ENT:Activate()
	if self:GetActivated() then return end

	zdev.log("D", "[BaseProjectile] Activate() - IsExplosive: " .. tostring(self.IsExplosive))

	self:SetActivated(true)

	-- Debug: Draw activation marker
	debugoverlay.Cross(self:GetPos(), 20, 3, Color(255, 0, 0), true)
	debugoverlay.Text(self:GetPos() + Vector(0, 0, 30), "ACTIVATED!", 3)

	-- Hook for derived entities (called before explosion/effect)
	self:OnActivate()

	-- Handle explosive activation
	if self.IsExplosive then
		zdev.log("I", "[BaseProjectile] Triggering explosion...")
		self:Explode()
	else
		-- Non-explosive activation (e.g., deploy effect, emit signal)
		-- If there's an active duration, schedule deactivation
		if self.ActiveDuration > 0 then
			zdev.log("D", "[BaseProjectile] Non-explosive activation, duration: " .. self.ActiveDuration .. "s")
			timer.Simple(self.ActiveDuration, function()
				if IsValid(self) then
					self:OnDeactivate()
				end
			end)
		end
	end
end

--- Called when active duration expires
function ENT:OnDeactivate()
	self:Remove()
end

-- ============================================================================
-- EXPLOSION LOGIC
-- ============================================================================

--- Handle explosion
function ENT:Explode()
	local pos = self:GetPos()
	local thrower = self:GetThrower()

	zdev.log("D", "[BaseProjectile] Explode() - Pos: " .. tostring(pos) .. " Radius: " .. self.ExplosionRadius .. " Damage: " .. self.ExplosionDamage)

	-- Debug: Draw explosion radius sphere
	debugoverlay.Sphere(pos, self.ExplosionRadius, 3, Color(255, 100, 0, 50), true)
	debugoverlay.Sphere(pos, self.ExplosionRadius * 0.5, 3, Color(255, 50, 0, 100), true)
	debugoverlay.Cross(pos, 30, 3, Color(255, 0, 0), true)
	debugoverlay.Text(pos + Vector(0, 0, self.ExplosionRadius * 0.5), "EXPLOSION R=" .. self.ExplosionRadius .. " D=" .. self.ExplosionDamage, 3)

	-- Create explosion effect
	local effectData = EffectData()
	effectData:SetOrigin(pos)
	effectData:SetMagnitude(self.ExplosionForce)
	effectData:SetRadius(self.ExplosionRadius)
	effectData:SetScale(1)
	util.Effect(self.ExplosionEffect, effectData, true, true)

	-- Play explosion sound
	if self.ExplosionSound and self.ExplosionSound ~= "" then
		self:EmitSound(self.ExplosionSound, 100, 100, 1)
	end

	-- Apply blast damage
	util.BlastDamage(
		self,
		IsValid(thrower) and thrower or self,
		pos,
		self.ExplosionRadius,
		self.ExplosionDamage
	)

	-- Apply physics force to nearby objects
	local affectedCount = 0
	for _, ent in ipairs(ents.FindInSphere(pos, self.ExplosionRadius)) do
		if IsValid(ent) and ent ~= self then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				local dir = (ent:GetPos() - pos):GetNormalized()
				local distance = pos:Distance(ent:GetPos())
				local falloff = 1 - (distance / self.ExplosionRadius)
				phys:ApplyForceCenter(dir * self.ExplosionForce * falloff)
				affectedCount = affectedCount + 1

				-- Debug: Draw force lines to affected entities
				debugoverlay.Line(pos, ent:GetPos(), 2, Color(255, 150, 0), true)
			end
		end
	end

	zdev.log("I", "[BaseProjectile] Explosion complete - Affected " .. affectedCount .. " physics objects")

	-- Hook for derived entities
	self:OnExplode(pos, self.ExplosionRadius, self.ExplosionDamage)

	-- Remove the entity
	self:Remove()
end

-- ============================================================================
-- DESTRUCTION AND CLEANUP
-- ============================================================================

--- Called when entity is destroyed by damage
-- @param attacker Entity Who destroyed this
-- @param inflictor Entity What weapon/entity dealt the killing blow
function ENT:OnDestroyed(attacker, inflictor)
	-- If explosive, explode on destruction
	if self.IsExplosive and not self:GetActivated() then
		self:SetActivated(true)
		self:Explode()
	else
		-- Non-explosive destruction effect
		local effectData = EffectData()
		effectData:SetOrigin(self:GetPos())
		effectData:SetScale(1)
		util.Effect("GlassImpact", effectData)

		self:Remove()
	end
end

--- Cleanup on removal
function ENT:OnRemove()
	-- Stop any running timers
	local timerName = "ZDEV_Throwable_" .. self:EntIndex()
	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end
end

-- ============================================================================
-- INPUT HANDLING (for Hammer I/O)
-- ============================================================================
function ENT:AcceptInput(inputName, activator, caller, param)
	local input = string.lower(inputName)

	if input == "arm" then
		self:Arm()
		return true
	elseif input == "activate" or input == "detonate" then
		self:RemoteActivate()
		return true
	elseif input == "detach" then
		self:Detach()
		return true
	end

	return false
end

-- ============================================================================
-- TRANSMIT STATE
-- ============================================================================
function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end