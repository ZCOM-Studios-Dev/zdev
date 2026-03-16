local _f = 'weapons/zdev_weapon_base_grenade/shared.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - Fragmentation Grenade SWEP
----------------------------------------------------------
	Simple grenade weapon with immediate throw mechanics
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

SWEP.PrintName = 'ZDEV Base Grenade'
SWEP.Author = 'ZCOM Studios'
SWEP.Contact = ''
SWEP.Purpose = 'Fragmentation grenade with timed explosive'
SWEP.Instructions = [[Primary Fire: Throw grenade. The grenade will explode after 4 seconds.]]
SWEP.Category = 'ZDEV Weapons'

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModelFOV = 84.221105527638
SWEP.ViewModelFlip = false
SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.HoldType = "slam"

SWEP.Slot = 4
SWEP.SlotPos = 1

--------------------------------------------------------------------------------
-- AMMUNITION CONFIGURATION
--------------------------------------------------------------------------------
SWEP.Primary.Delay = 1.0
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 3	
SWEP.Primary.Ammo = 'grenade'
SWEP.Primary.Sound = Sound('WeaponFrag.Throw')

SWEP.Secondary.Delay = 1.0
SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = 'none'

--------------------------------------------------------------------------------
-- GRENADE PROJECTILE CONFIGURATION
--------------------------------------------------------------------------------
SWEP.GrenadeClass = "npc_grenade_frag"
SWEP.GrenadeModel = "models/conviction/empnade.mdl"

-- Throw force configuration
SWEP.MinThrowForce = 400
SWEP.MaxThrowForce = 1500
SWEP.ThrowChargeTime = 1.5 -- seconds to reach max throw force
SWEP.ThrowOffset = Vector(0, 0, 0) -- offset from player shoot position to spawn grenade
SWEP.MaxHoldTime = 5.0 -- seconds before grenade explodes in hand

SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Grenade_body"] = { scale = Vector(0.01, 0.01, 0.01), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

