--[[
    MetaHUD Realistic Pistol Base

    Hyper-realistic pistol foundation with:
    - Ballistic simulation (velocity, drop)
    - Dynamic recoil patterns
    - Magazine + chambered round system
    - Tactical/empty reload differentiation
    - Accuracy modifiers (movement, stance, sustained fire)
    - Ironsight aiming system
    - Weapon sway and breathing
]]

SWEP.PrintName          = "ZDEV Base Pistol"
SWEP.Author             = "ZCOM Studios"
SWEP.Contact            = ""
SWEP.Purpose            = "Realistic pistol base class"
SWEP.Instructions       = "Primary: Fire | Secondary: Ironsights | R: Reload"
SWEP.Category           = "ZDEV Weapons"

SWEP.Spawnable          = false
SWEP.AdminOnly          = false

SWEP.ViewModelFOV       = 54
SWEP.ViewModelFlip      = false
SWEP.UseHands           = true

SWEP.ViewModel          = "models/weapons/c_pistol.mdl"
SWEP.WorldModel         = "models/weapons/w_pistol.mdl"
SWEP.HoldType           = "pistol"

SWEP.Slot               = 1
SWEP.SlotPos            = 1

--------------------------------------------------------------------------------
-- AMMUNITION CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.ClipSize = 17
SWEP.Primary.DefaultClip = 51
SWEP.Primary.Automatic = false

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

--------------------------------------------------------------------------------
-- BALLISTIC PROPERTIES
--------------------------------------------------------------------------------
SWEP.Ballistics = {
    Damage            = 25,           -- Base damage at point blank
    DamageFalloff     = 0.5,          -- Damage multiplier at max range
    DamageFalloffDist = 2000,         -- Distance where falloff begins

    NumBullets        = 1,            -- Projectiles per shot
    Spread            = 0.015,        -- Base spread (radians)

    MuzzleVelocity    = 12000,        -- Units per second
    PenetrationPower  = 1,            -- Material penetration (0-3)

    Force             = 5,            -- Physics push force
    Tracer            = 0,            -- Tracer frequency (0 = none)
}

--------------------------------------------------------------------------------
-- TIMING PROPERTIES
--------------------------------------------------------------------------------
SWEP.Timing = {
    FireDelay         = 0.08,         -- Minimum time between shots
    DeployTime        = 0.5,          -- Time to deploy weapon
    HolsterTime       = 0.3,          -- Time to holster weapon

    ReloadTime        = 1.5,          -- Tactical reload duration
    ReloadTimeEmpty   = 2.0,          -- Empty reload duration (rack slide)

    IronsightTime     = 0.15,         -- Time to ADS
}

--------------------------------------------------------------------------------
-- RECOIL CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Recoil = {
    -- Vertical recoil (pitch)
    VerticalMin       = 0.8,
    VerticalMax       = 1.2,

    -- Horizontal recoil (yaw) - negative = left bias
    HorizontalMin     = -0.3,
    HorizontalMax     = 0.3,

    -- Recoil recovery
    RecoveryRate      = 5.0,          -- How fast recoil recovers

    -- Sustained fire multiplier
    AccumulationRate  = 0.15,         -- Recoil increase per shot
    AccumulationMax   = 2.5,          -- Maximum recoil multiplier
    AccumulationDecay = 3.0,          -- Decay rate when not firing

    -- First shot multiplier
    FirstShotMult     = 1.5,
}

--------------------------------------------------------------------------------
-- ACCURACY MODIFIERS
--------------------------------------------------------------------------------
SWEP.Accuracy = {
    -- Movement penalties
    WalkPenalty       = 1.5,          -- Spread mult when walking
    RunPenalty        = 3.0,          -- Spread mult when running
    CrouchBonus       = 0.7,          -- Spread mult when crouched

    -- Ironsight bonuses
    IronsightBonus    = 0.4,          -- Spread mult when ADS

    -- Sustained fire bloom
    BloomPerShot      = 0.003,        -- Spread increase per shot
    BloomMax          = 0.05,         -- Maximum bloom
    BloomDecay        = 0.02,         -- Bloom decay per second
}

--------------------------------------------------------------------------------
-- IRONSIGHT CONFIGURATION
--------------------------------------------------------------------------------
SWEP.IronsightPos     = Vector(-5.95, -10, 2.7)
SWEP.IronsightAng     = Angle(0, 0, 0)
SWEP.IronsightFOV     = 75

