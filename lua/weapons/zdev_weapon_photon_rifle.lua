if !ZDEV then MsgC( Color(255,50,50,255), "[ZDEV] photon_rifle loaded before ZDEV namespace\n" ) end

AddCSLuaFile()

SWEP.Base        				 = "weapon_base"
SWEP.PrintName   				 = "Photon Rifle"
SWEP.Author      				 = "ZCOM Studios"
SWEP.Instructions				 = "Primary Attack - Fires a single laser pulse for 2-5% battery power which can be fired in rapid succession.\nSecondary Attack (Hold) - Charges a long-range pulse emission that lasts a few seconds to discharge fully. Consumes 25-35% battery power to fire and requires 3 seconds to fire again."
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
SWEP.UseHands      				 = false
SWEP.DrawCrosshair 				 = true
SWEP.ViewModelFOV				 = 44.422110552764
SWEP.ViewModelFlip				 = false
SWEP.ViewModel					 = "models/weapons/v_irifle.mdl"
SWEP.WorldModel				 	 = "models/weapons/w_irifle.mdl"
SWEP.ShowViewModel				 = false
SWEP.ShowWorldModel				 = false
SWEP.ViewModelBoneMods			 = {}

SWEP.Primary.Delay      		 = 0.08
SWEP.Primary.Recoil     		 = 1.9
SWEP.Primary.Automatic  		 = false
SWEP.Primary.Damage     		 = 20
SWEP.Primary.Cone       		 = 0.025
SWEP.Primary.Ammo       		 = "None"
SWEP.Primary.ClipSize   		 = -1
SWEP.Primary.ClipMax    		 = -1
SWEP.Primary.DefaultClip		 = -1
SWEP.Primary.Sound      		 = Sound("Weapon_AK47.Single")

SWEP.Secondary.Delay      		 = 1

SWEP.AmmoEnt				 	 = "item_battery"


SWEP.BoxAttachment				 = "muzzle"
SWEP.BoxMins					 = Vector(-2, -2, -2)
SWEP.BoxMaxs					 = Vector(2, 2, 2)
SWEP.BoxColor					 = Color(0, 255, 0)
SWEP.Attachments				 = {}
SWEP.Attachments.muzzle			 = {}

MUZZLE_POS				 		 = Vector(0, 0, 0)
MUZZLE_ANG				 		 = Angle(0, 0, 0)

SWEP.VElements				 	 = {}
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

--[[=======================================================
	-- FUNC SWEP:Initialize()
========================================================]]
function SWEP:Initialize()

	self:SetHoldType( self.HoldType )

	-- other initialize code goes here

	if CLIENT then
	
		-- Create a new table for every weapon instance
		self.VElements				 = table.FullCopy( self.VElements )
		self.WElements				 = table.FullCopy( self.WElements )
		self.ViewModelBoneMods				 = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels

		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm				 = self.Owner:GetViewModel()
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
	-- FUNC SWEP:Holster()
========================================================]]
function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm				 = self.Owner:GetViewModel()
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
	-- FUNC SWEP:Deploy()
========================================================]]
function SWEP:Deploy()

end

--[[=======================================================
	-- FUNC SWEP:PrimaryAttack()
========================================================]]

-- Define the primary attack function
function SWEP:PrimaryAttack()

	-- Check if the player is holding down the primary attack key
	if not self:CanPrimaryAttack() then return end
 
	-- Play the shoot sound (replace this with your actual sound)
	self:EmitSound("Weapon_Crossbow.Single")

	-- Calculate the force based on how long the player held down the primary attack key
	local force = 500 + math.Clamp(self:GetNextPrimaryFire() - CurTime(), 0, 3) * 1000

	-- Spawn the grappling hook prop
	local hook = ents.Create("prop_physics")
	hook:SetModel("models/props_c17/oildrum001.mdl") -- Replace with your grappling hook model
	hook:SetPos(self.Owner:GetShootPos())
	hook:SetAngles(self.Owner:EyeAngles())
	hook:Spawn()

	-- Apply force to the grappling hook prop
	local phys				 = hook:GetPhysicsObject()
	if IsValid(phys) then
			phys:SetVelocity(self.Owner:GetAimVector() * force)
	end

	-- Store grappling hook data
	self.Grapple.Hook				 = hook
	self.Grapple.StartPos				 = self.Owner:GetShootPos()

	-- Set the next primary attack time
	self:SetNextPrimaryFire(CurTime() + 1)
