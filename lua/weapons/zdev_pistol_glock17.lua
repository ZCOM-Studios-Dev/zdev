--[[    MetaHUD Glock 17
    Hyper-realistic Glock 17 pistol implementation.
    
    Real-world specifications:
    - Caliber: 9×19mm Parabellum    - Magazine: 17 rounds
    - Muzzle velocity: ~375 m/s (1,230 ft/s)    - Effective range: 50m
    - Weight: 905g loaded    - Action: Short recoil, locked breech
    
    Features:
    - High capacity magazine    - Reliable striker-fired action
    - Moderate recoil    - Proven accuracy and reliability]]
SWEP.Base              = "zdev_weapon_base_pistol"
SWEP.PrintName          = "Glock 17"
SWEP.Author             = "MetaHUD"
SWEP.Contact            = ""
SWEP.Purpose            = "Standard-issue service pistol"
SWEP.Instructions       = "Primary: Fire | Secondary: Ironsights | R: Reload"
SWEP.Category           = "ZDEV Weapons: Pistols"

SWEP.Spawnable          = true
SWEP.AdminOnly          = false
-- Model configuration
SWEP.ViewModel          = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel         = "models/weapons/w_pist_glock18.mdl"
SWEP.HoldType           = "pistol"
SWEP.ViewModelFOV       = 54
SWEP.ViewModelFlip      = false
SWEP.UseHands           = true
--------------------------------------------------------------------------------
-- BALLISTIC PROPERTIES (9×19mm)
--------------------------------------------------------------------------------
SWEP.Ballistics = {
    Damage            = 28,           -- Standard 9mm damage
    DamageFalloff     = 0.5,          -- Moderate velocity retention
    DamageFalloffStart = 800, 
    DamageFalloffEnd   = 1200, 
    DamageFalloffDist = 1200,         -- Effective range ~50m
    NumShots          = 1,
    NumBullets        = 1,            -- Projectiles per shot
    Spread            = 0.015,        -- Good accuracy
    MuzzleVelocity    = 12300,        -- 375 m/s in Source units (1m = 32.8u)
    PenetrationPower  = 1,            -- Standard penetration
    Force             = 5,            -- Moderate recoil impulse
    Tracer            = 0,
    TracerName        = "Tracer",
    TracerCount       = 0,
    Recoil            = 0.3,          -- Moderate recoil
    RecoilRandom      = 0.15,
    SpreadRandom      = 0.018,
    SpreadMax         = 0.04,
    SpreadMin         = 0.008,
    SpreadRecovery      = 6.0,          -- Moderate spread recovery
    RecoilRecovery      = 6.0,          -- Moderate recoil recovery
}