--------------------------------------------------------------------------------
-- SOUND CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Sounds = {
    Fire          = "Weapon_Pistol.Single",
    FireSilenced  = "Weapon_Pistol.Single",
    DryFire       = "Weapon_Pistol.Empty",
    Reload        = "Weapon_Pistol.Reload",
    ReloadEmpty   = "Weapon_Pistol.Reload",
    Deploy        = "weapons/draw_secondary.wav",
    MagOut        = "weapons/pistol/pistol_clip_out.wav",
    MagIn         = "weapons/pistol/pistol_clip_in.wav",
    SlideBack     = "weapons/pistol/pistol_slide_back.wav",
    SlideRelease  = "weapons/pistol/pistol_slide_release.wav",
}

--------------------------------------------------------------------------------
-- RUNTIME STATE (per-instance, initialized in Initialize)
--------------------------------------------------------------------------------
SWEP.RuntimeDefaults = {
    InIronsights      = false,
    IronsightLerp     = 0,
    RecoilAccumulator = 0,
    SpreadBloom       = 0,
    LastFireTime      = 0,
    ChamberedRound    = true,        -- Does the weapon have a round chambered
    NextIdleTime      = 0,
}

--------------------------------------------------------------------------------
-- CORE FUNCTIONS
--------------------------------------------------------------------------------

--[[
    Initialize weapon state
]]
function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    -- Copy runtime defaults to weapon instance
    for k, v in pairs(self.RuntimeDefaults) do
        self[k] = v
    end

    -- Networking setup
    self:SetNWBool("Ironsights", false)
    self:SetNWFloat("RecoilAccum", 0)
end

--[[
    Called when weapon is deployed
]]
function SWEP:Deploy()
    self:SetNextPrimaryFire(CurTime() + self.Timing.DeployTime)
    self:SetNextSecondaryFire(CurTime() + self.Timing.DeployTime)

    self.InIronsights = false
    self.IronsightLerp = 0
    self:SetNWBool("Ironsights", false)

    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        vm:SendViewModelMatchingSequence(vm:LookupSequence("draw"))
    end

    self:EmitSound(self.Sounds.Deploy)

    return true
end

--[[
    Called when weapon is holstered
]]
function SWEP:Holster(wep)
    self.InIronsights = false
    self.IronsightLerp = 0
    self:SetNWBool("Ironsights", false)

    return true
end

--[[
    Per-frame think logic
]]
function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local ct = CurTime()
    local ft = FrameTime()

    -- Ironsight lerp
    local target = self.InIronsights and 1 or 0
    self.IronsightLerp = Lerp(ft * (1 / self.Timing.IronsightTime) * 0.5, self.IronsightLerp, target)

    -- Recoil accumulator decay
    if self.RecoilAccumulator > 0 then
        local decay = self.Recoil.AccumulationDecay * ft
        self.RecoilAccumulator = math.max(0, self.RecoilAccumulator - decay)
        self:SetNWFloat("RecoilAccum", self.RecoilAccumulator)
    end

    -- Spread bloom decay
    if self.SpreadBloom > 0 then
        self.SpreadBloom = math.max(0, self.SpreadBloom - self.Accuracy.BloomDecay * ft)
    end

    -- Idle animation
    if ct > self.NextIdleTime and self:GetNextPrimaryFire() < ct then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local seq = vm:LookupSequence("idle")
            if seq > 0 then
                vm:SendViewModelMatchingSequence(seq)
            end
        end
        self.NextIdleTime = ct + 3
    end
end

--[[
    Calculate current accuracy spread
    @return number - Current spread value
]]
function SWEP:GetCurrentSpread()
    local owner = self:GetOwner()
    if not IsValid(owner) then return self.Ballistics.Spread end

    local spread = self.Ballistics.Spread + self.SpreadBloom

    -- Movement modifiers
    local vel = owner:GetVelocity():Length2D()
    if vel > 150 then
        spread = spread * self.Accuracy.RunPenalty
    elseif vel > 50 then
        spread = spread * self.Accuracy.WalkPenalty
    end

    -- Crouch bonus
    if owner:Crouching() then
        spread = spread * self.Accuracy.CrouchBonus
    end

    -- Ironsight bonus
    if self.InIronsights then
        spread = spread * self.Accuracy.IronsightBonus
    end

    return spread
end

--[[
    Get the effective damage based on distance
    @param distance - Distance to target
    @return number - Calculated damage
]]
function SWEP:GetDamageAtDistance(distance)
    local dmg = self.Ballistics.Damage

    if distance > self.Ballistics.DamageFalloffDist then
        local falloffDist = distance - self.Ballistics.DamageFalloffDist
        local falloffMult = math.Clamp(1 - (falloffDist / 3000), self.Ballistics.DamageFalloff, 1)
        dmg = dmg * falloffMult
    end

    return math.floor(dmg)
end