end


--[[=======================================================
	-- FUNC SWEP:Think()
========================================================]]
-- Think function to handle rope rendering
function SWEP:Think()
	-- Check if the grappling hook data exists
	if self.Grapple and IsValid(self.Grapple.Hook) then
			-- Render the rope
			local startPos				 = self.Grapple.StartPos
			local endPos				 = self.Grapple.Hook:GetPos()

			if SERVER then
					-- Update the rope position on the server
					umsg.Start("UpdateGrapplingHook", self.Owner)
					umsg.Vector(startPos)
					umsg.Vector(endPos)
					umsg.End()
			elseif CLIENT then
					-- Render the rope on the client
					render.SetMaterial(Material("cable/cable"))
					render.DrawBeam(startPos, endPos, 2, 0, 12.5, Color(255, 255, 255, 255))
			end
	end
end


--[[=======================================================
	-- FUNC SWEP:SecondaryAttack()
========================================================]]
-- Define the secondary attack function
function SWEP:SecondaryAttack()
	-- Check if the grappling hook data exists
	if self.Grapple then
			-- Remove the grappling hook prop
			if IsValid(self.Grapple.Hook) then
					self.Grapple.Hook:Remove()
			end

			-- Reset grappling hook data
			self.Grapple				 = nil

			-- Stop rendering the rope
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

			-- Set the next secondary attack time
			self:SetNextSecondaryFire(CurTime() + 1)
	end
end