---------------------------------------------------------------------------------- 
-- MAGAZINE CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Primary.ClipSize       = 17      -- Standard 17-round magazine
SWEP.Primary.DefaultClip    = 17
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
    FireDelay         = 0.09,         -- ~667 RPM cyclic rate
    DeployTime        = 0.5,    
    HolsterTime       = 0.35,
    ReloadTime        = 1.9,          -- Tactical reload    
    ReloadTimeEmpty   = 2.3,          -- Empty reload with slide rack
    IronsightTime     = 0.16,         -- Standard sight acquisition
}
---------------------------------------------------------------------------------- 
-- RECOIL CONFIGURATION (Moderate 9mm recoil)
--------------------------------------------------------------------------------
SWEP.Recoil = {    
    ViewPunch         = Angle(-1.2, 0, 0),    -- Moderate vertical kick
    ViewPunchRandom   = Angle(0.4, 0.2, 0),   -- Moderate randomization    
    -- Sustained fire recoil climb
    ClimbStart        = 0.8,
    ClimbEnd          = 2.5,
    ClimbPerShot      = 0.6,
    ClimbMax          = 3.5,
    ClimbDecay        = 2.5,
    -- Horizontal drift
    DriftPerShot      = 0.3,    
    DriftMax          = 2.0,
    DriftDecay        = 2.0,
}
--------------------------------------------------------------------------------
-- ACCURACY MODIFIERS
--------------------------------------------------------------------------------
SWEP.Accuracy = {
    BaseSpread        = 0.015,
    MinSpread         = 0.008,        -- Good inherent accuracy
    
    -- Movement penalties
    MovingMult        = 2.0,
    RunningMult       = 3.5,
    
    CrouchBonus       = 0.7,    
    -- Ironsight bonus
    IronsightEnabled  = true,
    IronsightMult     = 0.45,         -- Good sight picture
    
    -- Sustained fire penalty
    ShotSpreadAdd     = 0.01,         -- Moderate spread increase
    ShotSpreadMin     = 0.008,
    ShotSpreadMax     = 0.05,
    ShotSpreadDecay   = 6.0,          -- Moderate recovery
}
--------------------------------------------------------------------------------
-- IRONSIGHT CONFIGURATION
--------------------------------------------------------------------------------
SWEP.IronSights = {
    Enabled           = true,
    -- View model positioning for ADS
    Pos               = Vector(-5.8, -3, 2.9),
    -- View model angles for ADS
    Ang               = Vector(0.4, 0, 0),
    FOV               = 52,           -- Slight zoom
    Sensitivity       = 0.7,          -- Reduced mouse sensitivity when ADS
}
--------------------------------------------------------------------------------
-- WEAPON SWAY (Moderate due to polymer frame)
--------------------------------------------------------------------------------
SWEP.Sway = {
    Enabled           = true,
    
    -- Idle sway
    IdleScale         = 0.4,
    IdleSpeed         = 1.0,
    IdleMult          = 1.0,
    
    -- Movement sway
    WalkScale         = 1.0,
    RunScale          = 1.8,
    
    -- Breathing effect
    BreathingScale    = 0.2,
    BreathingSpeed    = 1.0,
}
--------------------------------------------------------------------------------
-- SOUND CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Sounds = {    
    Fire          = Sound("Weapon_Glock.Single"),
    FireSilenced  = Sound("Weapon_Glock.Single"),  -- TODO: Add suppressed sound
    DryFire       = Sound("Weapon_Pistol.Empty"),
    Reload        = Sound("Weapon_Glock.Reload"),
    ReloadEmpty   = Sound("Weapon_Glock.Reload"),
    Deploy        = Sound("weapons/draw_secondary.wav"),
    MagOut        = Sound("weapons/glock/glock_clipout.wav"),
    MagIn         = Sound("weapons/glock/glock_clipin.wav"),
    MagDrop       = Sound("weapons/glock/glock_clipdrop.wav"),
    SlideBack     = Sound("weapons/glock/glock_slideback.wav"),
    SlideRelease  = Sound("weapons/glock/glock_sliderelease.wav"),
}
--------------------------------------------------------------------------------
-- MUZZLE FLASH CONFIGURATION
--------------------------------------------------------------------------------
SWEP.MuzzleFlash = {
    Enabled           = true,
    Model             = "models/weapons/muzzleflash_pistol.mdl",
    Scale             = 0.8,          -- Standard 9mm flash
    Brightness        = 2.0,    
    Color             = Color(255, 220, 150),
    Duration          = 0.05,
}
--------------------------------------------------------------------------------
-- SHELL EJECTION
--------------------------------------------------------------------------------
SWEP.ShellEject = {
    Enabled           = true,
    Model             = "models/shells/shell_9mm.mdl",  -- 9mm shell
    Velocity          = Vector(60, 90, 110),
    AngVelocity       = Angle(0, 220, 0),
}
--------------------------------------------------------------------------------
-- CUSTOM FUNCTIONS
--------------------------------------------------------------------------------
-- Add any custom functionality here
-- For example, you could add a custom reload animation or sound
-- or modify the way the weapon handles certain actions.    