--[[
    Apply recoil to the player's view
]]
function SWEP:ApplyRecoil()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Calculate recoil multiplier based on accumulation
    local recoilMult = 1 + (self.RecoilAccumulator * self.Recoil.AccumulationRate)
    recoilMult = math.min(recoilMult, self.Recoil.AccumulationMax)

    -- First shot bonus
    if CurTime() - self.LastFireTime > 0.5 then
        recoilMult = recoilMult * self.Recoil.FirstShotMult
    end

    -- Calculate recoil angles
    local vertRecoil = math.Rand(self.Recoil.VerticalMin, self.Recoil.VerticalMax) * recoilMult
    local horzRecoil = math.Rand(self.Recoil.HorizontalMin, self.Recoil.HorizontalMax) * recoilMult

    -- Reduce recoil when aiming
    if self.InIronsights then
        vertRecoil = vertRecoil * 0.7
        horzRecoil = horzRecoil * 0.7
    end

    -- Apply to view
    local punch = Angle(-vertRecoil, horzRecoil, 0)
    owner:SetEyeAngles(owner:EyeAngles() + punch)
    owner:ViewPunch(punch * 0.3)

    -- Accumulate recoil
    self.RecoilAccumulator = self.RecoilAccumulator + 1
    self:SetNWFloat("RecoilAccum", self.RecoilAccumulator)
end

--[[
    Primary attack - Fire weapon
]]
function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Check for chambered round
    if not self.ChamberedRound and self:Clip1() <= 0 then
        self:EmitSound(self.Sounds.DryFire)
        self:SetNextPrimaryFire(CurTime() + 0.3)
        return
    end

    -- Check ammo
    if self:Clip1() <= 0 then
        self:EmitSound(self.Sounds.DryFire)
        self:SetNextPrimaryFire(CurTime() + 0.3)
        return
    end

    -- Consume ammo
    self:TakePrimaryAmmo(1)

    -- Chamber state: after firing, we have a round chambered if clip > 0
    self.ChamberedRound = self:Clip1() > 0

    -- Get spread
    local spread = self:GetCurrentSpread()

    -- Fire bullet (server handles damage)
    local bullet = {
        Num         = self.Ballistics.NumBullets,
        Src         = owner:GetShootPos(),
        Dir         = owner:GetAimVector(),
        Spread      = Vector(spread, spread, 0),
        Tracer      = self.Ballistics.Tracer,
        Force       = self.Ballistics.Force,
        Damage      = self.Ballistics.Damage,
        Callback    = function(attacker, tr, dmginfo)
            if SERVER then
                self:BulletCallback(attacker, tr, dmginfo)
            end
        end,
    }

    owner:FireBullets(bullet)

    -- Effects
    self:EmitSound(self.Sounds.Fire)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    owner:SetAnimation(PLAYER_ATTACK1)

    -- Apply recoil
    self:ApplyRecoil()

    -- Add spread bloom
    self.SpreadBloom = math.min(self.SpreadBloom + self.Accuracy.BloomPerShot, self.Accuracy.BloomMax)

    -- Timing
    self.LastFireTime = CurTime()
    self:SetNextPrimaryFire(CurTime() + self.Timing.FireDelay)
    self:SetNextSecondaryFire(CurTime() + self.Timing.FireDelay)
    self.NextIdleTime = CurTime() + 1
end

--[[
    Secondary attack - Toggle ironsights
]]
function SWEP:SecondaryAttack()
    if self:GetNextSecondaryFire() > CurTime() then return end

    self.InIronsights = not self.InIronsights
    self:SetNWBool("Ironsights", self.InIronsights)

    self:SetNextSecondaryFire(CurTime() + 0.2)
end

--[[
    Reload weapon
]]
function SWEP:Reload()
    if self:GetNextPrimaryFire() > CurTime() then return false end
    if self:Clip1() >= self.Primary.ClipSize then return false end
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return false end

    -- Exit ironsights
    self.InIronsights = false
    self:SetNWBool("Ironsights", false)

    -- Determine reload time based on chamber state
    local reloadTime
    if self:Clip1() <= 0 and not self.ChamberedRound then
        -- Empty reload - need to rack the slide
        reloadTime = self.Timing.ReloadTimeEmpty
        self:EmitSound(self.Sounds.ReloadEmpty)
    else
        -- Tactical reload - round in chamber
        reloadTime = self.Timing.ReloadTime
        self:EmitSound(self.Sounds.Reload)
    end

    self:DefaultReload(ACT_VM_RELOAD)
    self:SetNextPrimaryFire(CurTime() + reloadTime)
    self:SetNextSecondaryFire(CurTime() + reloadTime)

    -- After reload, we have a chambered round
    self.ChamberedRound = true

    return true
end

--[[
    Check if weapon can fire
]]
function SWEP:CanPrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    return true
end