-- SECTION CLIENT
if CLIENT then

	function SWEP:DrawHUD()

		local ply				 = ply or LocalPlayer()
		local wep				 = self.Entity

	end


	-- ========================================================
	--	FUNC FormatViewModelAttachment()
	--========================================================
	-- FIXME: The nFOV parameter should be replaced with ViewModelFOV() when it's binded
	local function FormatViewModelAttachment(nFOV, vOrigin, bFrom --[[= false]])
		local vEyePos				 = EyePos()
		local aEyesRot				 = EyeAngles()
		local vOffset				 = vOrigin - vEyePos
		local vForward				 = aEyesRot:Forward()

		local nViewX				 = math.tan(nFOV * math.pi / 360)

		if (nViewX == 0) then
			vForward:Mul(vForward:Dot(vOffset))
			vEyePos:Add(vForward)
			
			return vEyePos
		end

		-- FIXME: LocalPlayer():GetFOV() should be replaced with EyeFOV() when it's binded
		local nWorldX				 = math.tan(LocalPlayer():GetFOV() * math.pi / 360)

		if (nWorldX == 0) then
			vForward:Mul(vForward:Dot(vOffset))
			vEyePos:Add(vForward)
			
			return vEyePos
		end

		local vRight				 = aEyesRot:Right()
		local vUp				 = aEyesRot:Up()

		if (bFrom) then
			local nFactor				 = nWorldX / nViewX
			vRight:Mul(vRight:Dot(vOffset) * nFactor)
			vUp:Mul(vUp:Dot(vOffset) * nFactor)
		else
			local nFactor				 = nViewX / nWorldX
			vRight:Mul(vRight:Dot(vOffset) * nFactor)
			vUp:Mul(vUp:Dot(vOffset) * nFactor)
		end

		vForward:Mul(vForward:Dot(vOffset))

		vEyePos:Add(vRight)
		vEyePos:Add(vUp)
		vEyePos:Add(vForward)

		return vEyePos
	end

	SWEP.vRenderOrder				 = nil
	--[[=======================================================
		-- FUNC SWEP:ViewModelDrawn()
	========================================================]]
	function SWEP:ViewModelDrawn()

		local vm				 = self.Owner:GetViewModel()
		if !IsValid(vm) then return end

		if (!self.VElements) then return end

		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then

			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder				 = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end

		end

		for k, name in ipairs( self.vRenderOrder ) do

			local v				 = self.VElements[name]
			if (!v) then self.vRenderOrder				 = nil break end
			if (v.hide) then continue end

			local model				 = v.modelEnt
			local sprite				 = v.spriteMaterial

			if (!v.bone) then continue end

			local pos, ang				 = self:GetBoneOrientation( self.VElements, v, vm )

			if (!pos) then continue end

			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix				 = Matrix()
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

				local drawpos				 = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

			elseif (v.type == "Quad" and v.draw_func) then

				local drawpos				 = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end

		end


		local pOwner				 = self:GetOwner()
		if (not pOwner:IsValid()) then return end
	
		local pViewModel				 = pOwner:GetViewModel()
		if (not pViewModel:IsValid()) then return end
	
		local uAttachment				 = pViewModel:LookupAttachment(self.BoxAttachment)
		if (uAttachment < 1) then return end
	
		local tAttachment				 = pViewModel:GetAttachment(uAttachment)
		if (tAttachment == nil) then return end
	
		-- FIXME: This should be removed when ViewModelFOV() is binded
		local nFOV				 = self.ViewModelFOV
		if (not isnumber(nFOV)) then nFOV				 = 62 end
	
		MUZZLE_POS				 = tAttachment.Pos
		MUZZLE_ANG				 = tAttachment.Ang
	
		render.DrawWireframeBox(FormatViewModelAttachment(nFOV, tAttachment.Pos, false), tAttachment.Ang, self.BoxMins, self.BoxMaxs, self.BoxColor, true)
	end

	SWEP.wRenderOrder				 = nil
	--[[=======================================================
		-- FUNC SWEP:DrawWorldModel()
	========================================================]]
	function SWEP:DrawWorldModel()

		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end

		if (!self.WElements) then return end

		if (!self.wRenderOrder) then

			self.wRenderOrder				 = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end

		if (IsValid(self.Owner)) then
			bone_ent				 = self.Owner
		else
			-- when the weapon is dropped
			bone_ent				 = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v				 = self.WElements[name]
			if (!v) then self.wRenderOrder				 = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang				 = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang				 = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model				 = v.modelEnt
			local sprite				 = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix				 = Matrix()
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
				
				local drawpos				 = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos				 = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
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
			
			local v				 = basetab[tab.rel]
			
			if (!v) then return end
			
			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang				 = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos				 = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone				 = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang				 = Vector(0,0,0), Angle(0,0,0)
			local m				 = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang				 = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r				 = -ang.r -- Fixes mirrored models
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
				
				v.modelEnt				 = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel				 = v.model
				else
					v.modelEnt				 = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite ~= "" and (!v.spriteMaterial or v.createdSprite ~= v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name				 = v.sprite.."-"
				local params				 = { ["$basetexture"]				 = v.sprite }
				-- make sure we create a unique name based on the selected options
				local tocheck				 = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j]				 = 1
						name				 = name.."1"
					else
						name				 = name.."0"
					end
				end

				v.createdSprite				 = v.sprite
				v.spriteMaterial				 = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet				 = false
	--[[=======================================================
		-- FUNC SWEP:UpdateBonePositions()
	========================================================]]
	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			-- !! WORKAROUND !! --
			-- We need to check all model names :/
			local loopthrough				 = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones				 = {}
				for i=0, vm:GetBoneCount() do
					local bonename				 = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename]				 = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename]				 = { 
							scale				 = Vector(1,1,1),
							pos				 = Vector(0,0,0),
							angle				 = Angle(0,0,0)
						}
					end
				end
				
				loopthrough				 = allbones
			end
			-- !! ----------- !! --
			
			for k, v in pairs( loopthrough ) do
				local bone				 = vm:LookupBone(k)
				if (!bone) then continue end
				
				-- !! WORKAROUND !! --
				local s				 = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p				 = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms				 = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur				 = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale				 = loopthrough[vm:GetBoneName(cur)].scale
						ms				 = ms * pscale
						cur				 = vm:GetBoneParent(cur)
					end
				end
				
				s				 = s * ms
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
		
		local res				 = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k]				 = table.FullCopy(v) -- recursion ho!
			elseif (type(v) == "Vector") then
				res[k]				 = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k]				 = Angle(v.p, v.y, v.r)
			else
				res[k]				 = v
			end
		end
		
		return res
		
	end

	-- !SECTION CLIENT
end


