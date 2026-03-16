--[[    MetaHUD FN Five-Seven
    Hyper-realistic FN Five-Seven pistol implementation.
        Real-world specifications:
    - Caliber: 5.7×28mm    - Magazine: 20 rounds
    - Muzzle velocity: ~650 m/s (2,133 ft/s)    - Effective range: 50m
    - Weight: 744g loaded    - Action: Short recoil, delayed blowback
        Features:
    - High capacity magazine    - Armor-piercing capability
    - Low recoil due to small caliber
    - Excellent accuracy]]
SWEP.Base               = "zdev_weapon_base_pistol"
SWEP.PrintName          = "FN Five-Seven"
SWEP.Author             = "MetaHUD"
SWEP.Contact            = ""
SWEP.Purpose            = "High-capacity tactical pistol"
SWEP.Instructions       = "Primary: Fire | Secondary: Ironsights | R: Reload"
SWEP.Category           = "ZDEV Weapons: Pistols"

SWEP.Spawnable          = true
SWEP.AdminOnly          = false
-- Model configuration
SWEP.ViewModel          = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.WorldModel         = "models/weapons/w_pist_fiveseven.mdl"
SWEP.HoldType           = "pistol"
SWEP.ViewModelFOV       = 54
SWEP.ViewModelFlip      = false
SWEP.UseHands           = true
--------------------------------------------------------------------------------
-- BALLISTIC PROPERTIES (5.7×28mm)
--------------------------------------------------------------------------------
SWEP.Ballistics = {
    Damage            = 22,           -- Lower per-shot damage than 9mm
    DamageFalloff     = 0.6,          -- Better velocity retention
    DamageFalloffStart = 1000, 
    DamageFalloffEnd   = 1500, 
    DamageFalloffDist = 1500,         -- Effective range ~50m
    NumShots          = 1,
    NumBullets        = 1,            -- Projectiles per shot
    Spread            = 0.012,        -- Excellent accuracy
    MuzzleVelocity    = 21336,        -- 650 m/s in Source units (1m = 32.8u)
    PenetrationPower  = 2,            -- Armor-piercing capability
    Force             = 3,            -- Lower recoil impulse
    Tracer            = 0,
    TracerName        = "Tracer",
    TracerCount       = 0,
    Recoil            = 0.2,          -- Minimal recoil
    RecoilRandom      = 0.1,
    SpreadRandom      = 0.015,
    SpreadMax         = 0.03,
    SpreadMin         = 0.005,
    SpreadRecovery      = 8.0,          -- Fast spread recovery
    RecoilRecovery      = 8.0,          -- Fast recoil recovery
}

