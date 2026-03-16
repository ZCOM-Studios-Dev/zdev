if !ZDEV then return end

AddCSLuaFile()

SWEP.Base         				 = "weapon_base"
SWEP.PrintName    			 	 = "'Spectre' Laser Rifle"
SWEP.Author       				 = "Adrian 'ZCOM' L."
SWEP.Instructions = [[Primary Attack - Fires a single laser pulse for 2-5% battery power which can be fired in rapid succession.
Seconday Attack (Hold) - Charges a long-range pulse emission that lasts a few seconds to discharge fully. Consumes 25-35% battery power to fire and requires 3 seconds to fire again.]]
SWEP.Category    				 = "ZDEV Weapons: Rifles"

SWEP.HoldType      				 = "ar2"
SWEP.Slot          				 = 1
SWEP.SlotPos       				 = 0
SWEP.Weight        				 = 5
SWEP.AutoSwitchTo  				 = true
SWEP.AutoSwitchFrom				 = false

SWEP.Spawnable     				 = true
SWEP.AdminSpawnable				 = true

SWEP.ViewModelFlip 				 = true
SWEP.UseHands      				 = true
SWEP.DrawCrosshair 				 = true
SWEP.ViewModelFOV				 = 44.422110552764
SWEP.ViewModelFlip				 = false
SWEP.ViewModel 					 = "models/weapons/v_irifle.mdl"
SWEP.WorldModel 				 = "models/weapons/w_irifle.mdl"
SWEP.ShowViewModel 				 = false
SWEP.ShowWorldModel 			 = true
SWEP.ViewModelBoneMods 			= {
	["Shell2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Vent"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Base"] = { scale = Vector(0.112, 0.112, 0.112), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Claw1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Shell1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Reload1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Bolt2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Reload"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Bolt1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["Claw2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
SWEP.Primary.Delay       		= 0.08
SWEP.Primary.Recoil      		= 1.9
SWEP.Primary.Automatic   		= false
SWEP.Primary.Cone       		= 0.025
SWEP.Primary.Ammo       		= "battery"
SWEP.Primary.ClipSize   		= 100
SWEP.Primary.ClipMax    		= 100
SWEP.Primary.DefaultClip		= 100
SWEP.Primary.Sound      		= Sound("Weapon_AK47.Single")

SWEP.Secondary.Delay       		= 1
SWEP.Secondary.Delay			= 1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Recoil			= 4.9
SWEP.Secondary.Cone				= 0.013
SWEP.Secondary.Ammo				= "battery"
SWEP.Secondary.ClipSize			= 100
SWEP.Secondary.ClipMax			= 100
SWEP.Secondary.DefaultClip		= 100
SWEP.Secondary.Sound			= Sound("Weapon_SLAM.SatchelThrow");

SWEP.AmmoEnt 					= "item_battery"

SWEP.BoxAttachment				 = "muzzle"
SWEP.BoxMins					 = Vector(-2, -2, -2)
SWEP.BoxMaxs					 = Vector(2, 2, 2)
SWEP.BoxColor					 = Color(0, 255, 0)
SWEP.Attachments				 = {}
SWEP.Attachments.muzzle			 = {}

MUZZLE_POS				 		 = Vector(0, 0, 0)
MUZZLE_ANG				 		 = Angle(0, 0, 0)

SWEP.VElements = {
	["muzzle+"] = { type = "Model", model = "models/props_combine/combine_barricade_med01b.mdl", bone = "Base", rel = "", pos = Vector(0.601, -1.308, 16.488), angle = Angle(0, 0, 0), size = Vector(0.025, 0.025, 0.025), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_05"] = { type = "Model", model = "models/gibs/helicopter_brokenpiece_01.mdl", bone = "Base", rel = "", pos = Vector(1.167, -2.345, -1.575), angle = Angle(123.591, -41.922, -63.834), size = Vector(0.054, 0.054, 0.054), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.112, -2.472), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03++++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, -0.489), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_04"] = { type = "Model", model = "models/gibs/helicopter_brokenpiece_03.mdl", bone = "Base", rel = "", pos = Vector(0.449, -1.742, 14.84), angle = Angle(-87.824, 91.268, -47.284), size = Vector(0.237, 0.075, 0.093), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03+++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, -1.16), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03+"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, -3.659), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_02"] = { type = "Model", model = "models/combine_apc_destroyed_gib03.mdl", bone = "Base", rel = "", pos = Vector(0.4, 0.402, 4.039), angle = Angle(0, 0, -80.099), size = Vector(0.03, 0.03, 0.03), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, -1.826), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["muzzle+++"] = { type = "Model", model = "models/props_combine/combine_barricade_med01b.mdl", bone = "Base", rel = "", pos = Vector(0.589, -1.316, 10.668), angle = Angle(0, 0, 0), size = Vector(0.025, 0.025, 0.025), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Pipe"] = { type = "Model", model = "models/props_pipes/pipeset08d_256_001a.mdl", bone = "Base", rel = "", pos = Vector(0.652, -2.393, 4.597), angle = Angle(90, 90, -141.764), size = Vector(0.041, 0.041, 0.041), color = Color(85, 128, 185, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03++++++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, 0.976), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03+++++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, 0.189), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Cable++"] = { type = "Model", model = "models/props_pipes/pipeset08d_128_001a.mdl", bone = "Base", rel = "", pos = Vector(1.08, -1.754, 2.915), angle = Angle(90.167, 87.274, 1.524), size = Vector(0.054, 0.054, 0.035), color = Color(94, 137, 219, 255), surpresslightning = false, material = "metal/citadel_metalwall101a", skin = 0, bodygroup = {} },
	["muzzle"] = { type = "Model", model = "models/mechanics/solid_steel/box_beam_8.mdl", bone = "Base", rel = "", pos = Vector(0.428, -2.151, 8.763), angle = Angle(0, 0, 90), size = Vector(0.05, 0.207, 0.079), color = Color(0, 0, 0, 255), surpresslightning = false, material = "metal/citadel_metalwall076a", skin = 0, bodygroup = {} },
	["Pipe++"] = { type = "Model", model = "models/props_pipes/pipe02_straight01_short.mdl", bone = "Base", rel = "", pos = Vector(0.6, -0.473, 5.703), angle = Angle(0, 180, 90), size = Vector(0.019, 0.212, 0.019), color = Color(67, 84, 94, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Cable"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(0.456, -0.955, 8.793), angle = Angle(180, 0, 0), size = Vector(0.108, 0.108, 0.108), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Screen_glass"] = { type = "Model", model = "models/props_phx/construct/glass/glass_plate1x1.mdl", bone = "Base", rel = "", pos = Vector(1.633, -2.625, 1.815), angle = Angle(0, 0, 0), size = Vector(0.017, 0.017, 0.017), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_01"] = { type = "Model", model = "models/combine_apc_destroyed_gib05.mdl", bone = "Base", rel = "", pos = Vector(-1.395, 0.012, -0.389), angle = Angle(-93.807, 32.493, 52.179), size = Vector(0.028, 0.028, 0.028), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["mdl_panel_03+++++++"] = { type = "Model", model = "models/container_chunk01.mdl", bone = "Bolt1", rel = "", pos = Vector(0.794, -2.102, -3.082), angle = Angle(90, 180, 180), size = Vector(0.014, 0.014, 0.014), color = Color(118, 142, 161, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["muzzle++"] = { type = "Model", model = "models/props_combine/combine_barricade_med01b.mdl", bone = "Base", rel = "", pos = Vector(0.592, -1.486, 6.908), angle = Angle(0, 0, 0), size = Vector(0.025, 0.025, 0.025), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Cable+"] = { type = "Model", model = "models/props_combine/pipes03_single02c.mdl", bone = "Base", rel = "", pos = Vector(0.87, 1.656, 8.062), angle = Angle(180, 0, 0), size = Vector(0.009, 0.009, 0.009), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["muzzle++++"] = { type = "Model", model = "models/props_combine/combine_barricade_med01b.mdl", bone = "Base", rel = "", pos = Vector(0.601, -1.308, 13.605), angle = Angle(0, 0, 0), size = Vector(0.025, 0.025, 0.025), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Pipe+"] = { type = "Model", model = "models/props_pipes/pipe02_straight01_short.mdl", bone = "Base", rel = "", pos = Vector(0.316, -2.78, 19.837), angle = Angle(0, 0, 90), size = Vector(0.056, 0.37, 0.056), color = Color(34, 60, 90, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Screen_glass+"] = { type = "Model", model = "models/props_phx/construct/metal_wire2x2b.mdl", bone = "Base", rel = "", pos = Vector(1.633, -2.625, 1.815), angle = Angle(0, 0, 0), size = Vector(0.009, 0.009, 0.009), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Screen_ammo_quad"] = { type = "Quad", bone = "Base", rel = "Screen_glass", pos = Vector(0.1, -0.09, -0.25), angle = Angle(0, 0, 0), size = 0.01, draw_func = function(self)

		_AMMO = _AMMO or 0;

		--DrawGrid( 1, 1, 5, 5, 150, 150, Color(255,255,255,0.5), Color(255,0,0,1) )

		surface.SetDrawColor(0, 255, 0, 255)
		surface.DrawOutlinedRect( -50, -50, 100, 100, 1 )
		--ZDEV.DRAW.Circle( 0, 0, 50, 55, 0, 360, 16, Color(255, 0, 0, 255), Color(255, 255, 0, 255) )
		--ZDEV.DRAW.OutlinedBox( -1, -1, 2, 2, 0.1, Color(0, 255, 0, 255) )
		-- function ZDEV.DRAW.Circle(x,y,r,r2,startang,endang,iter,col,col2)
		--ZDEV.DRAW.DottedCircle( -0.5, -0.5, 0.5, 0.5, 0.5, 16, Color(255,150,0,255) )
		surface.SetDrawColor(50, 175, 255, math.Rand(0.55, 1))
		surface.DrawRect(-0.5, -0.5, 0.5, 0.5)
		-- Draw grid code here

	


		local Dw = 10
		local Dh = 10
		local x = -50
		local y = -50
		local w = 5
		local h = 5
		local x_step = w
		local y_step = h
		local line_color = Color(255, 255, 255, 255)
		local vertex_color = Color(255, 0, 0, 255)
		for i = 0, Dw do

			for j = 0, tonumber(Dh) do
				local x_pos = x + (i * x_step)
				local y_pos = y + (j * y_step)
				-- Draw line
				surface.SetDrawColor(line_color.r, line_color.g, line_color.b, 2)
				surface.DrawLine(x_pos, y, x_pos, y + (Dh * y_step))
				surface.DrawLine(x, y_pos, x + (Dw * x_step), y_pos)
				-- Draw vertex
				--surface.SetDrawColor(vertex_color)
				--surface.DrawRect(x_pos + (Dw * x_step), y_pos, w/5, h/2)
			end
		end
	


		for i = 1,  _AMMO do

			draw.DrawText( i, "ConsoleText", -50, -50 + (i * 2), Color(0, 255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			surface.SetDrawColor( 0, 255, 255, 150 )
			draw.RoundedBox( 0, 0, -50 + (i * 2), 10, 1, Color(0, 255, 255, 150) )
		end
		--draw.RoundedBox(0,-0.5, -0.5, 2, 1, Color(0, 255, 0, 50))
		--draw.DrawText("Ammo", "DermaDefault", 0, 0, Color(0, 200, 255, 255), TEXT_ALIGN_CENTER)

		--ZDEV.DRAW.TexturedRect( 1, 1, 1, 1, Material("hud/panel/pnl_1_1.png"), Color(255, 255, 255, 255) )	
		--ZDEV.DRAW.MaterialBox( 1, 1, 1, 1, Material("hud/panel/pnl_1_1.png"), Color(255, 255, 255, 255) )
	end}
}


local function DrawGrid( x, y, w, h, Dw, DH, line_color, vertex_color )

	local x_step = w
	local y_step = h
	for i = 0, Dw do

		for j = 0, tonumber(Dh) do
			local x_pos = x + (i * x_step)
			local y_pos = y + (j * y_step)
			-- Draw line
			surface.SetDrawColor(line_color.r, line_color.g, line_color.b)
			surface.DrawLine(x_pos, y, x_pos, y + (Dh * y_step))
			surface.DrawLine(x, y_pos, x + (Dw * x_step), y_pos)
			-- Draw vertex
			surface.SetDrawColor(vertex_color)
			surface.DrawRect(x_pos, y_pos, w, h)
		end
	end
 
 

end

local _AMMO = _AMMO or 0;


--[[*******************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
*******************************************************]]
function SWEP:ToggleAimLaser( force_state )

	if ( force_state ~= nil ) then
		self.AimLaser.State = force_state
	else
		self.AimLaser.State = !self.AimLaser.State
	end

	return self.AimLaser.State
end




--[[=======================================================
	-- FUNC SWEP:Initialize()
========================================================]]
function SWEP:Initialize()

	self:SetHoldType( self.HoldType )
	-- other initialize code goes here

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

--[[=======================================================
	-- FUNC SWEP:Deploy()
========================================================]]
function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

--[[=======================================================
	-- FUNC SWEP:OnRemove()	
========================================================]]
function SWEP:OnRemove()
	self:Holster()
end



--[[=======================================================
	-- FUNC SWEP:PrimaryAttack()
========================================================]]
function SWEP:PrimaryAttack()

	local ply = self:GetOwner()
	local pos1 = MUZZLE_POS
	local pos2 = ply:GetEyeTrace().HitPos

	self.ViewModelEntity = self.Owner:GetViewModel();
	self.Attachments = self:GetAttachments();
	local obj = self:LookupAttachment("muzzle")

	if (obj <= 1) then
		local muzzle = self.ViewModelEntity:GetAttachment(obj)
	end

	local effectdata_tracer = EffectData()
	effectdata_tracer:SetOrigin( pos2 )
	effectdata_tracer:SetAngles( ply:EyeAngles() )
	effectdata_tracer:SetScale( 10 )
	effectdata_tracer:SetAttachment( obj )
	effectdata_tracer:SetStart( ply:GetShootPos() )
	effectdata_tracer:SetColor( 3 )
	effectdata_tracer:SetEntity( self )
	util.Effect( "zdev_fx_tracer_laser", effectdata_tracer )

    -- Checks if we have enough ammo to shoot
    if (self:CanPrimaryAttack() == false) then return end

    -- weapon_base: SWEP:ShootBullet(damage, numberOfBullets, aimcone, ammoType, force, tracer)
    -- Shoots a bullet, handles player/weapon animations & applies recoil
    --self:ShootBullet(self.Primary.Damage,1,self.Primary.Cone,self.Primary.Ammo)

    self:TakePrimaryAmmo(1)

	_AMMO = self:Clip1();

    --self:EmitSound(self.Primary.Sound)

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		
end

--[[=======================================================
	-- FUNC SWEP:SecondaryAttack()
========================================================]]
function SWEP:SecondaryAttack()
	if(!self:CanSecondaryAttack()) then return end

	if SERVER then
			self:GetOwner():ChatPrint("Right click!")
	end

	-- Delay when the gun can next be fired (secondary attack)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
end

--[[=======================================================
	-- FUNC SWEP:Reload()
========================================================]]
local b_ReloadDoOnce = b_ReloadDoOnce or false;
SWEP.ReloadDelay = 1.5;
SWEP.NextReload = SWEP.NextReload or 0;
function SWEP:Reload()

	if ( self.NextReload > CurTime() ) then return end

	-- Put code here that you want to run every frame
	if self.Owner:KeyDown( IN_USE ) then
		self:ToggleAimLaser()
		zdev.log( "D", "Toggled Aim Laser: " .. tostring( self.AimLaser.State ) )
		self:EmitSound( "weapons/ar2/ar2_reload.wav" );
	end

	self.NextReload = CurTime() + self.ReloadDelay;

end

function SWEP:Think()

end

-- SECTION CLIENT
if CLIENT then
	
	SWEP.Effects = {
		AimLaser = {
			Mat = Material( "effects/laser_line2" ),
			Color = Color( 255, 255, 255, 255 ),
			Width = 3
		},
		AimSprite = {
			Mat = Material( "effects/redflare" ),
			Color = Color( 255, 255, 255, 255 ),
			Size = 6
		}
	}

	--[[---------------------------------------------------------
		Returns the right shoot start position for a tracer - based on 'data'.
	-----------------------------------------------------------]]
	function SWEP:GetTracerShootPos( Position, Ent, Attachment )

		if ( !IsValid( Ent ) ) then return Position end
		if ( !Ent:IsWeapon() ) then return Position end

		-- Shoot from the viewmodel
		if ( Ent:IsCarriedByLocalPlayer() and !LocalPlayer():ShouldDrawLocalPlayer() ) then

			local ViewModel = LocalPlayer():GetViewModel()

			if ( ViewModel:IsValid() ) then

				local att = ViewModel:GetAttachment( Attachment )
				if ( att ) then
					Position = att.Pos
					self.ViewModelTracer = true
				end

			end

		-- Shoot from the world model
		else

			local att = Ent:GetAttachment( Attachment )
			if ( att ) then
				Position = att.Pos
			end

		end

		return Position

	end

	function SWEP:PostDrawViewModel( vm, weapon, ply )

		--Msg( tostring( LocalPlayer() == ply ) .. "\n" );

		if ( self.AimLaser.State ) then

			if ( !IsValid( ply ) ) then return end
			if ( !IsValid( vm ) ) then return end
			if ( !IsValid( weapon ) ) then return end

			local startPos = LocalPlayer():GetShootPos()
			local endPos = ply:GetEyeTrace().HitPos
			local endNormal = ply:GetEyeTrace().HitNormal

			if ( weapon:IsCarriedByLocalPlayer() and !ply:ShouldDrawLocalPlayer() ) then

				if ( IsValid( vm ) ) then
					local att = vm:GetAttachment( vm:LookupAttachment( "muzzle" ) )
					if ( att ) then
						startPos = att.Pos
					end
				end
			else
				
				local att = weapon:GetAttachment( weapon:LookupAttachment( "muzzle" ) )
				if ( att ) then
					startPos = att.Pos
				end

			end

			render.SetMaterial( self.Effects.AimSprite.Mat )
			render.DrawQuadEasy( endPos, endNormal, self.Effects.AimSprite.Size, self.Effects.AimSprite.Size, self.Effects.AimSprite.Color )

			render.SetMaterial( self.Effects.AimLaser.Mat )
			render.DrawBeam( startPos, endPos, self.Effects.AimLaser.Width, 0, 1, self.Effects.AimLaser.Color )

		end

	end


	-- ========================================================
	--	FUNC DrawHUD()
	--========================================================
	function SWEP:DrawHUD()

		local ply = ply or LocalPlayer()
		local wep = self.Entity

	end


	-- ========================================================
	--	FUNC FormatViewModelAttachment()
	--========================================================
	-- FIXME: The nFOV parameter should be replaced with ViewModelFOV() when it's binded
	local function FormatViewModelAttachment(nFOV, vOrigin, bFrom --[[= false]])
		local vEyePos = EyePos()
		local aEyesRot = EyeAngles()
		local vOffset = vOrigin - vEyePos
		local vForward = aEyesRot:Forward()

		local nViewX = math.tan(nFOV * math.pi / 360)

		if (nViewX == 0) then
			vForward:Mul(vForward:Dot(vOffset))
			vEyePos:Add(vForward)
			
			return vEyePos
		end

		-- FIXME: LocalPlayer():GetFOV() should be replaced with EyeFOV() when it's binded
		local nWorldX = math.tan(LocalPlayer():GetFOV() * math.pi / 360)

		if (nWorldX == 0) then
			vForward:Mul(vForward:Dot(vOffset))
			vEyePos:Add(vForward)
			
			return vEyePos
		end

		local vRight = aEyesRot:Right()
		local vUp = aEyesRot:Up()

		if (bFrom) then
			local nFactor = nWorldX / nViewX
			vRight:Mul(vRight:Dot(vOffset) * nFactor)
			vUp:Mul(vUp:Dot(vOffset) * nFactor)
		else
			local nFactor = nViewX / nWorldX
			vRight:Mul(vRight:Dot(vOffset) * nFactor)
			vUp:Mul(vUp:Dot(vOffset) * nFactor)
		end

		vForward:Mul(vForward:Dot(vOffset))

		vEyePos:Add(vRight)
		vEyePos:Add(vUp)
		vEyePos:Add(vForward)

		return vEyePos
	end

	SWEP.vRenderOrder = nil
	--[[=======================================================
		-- FUNC SWEP:ViewModelDrawn()
	========================================================]]
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
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) ~= v) then
							model:SetBodygroup(k, v)
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


		local pOwner = self:GetOwner()
		if (not pOwner:IsValid()) then return end
	
		local pViewModel = pOwner:GetViewModel()
		if (not pViewModel:IsValid()) then return end
	
		local uAttachment = pViewModel:LookupAttachment(self.BoxAttachment)
		if (uAttachment < 1) then return end
	
		local tAttachment = pViewModel:GetAttachment(uAttachment)
		if (tAttachment == nil) then return end
	
		-- FIXME: This should be removed when ViewModelFOV() is binded
		local nFOV = self.ViewModelFOV
		if (not isnumber(nFOV)) then nFOV = 62 end
	
		MUZZLE_POS = tAttachment.Pos
		MUZZLE_POS = MUZZLE_POS + tAttachment.Ang:Forward() * 2000
		MUZZLE_POS = FormatViewModelAttachment(nFOV, MUZZLE_POS, false)
		MUZZLE_ANG = tAttachment.Ang
		MUZZLE_ANG:RotateAroundAxis(MUZZLE_ANG:Right(), 90)
		MUZZLE_ANG:RotateAroundAxis(MUZZLE_ANG:Up(), 0)
		
		--ui3d2d.drawVgui(vgui.Create("DFrame"), EyePos(), EyeAngles(), 2, LocalPlayer())


		render.DrawWireframeBox(FormatViewModelAttachment(nFOV, tAttachment.Pos, false), tAttachment.Ang, self.BoxMins, self.BoxMaxs, self.BoxColor, true)
	end

	SWEP.wRenderOrder = nil
	--[[=======================================================
		-- FUNC SWEP:DrawWorldModel()
	========================================================]]
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
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) ~= v) then
							model:SetBodygroup(k, v)
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

	--[[=======================================================
		-- FUNC SWEP:GetBoneOrientation()
	========================================================]]
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

	--[[=======================================================
		-- FUNC SWEP:CreateModels()
	========================================================]]
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
	--[[=======================================================
		-- FUNC SWEP:UpdateBonePositions()
	========================================================]]
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
	 
	--[[=======================================================
		-- FUNC SWEP:ResetBonePositions()
	========================================================]]
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

	-- !SECTION CLIENT
end