-- VIEWMODEL
SWEP.VElements = {
	["v_projectile_sprite"] = { type = "Sprite", sprite = "sprites/glow01", bone = "ValveBiped.Grenade_body", rel = "v_projectile", pos = Vector(-0.431, 0.061, -2.652), size = { x = 1.743, y = 1.743 }, color = Color(255, 127, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["v_projectile"] = { type = "Model", model = SWEP.GrenadeModel, bone = "ValveBiped.Grenade_body", rel = "", pos = Vector(0, 0, 0), angle = Angle(0, 0, 0), size = Vector(1.25, 1.25, 1.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

-- WORLD MODEL
SWEP.WElements = {
	["w_projectile"] = { type = "Model", model = SWEP.GrenadeModel, bone = "ValveBiped.Anim_Attachment_RH", rel = "", pos = Vector(1.524, -0.355, 0.063), angle = Angle(0, 0, 0), size = Vector(1.25, 1.25, 1.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

function SWEP:Initialize()

	self:SetHoldType(self.HoldType)
	self.Charging = false
	self.ChargeStart = 0

	if CLIENT then
	
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

function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:Deploy()
	-- Ensure we have a grenade ready when weapon is deployed
	self:CheckAutoReload()
	return true
end

function SWEP:CanPrimaryAttack()
	if self:GetOwner():IsPlayer() and self:GetOwner():Alive() then
		return self:Clip1() > 0 and CurTime() >= self:GetNextPrimaryFire()
	end
	return false
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	if not IsFirstTimePredicted() then return end

	if not self.Charging then
		-- Start charging throw force
		self.Charging = true
		self.ChargeStart = CurTime()

		-- Play pull pin animation
		self:SendWeaponAnim(ACT_VM_PULLPIN)
	end
end

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	-- Handle throw force charging
	if self.Charging then
		local holdTime = CurTime() - self.ChargeStart

		-- Check if player released the button
		if not owner:KeyDown(IN_ATTACK) then
			-- Released, throw grenade with calculated force
			local chargeTime = CurTime() - self.ChargeStart
			local throwForce = self:GetThrowForce(chargeTime)

			self:ThrowGrenade(throwForce)
			self.Charging = false
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

			-- Auto-reload next grenade after a short delay
			timer.Simple(0.5, function()
				if IsValid(self) and IsValid(owner) then
					self:CheckAutoReload()
				end
			end)
		elseif holdTime >= self.MaxHoldTime then
			-- Held too long, explode in hand
			self:ExplodeInHand()
			self.Charging = false
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

			-- Auto-reload next grenade after explosion
			timer.Simple(0.5, function()
				if IsValid(self) and IsValid(owner) then
					self:CheckAutoReload()
				end
			end)
		end
	end
end

-- Calculate throw force based on charge time
function SWEP:GetThrowForce(chargeTime)
	local fraction = math.Clamp(chargeTime / self.ThrowChargeTime, 0, 1)
	return Lerp(fraction, self.MinThrowForce, self.MaxThrowForce)
end

-- Get current charge fraction for HUD (0 to 1)
function SWEP:GetChargeFraction()
	if not self.Charging then return 0 end
	local chargeTime = CurTime() - self.ChargeStart
	return math.Clamp(chargeTime / self.ThrowChargeTime, 0, 1)
end

function SWEP:ThrowGrenade(throwForce)
	if SERVER then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		throwForce = throwForce or self.MaxThrowForce

		-- Calculate throw position and direction
		local shootPos = owner:GetShootPos()
		local eyeAngles = owner:EyeAngles()
		local forward = eyeAngles:Forward()
		local right = eyeAngles:Right()
		local up = eyeAngles:Up()

		-- Create grenade position with offset
		local grenadePos = shootPos + forward * self.ThrowOffset.x +
		                  right * self.ThrowOffset.y +
		                  up * self.ThrowOffset.z

		-- Calculate throw velocity using the charged throw force
		local throwVel = forward * throwForce + owner:GetVelocity()

		-- Create grenade entity using new base system
		local grenade = self:CreateGrenadeEntity(grenadePos, eyeAngles, throwVel)

		-- The grenade entity now handles its own timing and explosion
	end

	-- Play throw animation and sound
	self:SendWeaponAnim(ACT_VM_THROW)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:EmitSound(self.Primary.Sound)

	-- Take ammo
	self:TakePrimaryAmmo(1)
end

function SWEP:CreateGrenadeEntity(pos, angles, velocity)
	if not SERVER then return end
	
	-- Use the new ZDEV grenade base system
	local grenade = ents.Create( self.GrenadeClass )
	if not IsValid(grenade) then return nil end
	
	-- Set up the grenade entity
	grenade:SetPos(pos)
	grenade:SetAngles(angles)
	grenade:SetOwner(self:GetOwner())
	grenade:Spawn()
	grenade:Activate()
	
	-- Apply throw velocity
	local phys = grenade:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(velocity)
		phys:AddAngleVelocity(VectorRand() * 300)
	end
	
	-- Notify the grenade it was thrown
	grenade:OnGrenadeThrown(self:GetOwner(), velocity)
	
	return grenade
end

function SWEP:ExplodeInHand()
	if SERVER then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		-- Create explosion effect at player position
		local effectdata = EffectData()
		effectdata:SetOrigin(owner:GetPos())
		util.Effect("Explosion", effectdata, true, true)

		-- Damage the player
		local dmg = DamageInfo()
		dmg:SetDamage(self.BlastDamage or 120)
		dmg:SetAttacker(owner)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_BLAST)
		dmg:SetDamagePosition(owner:GetPos())
		owner:TakeDamageInfo(dmg)

		if ZDEV and ZDEV.LOG then
			zdev.log('W', 'Player ' .. owner:Nick() .. ' held grenade too long and it exploded!')
		end
	end

	-- Play explosion sound
	self:EmitSound("weapons/explode3.wav", 100, 100)

	-- Take ammo
	self:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack()
	-- Secondary attack does nothing for now
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end

function SWEP:Reload()
	-- Manual reload is disabled for grenades
	-- Auto-reload happens automatically after throwing
	return false
end

function SWEP:CheckAutoReload()
	-- Auto-reload next grenade from reserve ammo
	if self:Clip1() < 1 then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local ammoType = self:GetPrimaryAmmoType()
		local reserveAmmo = owner:GetAmmoCount(ammoType)

		if reserveAmmo > 0 then
			-- Take 1 from reserve and put it in clip
			owner:RemoveAmmo(1, ammoType)
			self:SetClip1(1)

			-- Play draw animation to show new grenade
			self:SendWeaponAnim(ACT_VM_DRAW)

			if ZDEV and ZDEV.LOG then
				zdev.log('N', 'Auto-reloaded grenade from reserve (' .. reserveAmmo - 1 .. ' remaining)')
			end
		else
			-- No more grenades, switch to another weapon
			if SERVER then
				timer.Simple(0.1, function()
					if IsValid(owner) and IsValid(self) then
						owner:SwitchToNextWeapon(self)
					end
				end)
			end
		end
	end
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetPrintName()
	return self.PrintName
end

-- Prediction setup
function SWEP:SetupDataTables()
	-- Add any networked variables here if needed
end