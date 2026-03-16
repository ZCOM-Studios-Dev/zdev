--[[
    Frag Grenade SWEP
    A standalone, gamemode-agnostic grenade weapon for Garry's Mod.
    Features: pin-pull mechanic, cooking with self-detonation risk,
    crosshair-aimed trajectory, physics-based projectile.
]]

AddCSLuaFile()

SWEP.PrintName          = "Frag Grenade"
SWEP.Author             = "Adrian"
SWEP.Instructions       = "Primary: Hold to charge throw power, release to throw. Secondary: Drop at feet."
SWEP.Category           = "ZDEV Weapons: Grenades"

SWEP.Spawnable          = true
SWEP.AdminOnly          = false

SWEP.ViewModel          = "models/weapons/v_eq_fraggrenade.mdl"
SWEP.WorldModel         = "models/weapons/w_eq_fraggrenade.mdl"
SWEP.ViewModelFlip      = true
SWEP.UseHands           = true

SWEP.HoldTypeReady      = "grenade"
SWEP.HoldTypeIdle       = "slam"

SWEP.Slot               = 4
SWEP.SlotPos            = 1

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = true

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic  = false
SWEP.Primary.Delay      = 0.8
SWEP.Primary.Ammo       = "grenade"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

-- Grenade configuration
SWEP.FuseTime           = 4.0       -- Seconds before detonation after pin pull
SWEP.ThrowForceMax      = 1200      -- Maximum throw velocity (at full charge)
SWEP.ThrowForceMin      = 200       -- Minimum throw velocity (no charge)
SWEP.ThrowDelay         = 0.12      -- Delay between release and actual projectile spawn
SWEP.ProjectileClass    = "ent_frag_grenade_proj"
SWEP.ProjectileWorldModel    = "models/weapons/w_eq_fraggrenade.mdl"
SWEP.ProjectileViewModel    = "models/weapons/w_eq_fraggrenade.mdl"
SWEP.ChargeTimeMax      = 2.0       -- Seconds to reach maximum throw force
SWEP.DropForce          = 100       -- Force for secondary attack drop

-- Trajectory rendering configuration
SWEP.TrajectorySteps    = 60        -- Number of points in trajectory curve
SWEP.TrajectoryTimeStep = 0.03      -- Time step per trajectory segment
SWEP.TrajectoryGravity  = 600       -- Gravity for trajectory prediction (Source units/s²)

-- Internal state (not networked, server-authoritative)
SWEP.was_thrown          = false
SWEP.CachedThrowForce    = 0        -- Cached throw force for release

SWEP.ViewModelData = {}
SWEP.ViewModelData.SpriteMaterial       = "sprites/glow04"
SWEP.ViewModelData.SpriteScale          = 1
SWEP.ViewModelData.SpriteColor          = Color(255, 77, 0, 255)

