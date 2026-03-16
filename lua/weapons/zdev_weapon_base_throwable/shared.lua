
-- ============================================================================
-- SWEP BASE
-- ============================================================================
-- WEP.Base = "weapon_zdev_base"
-- ============================================================================
-- SPAWNMENU PROPERTIES
-- ============================================================================

SWEP.PrintName = "ZDEV Base Throwable"		-- Display name in spawn menu-- Default  "Scripted Weapon"
SWEP.Author = "ZCOM Studios"		-- Author name-- Default  ""
SWEP.Contact = "dev@zcom-studios.com"		-- Contact information-- Default  ""
SWEP.Purpose = "Basic throwable weapon framework. Used for grenades, deployable gadgets, etc."		-- Purpose/description-- Default  ""
SWEP.Instructions = "Hold left click to increasae throw force. Release to throw. Click once for lob and click again for a high arc. Right-click throw down at the ground where you are standing. "		-- Usage instructions-- Default  ""
SWEP.Category = "ZDEV"		-- Spawn menu category-- Default  "#spawnmenu.category.other"

SWEP.Spawnable = true		-- Whether weapon appears in spawn menu-- Default  false	-- Whether weapon appears in spawn menu-- Default  false
SWEP.AdminOnly = false		-- Whether only admins can spawn this weapon-- Default  false

SWEP.ScriptedEntityType = "weapon"
SWEP.HoldType = "slam"
SWEP.ViewModelFOV = 59.675891726405
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/cstrike/c_eq_flashbang.mdl"
SWEP.WorldModel = "models/weapons/w_eq_flashbang.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
-- 
SWEP.Weight = 3				-- Higher weight = higher priority-- Default  5
SWEP.AutoSwitchTo = true			-- Can auto-switch TO this weapon when picked up-- Default  true-- Can auto-switch TO this weapon when picked up-- Default  true
SWEP.AutoSwitchFrom = true				-- Can auto-switch FROM this weapon when out of ammo-- Default  true

SWEP.m_WeaponDeploySpeed = 1.0
SWEP.DisableDuplicator = false
SWEP.m_bPlayPickupSound = true

SWEP.BobScale = 1
SWEP.SwayScale = 1

SWEP.Slot = 1 			-- 0 = Melee, 1 = Pistols, 2 = Shotguns/SMGs, 3 = Rifles, 4 = Explosives, 5 = Tools Default: 0
SWEP.SlotPos = 1		-- Position within slot (0-128) Default: 10

SWEP.DrawAmmo = true-- Draw default HL2 ammo counter Default: true
SWEP.DrawCrosshair = true-- Draw default crosshair Default: true
SWEP.DrawWeaponInfoBox = true-- Draw weapon selection info box (instructions, etc.) Default: true
SWEP.BounceWeaponIcon = false -- Bounce weapon icon in weapon selection Default: true

SWEP.AccurateCrosshair = false	-- Crosshair positioned in 3D space (like Jeep) Instead of center of screen-- Default  false
SWEP.CSMuzzleFlashes = false	-- Required for CS:S/DoD:S view models-- Default  false
SWEP.CSMuzzleX = false 			-- Requires CSMuzzleFlashes = true-- Default  false

-- ============================================================================
-- AMMO CONFIGURATION
-- ============================================================================
SWEP.Primary.Ammo = "grenade"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = false

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

-- ============================================================================
-- PROJECTILE CONFIGURATION
-- ============================================================================

SWEP.Projectile = {
    WorldModel = "models/weapons/w_eq_flashbang.mdl",
    ViewModel = "models/weapons/w_eq_flashbang.mdl",
    VMSpriteMaterial = "sprites/glow04",
    VMSpriteScale = 1,
    VMSpriteColor = Color(255, 77, 0, 255),
    Entity = "zdev_projectile_base_grenade",
    Velocity = 1000
}

SWEP.ViewModelBoneMods = {
	["v_weapon.Flashbang_Parent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
SWEP.WElements = {
	["mdl_projectile_w"] = { type = "Model", model = SWEP.Projectile.WorldModel, bone = "ValveBiped.Anim_Attachment_RH", rel = "", pos = Vector(1.271, 1.21, -0.129), angle = Angle(-2.178, 20.454, -75.255), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["mdl_projectile"] = { type = "Model", model = SWEP.Projectile.ViewModel, bone = "v_weapon.Flashbang_Parent", rel = "", pos = Vector(1.866, 6.019, -0.509), angle = Angle(6.35, 14.298, -80.22), size = Vector(0.75, 0.75, 0.75), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["spr_projectile_fx"] = { type = "Sprite", sprite = SWEP.Projectile.VMSpriteMaterial, bone = "ValveBiped.Bip01_R_Hand", rel = "mdl_projectile", pos = Vector(-0.042, 0.962, 5.59), size = { x = SWEP.Projectile.VMSpriteScale, y = SWEP.Projectile.VMSpriteScale }, color = SWEP.Projectile.VMSpriteColor, nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "PinPulled")
    self:NetworkVar("Float", 0, "DetonateTime")
    self:NetworkVar("Float", 1, "ThrowTime")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Think()
end

function SWEP:Tick()
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:OnReloaded()
end

function SWEP:OnRestore()
end

function SWEP:Equip(newOwner)
end

function SWEP:EquipAmmo(ply)
end

function SWEP:OnDrop(owner)
end

function SWEP:OwnerChanged()
end

function SWEP:TranslateActivity(act)
	return act
end

function SWEP:SetWeaponHoldType(name)
	self:SetHoldType(name)
end

function SWEP:AcceptInput(inputName, activator, caller, data)
	return false
end

function SWEP:KeyValue(key, value)
	return false
end

function SWEP:FireAnimationEvent(pos, ang, event, options, source)
	return false
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end			-- Check if we can attack

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:GetOwner():SetAnimation(PLAYER_ATTACK1)

	self:SetNextPrimaryFire(CurTime() + 1.0)
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	self:GetOwner():SetAnimation(PLAYER_ATTACK2)

	self:SetNextSecondaryFire(CurTime() + 1.0)
end

function SWEP:Reload()
	self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:CanPrimaryAttack()
	return tobool(self:Clip1() <= 0)
end

function SWEP:CanSecondaryAttack()
	return tobool(self:Clip1() <= 0)
end

function SWEP:TakePrimaryAmmo(amount)
	self:SetClip1(self:Clip1() - amount)
end

function SWEP:TakeSecondaryAmmo(amount)
	self:SetClip2(self:Clip2() - amount)
end

function SWEP:Ammo1()
	local owner = self:GetOwner()
	if not IsValid(owner) then return 0 end

	return owner:GetAmmoCount(self.Primary.Ammo)
end

function SWEP:Ammo2()
	local owner = self:GetOwner()
	if not IsValid(owner) then return 0 end

	return owner:GetAmmoCount(self.Secondary.Ammo)
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:DoImpactEffect(traceResult, damageType)
	return false
end

function SWEP:GetTracerOrigin()
	return self:GetOwner():GetShootPos()
end
