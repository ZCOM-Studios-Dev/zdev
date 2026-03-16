--[[
    Frag Grenade Projectile Entity
    Spawned by weapon_frag_grenade. Handles physics simulation,
    fuse countdown, detonation, and blast damage.
]]

AddCSLuaFile()

ENT.Type            = "anim"
ENT.Base            = "base_anim"
ENT.PrintName       = "Frag Grenade"
ENT.Author          = "Adrian"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Model           = "models/weapons/w_eq_fraggrenade.mdl"

-- Explosion configuration
ENT.BlastDamage     = 150
ENT.BlastRadius     = 350

-- Bounce sounds
ENT.BounceSounds = {
    "physics/metal/metal_grenade_impact_hard1.wav",
    "physics/metal/metal_grenade_impact_hard2.wav",
    "physics/metal/metal_grenade_impact_hard3.wav",
}

--------------------------------------------------------------------------------
-- Networking                                                                                                                                                                                                   
--------------------------------------------------------------------------------

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "DetonateTime")
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function ENT:Initialize()
    self:SetModel(self.Model)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(5)
            phys:SetBuoyancyRatio(0.4)
            phys:Wake()
        end

        -- Default fuse if not set by the SWEP
        if self:GetDetonateTime() == 0 then
            self:SetDetonateTime(CurTime() + 4.0)
        end
    end
end

--------------------------------------------------------------------------------
-- Think: Fuse Countdown
--------------------------------------------------------------------------------

function ENT:Think()
    if SERVER and CurTime() >= self:GetDetonateTime() then
        self:Detonate()
        return
    end

    self:NextThink(CurTime())
    return true
end

--------------------------------------------------------------------------------
-- Physics Collision: Bounce Sounds
--------------------------------------------------------------------------------

function ENT:PhysicsCollide(colData, collider)
    if colData.Speed > 60 then
        local volume = math.Clamp(colData.Speed / 400, 0.2, 0.8)
        local snd = self.BounceSounds[math.random(#self.BounceSounds)]
        self:EmitSound(snd, 65, math.random(95, 110), volume)
    end

    -- Dampen spin on impact for more natural bouncing
    if IsValid(collider) then
        local angVel = collider:GetAngleVelocity()
        collider:AddAngleVelocity(angVel * -0.3)
    end
end

--------------------------------------------------------------------------------
-- Detonation (Server)
--------------------------------------------------------------------------------

function ENT:Detonate()
    if CLIENT then return end
    if self.has_detonated then return end

    self.has_detonated = true

    local pos = self:GetPos()
    local thrower = self:GetOwner()

    -- Explosion effect (replicated to clients automatically)
    local fx = EffectData()
    fx:SetOrigin(pos)
    fx:SetMagnitude(self.BlastRadius)
    fx:SetScale(1)
    fx:SetRadius(self.BlastRadius)
    util.Effect("Explosion", fx)

    -- Screen shake for nearby players
    util.ScreenShake(pos, 10, 5, 1.0, self.BlastRadius * 1.5)

    -- Blast damage
    util.BlastDamage(
        self,                                   -- inflictor
        IsValid(thrower) and thrower or self,    -- attacker (credit kills to thrower)
        pos,
        self.BlastRadius,
        self.BlastDamage
    )

    -- Scorch decal on nearby surfaces
    local tr = util.TraceLine({
        start   = pos,
        endpos  = pos + Vector(0, 0, -64),
        mask    = MASK_SOLID_BRUSHONLY,
    })

    if tr.Hit then
        util.Decal("Scorch", tr.HitPos + tr.HitNormal * 2, tr.HitPos - tr.HitNormal * 2)
    end

    self:Remove()
end

--------------------------------------------------------------------------------
-- Take Damage: Shoot grenades to detonate them early
--------------------------------------------------------------------------------

function ENT:OnTakeDamage(dmginfo)
    if SERVER and dmginfo:GetDamage() > 5 then
        self:Detonate()
    end
end

--------------------------------------------------------------------------------
-- Client-Side Rendering
--------------------------------------------------------------------------------

function ENT:Draw()
    self:DrawModel()

    if CLIENT and self:GetDetonateTime() > 0 then
        local remaining = self:GetDetonateTime() - CurTime()

        -- Pulsing red glow in the last 1.5 seconds of fuse                             
        if remaining < 1.5 and remaining > 0 then
            local urgency = 1 - (remaining / 1.5)
            local pulse = math.sin(CurTime() * (10 + urgency * 20)) * 0.5 + 0.5

            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos          = self:GetPos()
                dlight.r            = 255
                dlight.g            = math.floor(80 * (1 - pulse))
                dlight.b            = 0
                dlight.brightness   = 1.5 * pulse
                dlight.size         = 64
                dlight.decay        = 300
                dlight.dietime      = CurTime() + 0.1
            end
        end
    end
end