SWEP.ViewModelBoneMods = {
	["v_weapon.Flashbang_Parent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
SWEP.WElements = {
	["mdl_projectile_w"] = { type = "Model", model = SWEP.ProjectileWorldModel, bone = "ValveBiped.Anim_Attachment_RH", rel = "", pos = Vector(1.271, 1.21, -0.129), angle = Angle(-2.178, 20.454, -75.255), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["mdl_projectile"] = { type = "Model", model = SWEP.ProjectileViewModel, bone = "v_weapon.Flashbang_Parent", rel = "", pos = Vector(1.866, 6.019, -0.509), angle = Angle(6.35, 14.298, -80.22), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["spr_projectile_fx"] = { type = "Sprite", sprite = SWEP.ViewModelData.SpriteMaterial, bone = "ValveBiped.Bip01_R_Hand", rel = "mdl_projectile", pos = Vector(-0.042, 0.962, 5.59), size = { x = SWEP.ViewModelData.SpriteScale, y = SWEP.ViewModelData.SpriteScale }, color = SWEP.ViewModelData.SpriteColor, nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}
--------------------------------------------------------------------------------
-- Data Tables (Networked State)
--------------------------------------------------------------------------------

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "PinPulled")
    self:NetworkVar("Bool", 1, "IsDropThrow")     -- True if this is a secondary attack drop
    self:NetworkVar("Float", 0, "DetonateTime")
    self:NetworkVar("Float", 1, "ThrowTime")
    self:NetworkVar("Float", 2, "ChargeStartTime") -- When player started charging throw
end

--------------------------------------------------------------------------------
-- Initialize / Deploy / Holster
--------------------------------------------------------------------------------

function SWEP:Initialize()
    self:SetHoldType(self.HoldTypeIdle)

    self:SetPinPulled(false)
    self:SetIsDropThrow(false)
    self:SetDetonateTime(0)
    self:SetThrowTime(0)
    self:SetChargeStartTime(0)

    self.was_thrown = false
    self.CachedThrowForce = 0

    if CLIENT then
 
        self.ProjectileWorldModel = self.ProjectileWorldModel or "models/dynamite/dynamite.mdl"
        self.ProjectileViewModel = self.ProjectileViewModel or "models/dynamite/dynamite.mdl"

        -- Create a new table for every weapon instance

        self.VElements = table.FullCopy( self.VElements )
        self.WElements = table.FullCopy( self.WElements )
        self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

        self:CreateModels(self.VElements) -- create viewmodels
        self:CreateModels(self.WElements) -- create worldmodels

        -- init view model bone build function
        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:ResetBonePositions(vm)
                
                -- Init viewmodel visibility
                if (self.ShowViewModel == nil or self.ShowViewModel) then
                    vm:SetColor(Color(255,255,255,255))
                else
                    -- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
                    vm:SetColor(Color(255,255,255,1))
                    -- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
                    -- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
                    vm:SetMaterial("Debug/hsv")			
                end
            end
        end
    end
end

function SWEP:Deploy()
    self:SetHoldType(self.HoldTypeIdle)
    self:SetPinPulled(false)
    self:SetIsDropThrow(false)
    self:SetThrowTime(0)
    self:SetChargeStartTime(0)
    self.CachedThrowForce = 0

    return true
end

function SWEP:Holster()
    -- Cannot holster once the pin is pulled — you're committed
    if self:GetPinPulled() then
        return false
    end

    self:SetThrowTime(0)
    self:SetPinPulled(false)
    self:SetIsDropThrow(false)
    self:SetChargeStartTime(0)
    self.CachedThrowForce = 0

    return true
end

function SWEP:Reload()
    return false
end

--------------------------------------------------------------------------------
-- Primary Attack: Pull the Pin
--------------------------------------------------------------------------------

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:PullPin()
end

function SWEP:SecondaryAttack()
    -- Drop grenade at player's feet with minimal force
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:PullPin(true) -- true = drop throw mode
end

function SWEP:PullPin(isDropThrow)
    if self:GetPinPulled() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Consume one grenade from ammo
    if self:Ammo1() <= 0 then return end

    self:SendWeaponAnim(ACT_VM_PULLPIN)
    self:SetHoldType(self.HoldTypeReady)

    self:SetPinPulled(true)
    self:SetIsDropThrow(isDropThrow or false)
    self:SetDetonateTime(CurTime() + self.FuseTime)
    self:SetChargeStartTime(CurTime())

    if SERVER then
        self:EmitSound("weapons/hegrenade/he_pinpull.wav", 60, 100, 0.5)
    end
end

--------------------------------------------------------------------------------
-- Throw Force Calculation
--------------------------------------------------------------------------------

--- Calculates the current throw force based on charge time
--- @return number force The calculated throw force
--- @return number fraction The charge fraction (0-1)
function SWEP:GetCurrentThrowForce()
    local chargeStart = self:GetChargeStartTime()
    if chargeStart <= 0 then
        return self.ThrowForceMin, 0
    end

    local chargeTime = CurTime() - chargeStart
    local fraction = math.Clamp(chargeTime / self.ChargeTimeMax, 0, 1)
    local force = Lerp(fraction, self.ThrowForceMin, self.ThrowForceMax)

    return force, fraction
end

--------------------------------------------------------------------------------
-- Think: State Machine
--------------------------------------------------------------------------------

function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if self:GetPinPulled() then
        local isDropThrow = self:GetIsDropThrow()
        local releaseKey = isDropThrow and IN_ATTACK2 or IN_ATTACK

        -- Player released attack button — begin throw sequence
        if not owner:KeyDown(releaseKey) then
            -- Cache the throw force at release time
            local force, _ = self:GetCurrentThrowForce()
            self.CachedThrowForce = force

            self:BeginThrow()
            self:SetPinPulled(false)

            self:SendWeaponAnim(ACT_VM_THROW)

            if SERVER then
                owner:SetAnimation(PLAYER_ATTACK1)
            end
        else
            -- Still cooking — check if fuse has expired
            if SERVER and CurTime() >= self:GetDetonateTime() then
                self:DetonateInHand()
            end
        end
    elseif self:GetThrowTime() > 0 and CurTime() >= self:GetThrowTime() then
        -- Throw delay elapsed — spawn the projectile
        self:ReleaseProjectile()
    end
end

--------------------------------------------------------------------------------
-- Throw Mechanics
--------------------------------------------------------------------------------

function SWEP:BeginThrow()
    self:SetThrowTime(CurTime() + self.ThrowDelay)
end

function SWEP:ReleaseProjectile()
    if CLIENT then
        self:SetThrowTime(0)
        self:SetIsDropThrow(false)
        self:SetChargeStartTime(0)
        return
    end

    -- SERVER
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self.was_thrown then return end

    self.was_thrown = true

    local isDropThrow = self:GetIsDropThrow()
    local eyeAng = owner:EyeAngles()
    local viewOffset = owner:Crouching() and owner:GetViewOffsetDucked() or owner:GetViewOffset()

    local src, velocity, angImpulse

    if isDropThrow then
        -- Drop throw: spawn at player's feet, throw straight down
        src = owner:GetPos() + Vector(0, 0, 20) -- Slightly above ground
        velocity = Vector(0, 0, -self.DropForce) + owner:GetVelocity()
        angImpulse = Vector(math.random(-200, 200), math.random(-200, 200), 0)
    else
        -- Normal throw: use cached throw force based on charge time
        src = owner:GetPos() + viewOffset
                    + (eyeAng:Forward() * 8)
                    + (eyeAng:Right() * 10)

        -- Calculate throw direction aimed at the crosshair hit position
        local traceTarget = owner:GetEyeTraceNoCursor().HitPos
        local throwAng = (traceTarget - src):Angle()

        -- Adjust pitch for an upward arc (makes throws feel natural)
        throwAng.p = self:CalculateThrowPitch(throwAng.p)
        throwAng.p = math.Clamp(throwAng.p, -90, 90)

        -- Use the cached throw force from when the player released the button
        local speed = self.CachedThrowForce or self.ThrowForceMin
        velocity = throwAng:Forward() * speed + owner:GetVelocity()

        -- Angular impulse for tumbling effect
        angImpulse = Vector(600, math.random(-1200, 1200), 0)
    end

    self:SpawnProjectile(src, Angle(0, 0, 0), velocity, angImpulse, owner)

    -- Consume ammo and clean up
    owner:RemoveAmmo(1, self.Primary.Ammo)

    self:SetThrowTime(0)
    self:SetIsDropThrow(false)
    self:SetChargeStartTime(0)
    self.CachedThrowForce = 0

    -- If the player has more grenades, reset; otherwise remove the weapon
    timer.Simple(0.5, function()
        if not IsValid(self) then return end
        if not IsValid(owner) then return end

        if owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            self.was_thrown = false
            self:Initialize()
            self:Deploy()
            self:SendWeaponAnim(ACT_VM_DRAW)
        else
            owner:StripWeapon(self:GetClass())
        end
    end)
end

--- Converts raw pitch into an arced throw pitch.
--- Looking level (0°) throws slightly upward; looking down throws downward.
function SWEP:CalculateThrowPitch(pitch)
    if pitch < 90 then
        -- Looking forward/up: remap 0..90 → -10..90 (slight upward bias)
        return -10 + pitch * (100 / 90)
    else
        -- Looking behind/down: remap 270..360 → negative range
        local adjustedPitch = 360 - pitch
        return -10 + adjustedPitch * -(100 / 90)
    end
end

--------------------------------------------------------------------------------
-- Detonation in Hand (cooked too long)
--------------------------------------------------------------------------------

function SWEP:DetonateInHand()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self.was_thrown then return end

    self.was_thrown = true

    local viewOffset = owner:Crouching() and owner:GetViewOffsetDucked() or owner:GetViewOffset()
    local src = owner:GetPos() + viewOffset + (owner:GetAngles():Right() * 10)

    -- Spawn grenade right at the player with minimal velocity (it detonates immediately)
    self:SpawnProjectile(src, Angle(0, 0, 0), Vector(0, 0, 1), Vector(0, 0, 0), owner)

    self:SetThrowTime(0)
    self:Remove()
end

--- Called if the weapon is dropped while the pin is pulled (e.g., owner dies)
function SWEP:PreDrop()
    if self:GetPinPulled() then
        self:DetonateInHand()
    end
end

--------------------------------------------------------------------------------
-- Projectile Spawning
--------------------------------------------------------------------------------

function SWEP:SpawnProjectile(pos, ang, velocity, angImpulse, thrower)
    local grenade = ents.Create(self.ProjectileClass)
    if not IsValid(grenade) then
        ErrorNoHalt("[Frag Grenade] Failed to create projectile entity: " .. self.ProjectileClass .. "\n")
        return nil
    end

    grenade:SetPos(pos)
    grenade:SetAngles(ang)
    grenade:SetOwner(thrower)

    -- Physics properties for realistic bouncing
    grenade:SetGravity(0.4)
    grenade:SetFriction(0.2)
    grenade:SetElasticity(0.45)

    grenade:Spawn()
    grenade:Activate()
    grenade:PhysWake()

    local phys = grenade:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(velocity)
        phys:AddAngleVelocity(angImpulse)
    end

    -- Transfer remaining fuse time to the projectile
    if grenade.SetDetonateTime and self:GetDetonateTime() > 0 then
        grenade:SetDetonateTime(self:GetDetonateTime())
    end

    return grenade
end

--------------------------------------------------------------------------------
-- Trajectory Calculation (Shared for prediction)
--------------------------------------------------------------------------------

--- Calculates trajectory points for the grenade throw
--- @param startPos Vector Starting position
--- @param velocity Vector Initial velocity
--- @return table Array of Vector points along the trajectory
function SWEP:CalculateTrajectory(startPos, velocity)
    local points = {}
    local pos = Vector(startPos.x, startPos.y, startPos.z)
    local vel = Vector(velocity.x, velocity.y, velocity.z)
    local gravity = Vector(0, 0, -self.TrajectoryGravity)
    local dt = self.TrajectoryTimeStep

    table.insert(points, Vector(pos.x, pos.y, pos.z))

    for i = 1, self.TrajectorySteps do
        -- Apply gravity to velocity
        vel = vel + gravity * dt
        -- Update position
        pos = pos + vel * dt

        -- Check for collision with world
        local tr = util.TraceLine({
            start = points[#points],
            endpos = pos,
            mask = MASK_SOLID_BRUSHONLY
        })

        if tr.Hit then
            table.insert(points, tr.HitPos)
            break
        end

        table.insert(points, Vector(pos.x, pos.y, pos.z))
    end

    return points
end

--- Gets the predicted throw parameters (position, velocity) for trajectory
--- @return Vector startPos, Vector velocity
function SWEP:GetThrowPrediction()
    local owner = self:GetOwner()
    if not IsValid(owner) then return Vector(0,0,0), Vector(0,0,0) end

    local isDropThrow = self:GetIsDropThrow()
    local eyeAng = owner:EyeAngles()
    local viewOffset = owner:Crouching() and owner:GetViewOffsetDucked() or owner:GetViewOffset()

    if isDropThrow then
        local src = owner:GetPos() + Vector(0, 0, 20)
        local velocity = Vector(0, 0, -self.DropForce) + owner:GetVelocity()
        return src, velocity
    else
        local src = owner:GetPos() + viewOffset
                    + (eyeAng:Forward() * 8)
                    + (eyeAng:Right() * 10)

        local traceTarget = owner:GetEyeTraceNoCursor().HitPos
        local throwAng = (traceTarget - src):Angle()

        throwAng.p = self:CalculateThrowPitch(throwAng.p)
        throwAng.p = math.Clamp(throwAng.p, -90, 90)

        local speed, _ = self:GetCurrentThrowForce()
        local velocity = throwAng:Forward() * speed + owner:GetVelocity()

        return src, velocity
    end
end

--------------------------------------------------------------------------------
-- HUD and Trajectory Rendering (Client)
--------------------------------------------------------------------------------

if CLIENT then


    function SWEP:Holster()
        
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            self:ResetBonePositions(vm)
        end

    end

    function SWEP:ViewModelDrawn()
        
        local vm = self.Owner:GetViewModel()
        if !IsValid(vm) then return end
        
        if (!self.VElements) then return end
        
        self:UpdateBonePositions(vm)

        if (!self.vRenderOrder) then
            
            -- we build a render order because sprites need to be drawn after models
            self.vRenderOrder = {}

            for k, v in pairs( self.VElements ) do
                if (v.type == "Model") then
                    table.insert(self.vRenderOrder, 1, k)
                elseif (v.type == "Sprite" or v.type == "Quad") then
                    table.insert(self.vRenderOrder, k)
                end
            end
            
        end

        for k, name in ipairs( self.vRenderOrder ) do
        
            local v = self.VElements[name]
            if (!v) then self.vRenderOrder = nil break end
            if (v.hide) then continue end
            
            local model = v.modelEnt
            local sprite = v.spriteMaterial
            
            if (!v.bone) then continue end
            
            local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
            
            if (!pos) then continue end
            
            if (v.type == "Model" and IsValid(model)) then

                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                model:SetAngles(ang)
                --model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix( "RenderMultiply", matrix )
                
                if (v.material == "") then
                    model:SetMaterial("")
                elseif (model:GetMaterial() ~= v.material) then
                    model:SetMaterial( v.material )
                end
                
                if (v.skin and v.skin ~= model:GetSkin()) then
                    model:SetSkin(v.skin)
                end
                
                if (v.bodygroup) then
                    for bg_id, bg_val in ipairs( v.bodygroup ) do
                        if (model:GetBodygroup(bg_id - 1) ~= bg_val) then
                            model:SetBodygroup(bg_id - 1, bg_val)
                        end
                    end
                end

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(true)
                end

                render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
                render.SetBlend(v.color.a/255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(false)
                end

            elseif (v.type == "Sprite" and sprite) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

            elseif (v.type == "Quad" and v.draw_func) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                cam.Start3D2D(drawpos, ang, v.size)
                    v.draw_func( self )
                cam.End3D2D()

            end

        end

    end

    SWEP.wRenderOrder = nil
    function SWEP:DrawWorldModel()
        
        if (self.ShowWorldModel == nil or self.ShowWorldModel) then
            self:DrawModel()
        end
        
        if (!self.WElements) then return end
        
        if (!self.wRenderOrder) then

            self.wRenderOrder = {}

            for k, v in pairs( self.WElements ) do
                if (v.type == "Model") then
                    table.insert(self.wRenderOrder, 1, k)
                elseif (v.type == "Sprite" or v.type == "Quad") then
                    table.insert(self.wRenderOrder, k)
                end
            end

        end
        
        if (IsValid(self.Owner)) then
            bone_ent = self.Owner
        else
            -- when the weapon is dropped
            bone_ent = self
        end
        
        for k, name in pairs( self.wRenderOrder ) do
        
            local v = self.WElements[name]
            if (!v) then self.wRenderOrder = nil break end
            if (v.hide) then continue end
            
            local pos, ang
            
            if (v.bone) then
                pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
            else
                pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
            end
            
            if (!pos) then continue end
            
            local model = v.modelEnt
            local sprite = v.spriteMaterial
            
            if (v.type == "Model" and IsValid(model)) then

                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                model:SetAngles(ang)
                --model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix( "RenderMultiply", matrix )
                
                if (v.material == "") then
                    model:SetMaterial("")
                elseif (model:GetMaterial() ~= v.material) then
                    model:SetMaterial( v.material )
                end
                
                if (v.skin and v.skin ~= model:GetSkin()) then
                    model:SetSkin(v.skin)
                end
                
                if (v.bodygroup) then
                    for bg_id, bg_val in ipairs( v.bodygroup ) do
                        if (model:GetBodygroup(bg_id - 1) ~= bg_val) then
                            model:SetBodygroup(bg_id - 1, bg_val)
                        end
                    end
                end

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(true)
                end

                render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
                render.SetBlend(v.color.a/255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)

                if (v.surpresslightning) then
                    render.SuppressEngineLighting(false)
                end

            elseif (v.type == "Sprite" and sprite) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

            elseif (v.type == "Quad" and v.draw_func) then

                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)

                cam.Start3D2D(drawpos, ang, v.size)
                    v.draw_func( self )
                cam.End3D2D()

            end

        end

    end

    function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
        
        local bone, pos, ang
        if (tab.rel and tab.rel ~= "") then
            
            local v = basetab[tab.rel]
            
            if (!v) then return end
            
            -- Technically, if there exists an element with the same name as a bone
            -- you can get in an infinite loop. Let's just hope nobody's that stupid.
            pos, ang = self:GetBoneOrientation( basetab, v, ent )
            
            if (!pos) then return end
            
            pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                
        else
        
            bone = ent:LookupBone(bone_override or tab.bone)

            if (!bone) then return end
            
            pos, ang = Vector(0,0,0), Angle(0,0,0)
            local m = ent:GetBoneMatrix(bone)
            if (m) then
                pos, ang = m:GetTranslation(), m:GetAngles()
            end
            
            if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
                ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
                ang.r = -ang.r -- Fixes mirrored models
            end
        
        end
        
        return pos, ang
    end

    function SWEP:CreateModels( tab )

        if (!tab) then return end

        -- Create the clientside models here because Garry says we can't do it in the render hook
        for k, v in pairs( tab ) do
            if (v.type == "Model" and v.model and v.model ~= "" and (!IsValid(v.modelEnt) or v.createdModel ~= v.model) and 
                    string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
                
                v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
                if (IsValid(v.modelEnt)) then
                    v.modelEnt:SetPos(self:GetPos())
                    v.modelEnt:SetAngles(self:GetAngles())
                    v.modelEnt:SetParent(self)
                    v.modelEnt:SetNoDraw(true)
                    v.createdModel = v.model
                else
                    v.modelEnt = nil
                end
                
            elseif (v.type == "Sprite" and v.sprite and v.sprite ~= "" and (!v.spriteMaterial or v.createdSprite ~= v.sprite) 
                and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
                
                local name = v.sprite.."-"
                local params = { ["$basetexture"] = v.sprite }
                -- make sure we create a unique name based on the selected options
                local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
                for i, j in pairs( tocheck ) do
                    if (v[j]) then
                        params["$"..j] = 1
                        name = name.."1"
                    else
                        name = name.."0"
                    end
                end

                v.createdSprite = v.sprite
                v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
                
            end
        end
        
    end

    local allbones
    local hasGarryFixedBoneScalingYet = false

    function SWEP:UpdateBonePositions(vm)
        
        if self.ViewModelBoneMods then
            
            if (!vm:GetBoneCount()) then return end
            
            -- !! WORKAROUND !! --
            -- We need to check all model names :/
            local loopthrough = self.ViewModelBoneMods
            if (!hasGarryFixedBoneScalingYet) then
                allbones = {}
                for i=0, vm:GetBoneCount() do
                    local bonename = vm:GetBoneName(i)
                    if (self.ViewModelBoneMods[bonename]) then 
                        allbones[bonename] = self.ViewModelBoneMods[bonename]
                    else
                        allbones[bonename] = { 
                            scale = Vector(1,1,1),
                            pos = Vector(0,0,0),
                            angle = Angle(0,0,0)
                        }
                    end
                end
                
                loopthrough = allbones
            end
            -- !! ----------- !! --
            
            for k, v in pairs( loopthrough ) do
                local bone = vm:LookupBone(k)
                if (!bone) then continue end
                
                -- !! WORKAROUND !! --
                local s = Vector(v.scale.x,v.scale.y,v.scale.z)
                local p = Vector(v.pos.x,v.pos.y,v.pos.z)
                local ms = Vector(1,1,1)
                if (!hasGarryFixedBoneScalingYet) then
                    local cur = vm:GetBoneParent(bone)
                    while(cur >= 0) do
                        local pscale = loopthrough[vm:GetBoneName(cur)].scale
                        ms = ms * pscale
                        cur = vm:GetBoneParent(cur)
                    end
                end
                
                s = s * ms
                -- !! ----------- !! --
                
                if vm:GetManipulateBoneScale(bone) ~= s then
                    vm:ManipulateBoneScale( bone, s )
                end
                if vm:GetManipulateBoneAngles(bone) ~= v.angle then
                    vm:ManipulateBoneAngles( bone, v.angle )
                end
                if vm:GetManipulateBonePosition(bone) ~= p then
                    vm:ManipulateBonePosition( bone, p )
                end
            end
        else
            self:ResetBonePositions(vm)
        end
            
    end
        
    function SWEP:ResetBonePositions(vm)
        
        if (!vm:GetBoneCount()) then return end
        for i=0, vm:GetBoneCount() do
            vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
            vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
            vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
        end
        
    end

    --[[*************************
        Global utility code
    *************************]]

    -- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
    -- Does not copy entities of course, only copies their reference.
    -- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
    function table.FullCopy( tab )

        if (!tab) then return nil end
        
        local res = {}
        for k, v in pairs( tab ) do
            if (type(v) == "table") then
                res[k] = table.FullCopy(v) -- recursion ho!
            elseif (type(v) == "Vector") then
                res[k] = Vector(v.x, v.y, v.z)
            elseif (type(v) == "Angle") then
                res[k] = Angle(v.p, v.y, v.r)
            else
                res[k] = v
            end
        end
        
        return res
        
    end

    -- Cached trajectory data for smooth rendering
    local trajectoryPoints = {}
    local lastTrajectoryUpdate = 0
    local TRAJECTORY_UPDATE_RATE = 0.016 -- ~60 FPS update rate

    function SWEP:DrawHUD()
        if not self:GetPinPulled() then return end

        local isDropThrow = self:GetIsDropThrow()

        -- Fuse timer
        local remaining = math.max(0, self:GetDetonateTime() - CurTime())
        local fuseFraction = remaining / self.FuseTime

        -- Throw force (only for primary attack)
        local _, chargeFraction = self:GetCurrentThrowForce()

        local w, h = 200, 12
        local x = ScrW() / 2 - w / 2
        local y = ScrH() / 2 + 50

        -- Background for both bars
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(x - 4, y - 4, w + 8, (h + 8) * 2 + 4)

        -- FUSE BAR (top)
        -- Outer border
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2)

        -- Timer bar (green → red as time runs out)
        local fuseR = math.floor(255 * (1 - fuseFraction))
        local fuseG = math.floor(255 * fuseFraction)
        surface.SetDrawColor(fuseR, fuseG, 0, 230)
        surface.DrawRect(x, y, w * fuseFraction, h)

        -- Fuse label
        draw.SimpleText(
            string.format("FUSE: %.1fs", remaining),
            "DermaDefaultBold",
            ScrW() / 2, y + h / 2,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )

        -- THROW FORCE BAR (bottom) - only show for primary attack
        local forceY = y + h + 8

        if not isDropThrow then
            -- Outer border
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawOutlinedRect(x - 1, forceY - 1, w + 2, h + 2)

            -- Force bar (blue → cyan as charge increases)
            local forceR = math.floor(50 * (1 - chargeFraction))
            local forceG = math.floor(150 + 105 * chargeFraction)
            local forceB = 255
            surface.SetDrawColor(forceR, forceG, forceB, 230)
            surface.DrawRect(x, forceY, w * chargeFraction, h)

            -- Force label
            local forcePercent = math.floor(chargeFraction * 100)
            draw.SimpleText(
                string.format("FORCE: %d%%", forcePercent),
                "DermaDefaultBold",
                ScrW() / 2, forceY + h / 2,
                color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
            )
        else
            -- Drop mode indicator
            surface.SetDrawColor(80, 80, 80, 200)
            surface.DrawRect(x, forceY, w, h)
            draw.SimpleText(
                "DROP MODE",
                "DermaDefaultBold",
                ScrW() / 2, forceY + h / 2,
                Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
            )
        end
    end

    --- Draws the 3D trajectory arc
    function SWEP:DrawTrajectory()
        if not self:GetPinPulled() then
            trajectoryPoints = {}
            return
        end

        -- Update trajectory prediction at fixed rate for performance
        if CurTime() - lastTrajectoryUpdate > TRAJECTORY_UPDATE_RATE then
            local startPos, velocity = self:GetThrowPrediction()
            trajectoryPoints = self:CalculateTrajectory(startPos, velocity)
            lastTrajectoryUpdate = CurTime()
        end

        if #trajectoryPoints < 2 then return end

        local _, chargeFraction = self:GetCurrentThrowForce()
        local isDropThrow = self:GetIsDropThrow()

        -- Calculate colors based on charge
        local baseColor
        if isDropThrow then
            baseColor = Color(255, 200, 100, 255) -- Orange for drop
        else
            -- Blue to cyan based on charge
            baseColor = Color(
                math.floor(50 + 50 * (1 - chargeFraction)),
                math.floor(150 + 105 * chargeFraction),
                255,
                255
            )
        end

        -- Draw the trajectory curve
        cam.Start3D()
            render.SetColorMaterial()

            local numPoints = #trajectoryPoints
            for i = 1, numPoints - 1 do
                local p1 = trajectoryPoints[i]
                local p2 = trajectoryPoints[i + 1]

                -- Fade alpha along the arc
                local alpha = math.floor(255 * (1 - (i / numPoints) * 0.7))
                local lineColor = Color(baseColor.r, baseColor.g, baseColor.b, alpha)

                -- Draw line segment
                render.DrawLine(p1, p2, lineColor, true)

                -- Draw small spheres at intervals for visibility
                if i % 4 == 1 then
                    local sphereSize = 1.5 * (1 - (i / numPoints) * 0.5)
                    render.DrawSphere(p1, sphereSize, 8, 8, lineColor)
                end
            end

            -- Draw impact point marker
            local endPoint = trajectoryPoints[numPoints]
            local impactColor = Color(255, 100, 100, 200)

            -- Impact cross
            local crossSize = 4
            render.DrawLine(endPoint + Vector(-crossSize, 0, 0), endPoint + Vector(crossSize, 0, 0), impactColor, true)
            render.DrawLine(endPoint + Vector(0, -crossSize, 0), endPoint + Vector(0, crossSize, 0), impactColor, true)
            render.DrawLine(endPoint + Vector(0, 0, -crossSize), endPoint + Vector(0, 0, crossSize), impactColor, true)

            -- Impact sphere
            render.DrawSphere(endPoint, 3, 12, 12, impactColor)
        cam.End3D()
    end

    -- Hook into PostDrawOpaqueRenderables for 3D trajectory
    hook.Add("PostDrawOpaqueRenderables", "ZDEV_GrenadeTrajectory", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then return end

        -- Check if this weapon has our trajectory function
        if wep.DrawTrajectory and wep.GetPinPulled then
            wep:DrawTrajectory()
        end
    end)
end