---------------------------------------------------------------------------------- 
-- MAGAZINE CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Primary.ClipSize       = 20      -- Standard 20-round magazine
SWEP.Primary.DefaultClip    = 20
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "pistol"
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
---------------------------------------------------------------------------------- 
-- TIMING PROPERTIES
--------------------------------------------------------------------------------
SWEP.Timing = {
    FireDelay         = 0.075,        -- ~800 RPM cyclic rate
    DeployTime        = 0.45,    
    HolsterTime       = 0.3,
    ReloadTime        = 1.8,          -- Tactical reload    
    ReloadTimeEmpty   = 2.2,          -- Empty reload with slide rack
    IronsightTime     = 0.14,         -- Fast sight acquisition
}
---------------------------------------------------------------------------------- 
-- RECOIL CONFIGURATION (Low recoil due to 5.7mm)
--------------------------------------------------------------------------------
SWEP.Recoil = {    
    ViewPunch         = Angle(-0.8, 0, 0),    -- Minimal vertical kick
    ViewPunchRandom   = Angle(0.3, 0.15, 0),  -- Slight randomization    
    -- Sustained fire recoil climb
    ClimbStart        = 0.5,
    ClimbEnd          = 2.0,
    ClimbPerShot      = 0.4,
    ClimbMax          = 2.5,
    ClimbDecay        = 3.0,
    -- Horizontal drift
    DriftPerShot      = 0.2,    
    DriftMax          = 1.5,
    DriftDecay        = 2.5,
}
--------------------------------------------------------------------------------
-- ACCURACY MODIFIERS
--------------------------------------------------------------------------------
SWEP.Accuracy = {
    BaseSpread        = 0.012,
    MinSpread         = 0.005,        -- Inherently accurate
        -- Movement penalties (minimal due to light weight)
    MovingMult        = 1.8,
    RunningMult       = 3.0,
        CrouchBonus       = 0.7,    
    -- Ironsight bonus
    IronsightEnabled  = true,
    IronsightMult     = 0.4,          -- Excellent sight picture
        -- Sustained fire penalty
    ShotSpreadAdd     = 0.008,        -- Low recoil = low spread increase
    ShotSpreadMin     = 0.005,
    ShotSpreadMax     = 0.04,
    ShotSpreadDecay   = 8.0,          -- Fast recovery
}
--------------------------------------------------------------------------------
-- IRONSIGHT CONFIGURATION
--------------------------------------------------------------------------------
SWEP.IronSights = {
    Enabled           = true,
    -- View model positioning for ADS
    Pos               = Vector(-5.95, -3, 2.85),
    -- View model angles for ADS
    Ang               = Vector(0.5, 0, 0),
    FOV               = 50,           -- Slight zoom
    Sensitivity       = 0.7,          -- Reduced mouse sensitivity when ADS
}
--------------------------------------------------------------------------------
-- WEAPON SWAY (Minimal due to light weight)
--------------------------------------------------------------------------------
SWEP.Sway = {
    Enabled           = true,
        -- Idle sway
    IdleScale         = 0.3,
    IdleSpeed         = 1.2,
    IdleMult          = 1.0,
        -- Movement sway
    WalkScale         = 0.8,
    RunScale          = 1.5,
        -- Breathing effect
    BreathingScale    = 0.15,
    BreathingSpeed    = 0.8,
}
--------------------------------------------------------------------------------
-- SOUND CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Sounds = {    
    Fire          = Sound("Weapon_FiveSeven.Single"),
    FireSilenced  = Sound("Weapon_FiveSeven.Single"),  -- TODO: Add suppressed sound
    DryFire       = Sound("Weapon_Pistol.Empty"),
    Reload        = Sound("Weapon_FiveSeven.Reload"),
    ReloadEmpty   = Sound("Weapon_FiveSeven.Reload"),
    Deploy        = Sound("weapons/draw_secondary.wav"),
    MagOut        = Sound("weapons/fiveseven/fiveseven_clipout.wav"),
    MagIn         = Sound("weapons/fiveseven/fiveseven_clipin.wav"),
    MagDrop       = Sound("weapons/fiveseven/fiveseven_clipdrop.wav"),
    SlideBack     = Sound("weapons/fiveseven/fiveseven_slideback.wav"),
    SlideRelease  = Sound("weapons/fiveseven/fiveseven_sliderelease.wav"),
}--------------------------------------------------------------------------------
-- MUZZLE FLASH CONFIGURATION
--------------------------------------------------------------------------------
SWEP.MuzzleFlash = {
    Enabled           = true,
    Model             = "models/weapons/muzzleflash_57.mdl",
    Scale             = 0.7,          -- Smaller flash due to lower powder charge
    Brightness        = 1.8,    
    Color             = Color(255, 200, 120),
    Duration          = 0.04,
}
--------------------------------------------------------------------------------
-- SHELL EJECTION
--------------------------------------------------------------------------------
SWEP.ShellEject = {
    Enabled           = true,
    Model             = "models/shells/shell_57.mdl",  -- 5.7mm shell
    Velocity          = Vector(50, 80, 100),
    AngVelocity       = Angle(0, 200, 0),
}
--------------------------------------------------------------------------------
-- CUSTOM FUNCTIONS
--------------------------------------------------------------------------------
-- Add any custom functionality here
-- For example, you could add a custom reload animation or sound
-- or modify the way the weapon handles certain actions.    