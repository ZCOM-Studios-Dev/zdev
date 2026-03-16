SWEP.Base = "weapon_base"

SWEP.PrintName = "ZDev Axe"
SWEP.Author = "Your Name"
SWEP.Contact = ""
SWEP.Purpose = "Melee weapon that detects trees"
SWEP.Instructions = "Left click to swing, right click for secondary attack"
SWEP.Category = "ZDEV"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54

SWEP.Weight = 5
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = true

SWEP.Slot = 0
SWEP.SlotPos = 1

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "melee"
SWEP.Offset = Vector(0, 0, 0)

function SWEP:Initialize()
	self:SetHoldType("melee")
end

function SWEP:Deploy()
	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	-- Set next attack time
	self:SetNextPrimaryFire(CurTime() + 0.5)
	
	-- Swing animation
	self:SendWeaponAnim(ACT_VM_HITCENTER)
	owner:SetAnimation(PLAYER_ATTACK1)
	
	-- Trace for entities
	local trace = {}
	trace.start = owner:GetShootPos()
	trace.endpos = trace.start + owner:GetAimVector() * 80
	trace.filter = owner
	
	local tr = util.TraceLine(trace)
	
	-- Check if we hit an entity with "tree" in its model name
	if tr.Hit and tr.Entity:IsValid() then
		local modelName = string.lower(tr.Entity:GetModel())
		if string.find(modelName, "tree") then
			Msg("Player has received wood.\n")
		end
	end
end

function SWEP:SecondaryAttack()
	-- Secondary attack functionality
	self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:Think()
end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return true
end

function SWEP:Reload()
	return false
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
end

function SWEP:OnRestore()
end

function SWEP:OnDrop(owner)
end

function SWEP:OwnerChanged()
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

function SWEP:TranslateActivity(act)
	return act
end

function SWEP:SetWeaponHoldType(name)
	self:SetHoldType(name)
end

function SWEP:Equip(newOwner)
end

function SWEP:EquipAmmo(ply)
end

function SWEP:ShouldDropOnDie()
	return true
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:GetNPCBulletSpread(proficiency)
	return 15
end

function SWEP:GetNPCBurstSettings()
	return 3, 10, 0.1
end

function SWEP:GetNPCRestTimes()
	return 0.3, 0.6
end

function SWEP:NPCShoot_Primary(shootPos, shootDir)
	self:PrimaryAttack()
end

function SWEP:NPCShoot_Secondary(shootPos, shootDir)
	self:SecondaryAttack()
end

function SWEP:DoImpactEffect(traceResult, damageType)
	return false
end

function SWEP:GetTracerOrigin()
	return self:GetOwner():GetShootPos()
end

if CLIENT then
	function SWEP:DrawHUD()
	end

	function SWEP:DrawHUDBackground()
	end

	function SWEP:DoDrawCrosshair(x, y)
		return false
	end

	function SWEP:DrawWeaponSelection(x, y, width, height, alpha)
		self:PrintWeaponInfo(x, y, alpha)
	end

	function SWEP:PrintWeaponInfo(x, y, alpha)
	end

	function SWEP:DrawWorldModel(flags)
		self:DrawModel()
	end

	function SWEP:DrawWorldModelTranslucent(flags)
		self:DrawModel()
	end

	function SWEP:ViewModelDrawn(viewModel, flags)
	end

	function SWEP:PreDrawViewModel(vm, weapon, ply, flags)
		return false
	end

	function SWEP:PostDrawViewModel(vm, weapon, ply, flags)
	end

	function SWEP:ShouldDrawViewModel()
		return true
	end

	function SWEP:GetViewModelPosition(eyePos, eyeAng)
		return eyePos, eyeAng
	end

	function SWEP:CalcViewModelView(viewModel, oldEyePos, oldEyeAng, eyePos, eyeAng)
		return eyePos, eyeAng
	end

	function SWEP:CalcView(ply, pos, ang, fov)
		return pos, ang, fov
	end

	function SWEP:TranslateFOV(currentFOV)
		return currentFOV
	end

	function SWEP:AdjustMouseSensitivity()
		return 1.0
	end

	function SWEP:FreezeMovement()
		return false
	end

	function SWEP:HUDShouldDraw(element)
		return true
	end

	function SWEP:CustomAmmoDisplay()
	end

	function SWEP:RenderScreen()
	end
end