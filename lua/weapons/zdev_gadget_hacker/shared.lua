--DEFINE_BASECLASS( "weapon_base" )
SWEP.Base				= "weapon_base"
SWEP.PrintName			= "Hacker Armband"

SWEP.Spawnable			= true
SWEP.AdminOnly			= true

SWEP.ViewModel			= Model("models/weapons/v_c4.mdl")
SWEP.WorldModel			= Model("models/weapons/w_c4.mdl")
SWEP.Slot				= 0
SWEP.SlotPos			= 0
SWEP.HoldType			= "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.m_WeaponDeploySpeed	= 1.5
SWEP.DisableDuplicator		= true
SWEP.m_bPlayPickupSound		= Sound( "" )
SWEP.m_iLastReload			= 0
SWEP.m_iNextReload			= 10
SWEP.m_iReloadDelay			= 1