
SWEP.PrintName			= "Effect Editor"

SWEP.Spawnable			= true
SWEP.AdminOnly			= false

SWEP.ViewModel			= Model("models/weapons/v_c4.mdl")
SWEP.WorldModel			= Model("models/weapons/w_c4.mdl")
SWEP.Slot				= 5
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
--function SWEP:Ammo1( )	end

--function SWEP:Ammo2( )	end
--function SWEP:CanPrimaryAttack( )	end
--function SWEP:DoImpactEffect( )	end
--function SWEP:FireAnimationEvent( )	end
--function SWEP:OnReloaded( )	end
--function SWEP:OnRemove( )	end
--function SWEP:OnRestore( )	end
--function SWEP:OwnerChanged( )	end
--function SWEP:SetDeploySpeed( )	end
--function SWEP:SetWeaponHoldType( )	end
--function SWEP:ShootBullet( )	end
--function SWEP:ShootEffects( )	end
--function SWEP:TakePrimaryAmmo( )	end
--function SWEP:TakeSecondaryAmmo( )	end
--function SWEP:TranslateActivity( )	end

CreateClientConVar( "zdev_edit_fx_sprite_material", "sprites/efx_0a_glow_24", true, false, "")
CreateClientConVar( "zdev_edit_fx_sprite_scale", 0.25, true, false, "")
CreateClientConVar( "zdev_edit_fx_sprite_color", "255 255 255 255", true, false, "")
CreateClientConVar( "zdev_edit_fx_sprite_alpha", 255, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_max", 100, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_min", 50, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_material", "sprites/efx_0a_glow_24", true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_collide", 1, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_bounce", 0.4, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_size_start", 1.0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_alpha_start", 255, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_length_start", 0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_lifetime", 0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_dietime", 0.5, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_size_end", 0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_alpha_end", 0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_length_end", 0, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_color", "255 255 255 255", true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_airresistance", 100, true, false, "")
CreateClientConVar( "zdev_edit_fx_emitter_gravity", "0 0 0", true, false, "")

SWEP.ClientConVar = {
	["zdev_edit_fx_sprite_material"] = {name="Material", type="string", property="Generic", min=nil, max=nil},
	["zdev_edit_fx_sprite_scale"] = {name="Scale", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_sprite_color"] = {name="Color", type="string", property="VectorColor", min=nil, max=nil},
	["zdev_edit_fx_sprite_alpha"] = {name="Alpha", type="number", property="Int", min=0, max=9999},
	["zdev_edit_fx_emitter_max"] = {name="Particles (Max)", type="number", property="Int", min=0, max=9999},
	["zdev_edit_fx_emitter_min"] = {name="Particles (Min)", type="number", property="Int", min=0, max=9999},
	["zdev_edit_fx_emitter_material"] = {name="Material", type="string", property="Generic", min=nil, max=nil},
	["zdev_edit_fx_emitter_collide"] = {name="Collide", type="boolean", property="Boolean", min=nil, max=nil},
	["zdev_edit_fx_emitter_bounce"] = {name="Bounce", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_size_start"] = {name="Start Size", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_alpha_start"] = {name="Start Alpha", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_length_start"] = {name="Start Length", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_lifetime"] = {name="Lifetime", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_dietime"] = {name="Dietime", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_size_end"] = {name="End Size", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_alpha_end"] = {name="End Alpha", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_length_end"] = {name="End Length", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_color"] = {name="Color", type="string", property="VectorColor", min=nil, max=nil},
	["zdev_edit_fx_emitter_airresistance"] = {name="Air Resistance", type="float", property="Float", min=0.000, max=99.999},
	["zdev_edit_fx_emitter_gravity"] = {name="Gravity", type="string", property="VectorColor", min=nil, max=nil}

}

-- Deprecated fxedit_* aliases (Sweep Phase 4b): value-migrating, write-mirroring.
if CLIENT and ZDEV and ZDEV.CONV and ZDEV.CONV.LegacyAlias then
	for cvar in pairs( SWEP.ClientConVar ) do
		ZDEV.CONV.LegacyAlias( cvar, ( string.gsub( cvar, "^zdev_edit_fx_", "fxedit_" ) ) )
	end
end

function SWEP:GetClientConVars( )

	local t_cconvars = {}

	for cv, tbl in pairs( self.ClientConVar ) do
		local t = tbl.type
		local val = GetConVar( cv )
		if t == "float" then
			val = val:GetFloat()
		elseif t == "number" then
			val = val:GetInt()
		elseif t == "string" then 
			val = val:GetString()
		elseif t == "boolean" then
			val = val:GetBool()
		end

		t_cconvars[ cv ] = val

	end

	return t_cconvars

end

function SWEP:SetupDataTables( )

	self:NetworkVar( "String", 0, "SpriteMaterial" )
	self:NetworkVar( "Float", 0, "SpriteScale" )
	self:NetworkVar( "Vector", 0, "SpriteColor" )
	self:NetworkVar( "Int", 0, "SpriteAlpha" )

	self:NetworkVar( "Bool", 1, "EmitterOn")
	self:NetworkVar( "Int", 2, "EmitterMax")
	self:NetworkVar( "Int", 3, "EmitterMin")
	self:NetworkVar( "String", 4, "EmitterMaterial")
	self:NetworkVar( "Float", 5, "EmitterBounce")
	self:NetworkVar( "Bool", 6, "EmitterCollide")
	self:NetworkVar( "Float", 7, "EmitterStartSize")
	self:NetworkVar( "Float", 8, "EmitterStartAlpha")
	self:NetworkVar( "Float", 9, "EmitterStartLength")
	self:NetworkVar( "Float", 10, "EmitterEndSize")
	self:NetworkVar( "Float", 11, "EmitterEndAlpha")
	self:NetworkVar( "Float", 12, "EmitterEndLength")
	self:NetworkVar( "Vector", 13, "EmitterColor")
	self:NetworkVar( "Float", 14, "EmitterLifetime")
	self:NetworkVar( "Float", 15, "EmitterDietime")
	self:NetworkVar( "Float", 16, "EmitterAirResistance")
	self:NetworkVar( "Vector", 17, "EmitterGravity")

end

function SWEP:Initialize( )

	self:SetHoldType( self.HoldType )

end

function SWEP:Deploy( )	
	
	return true 
	
end

function SWEP:Holster( )

	return true

end

function SWEP:Reload( )

	if self.m_iNextReload > CurTime() then return end
	self.m_iNextReload = CurTime() + self.m_iReloadDelay

	if CLIENT then
		self:EditorMenu()
	end

end

function SWEP:PrimaryAttack( )

end

function SWEP:SecondaryAttack( )

	if CLIENT then
		--self:CreateMenu()
	end
	local trace = self:GetTrace()
	
	if SERVER then
		if self.Owner:KeyDown( IN_USE ) then
			self:CreateEmitter( trent, trace.HitPos, Angle(0,0,0) )
		else
			self:CreateSprite( trent, trace.HitPos, Angle(0,0,0) )
		end
	end

	self:SetNextSecondaryFire( CurTime() + 0.5 )

end

function SWEP:Think( )

	return true
end

function SWEP:GetTrace()
	local owner = self.Owner
	if !IsValid(owner) then return end

	if ( owner:IsPlayer() ) then
		owner:LagCompensation( true )
	end

	local trace = owner:GetEyeTrace()

	if ( owner:IsPlayer() ) then
		owner:LagCompensation( false )
	end

	return trace
end


function SWEP:CreateSprite( parent, pos, ang  )

	local convar = self:GetClientConVars( )

	local mat, color, scale, alpha
	mat = convar["zdev_edit_fx_sprite_material"]
	scale = convar["zdev_edit_fx_sprite_scale"]
	color = string.ToColor( convar["zdev_edit_fx_sprite_color"] )
	alpha = color.a or 254

	local spr = ents.Create( "effect_sprite" )
	spr:Spawn()
	--spr:SetOwner( self.Owner 
	spr:SetParent( parent )
	spr:SetPos( pos )
	spr:SetAngles( ang )
	spr:SetSpriteMaterial( mat )
	spr:SetSpriteScale( scale )
	spr:SetSpriteColor( Vector(color.r, color.g, color.b ) )
	spr:SetSpriteAlpha( color.a )

	if SERVER then
		undo.Create("sprite")
			undo.AddEntity(spr)
			undo.SetPlayer(self.Owner)
		undo.Finish()
	end

end

function SWEP:CreateEmitter( parent, pos, ang )

	local convar = self:GetClientConVars( )

	local mat, color, lifetime, dietime,  start_size, start_alpha, start_len, end_size, end_alpha, end_len, min, max, bounce, collide, airres, gravity
	mat = convar["zdev_edit_fx_sprite_material"]
	color = string.ToColor( convar["zdev_edit_fx_emitter_color"] )
	lifetime, dietime = convar["zdev_edit_fx_emitter_lifetime"], convar["zdev_edit_fx_emitter_dietime"]
	start_size, end_size = convar["zdev_edit_fx_emitter_size_start"], convar["zdev_edit_fx_emitter_size_end"]
 	start_alpha, end_alpha = convar["zdev_edit_fx_emitter_alpha_start"], convar["zdev_edit_fx_emitter_alpha_end"]
	start_len, end_len = convar["zdev_edit_fx_emitter_length_start"], convar["zdev_edit_fx_emitter_length_end"]
	bounce, collide = convar["zdev_edit_fx_emitter_bounce"], convar["zdev_edit_fx_emitter_collide"]
	min, max = convar["zdev_edit_fx_emitter_min"], convar["zdev_edit_fx_emitter_max"]
	airres, gravity = convar["zdev_edit_fx_emitter_airresistance"], convar["zdev_edit_fx_emitter_gravity"]
	
	MsgC( Color(255,100,255), "Creating new Particle Emitter:\n" )
	print( mat, airres, gravity, lifetime, dietime,  start_size, start_alpha, start_len, end_size, end_alpha, end_len, min, max, bounce, collide)

	local spr = ents.Create( "effect_emitter" )
	spr:Spawn()
	--spr:SetOwner( self.Owner )
	spr:SetParent( parent )
	spr:SetPos( pos )
	spr:SetAngles( ang )
	spr:SetEmitterMaterial( mat )
	spr:SetEmitterColor( Vector(color.r, color.g, color.b ) )
	spr:SetEmitterLifetime( lifetime )
	spr:SetEmitterDietime( dietime )
	spr:SetEmitterStartSize( start_size )
	spr:SetEmitterEndSize( end_size )
	spr:SetEmitterStartAlpha( start_alpha )
	spr:SetEmitterEndAlpha( end_alpha )
	spr:SetEmitterStartLength( start_len )
	spr:SetEmitterEndLength( end_len)
	spr:SetEmitterBounce( bounce )
	spr:SetEmitterCollide( collide )
	spr:SetEmitterMin( min )
	spr:SetEmitterMax( max )
	spr:SetEmitterOn( true )

	spr:SetEmitterTime( lifetime, dietime )
	spr:SetEmitterAlpha( start_alpha, end_alpha)
	spr:SetEmitterSize( start_size, end_size )
	spr:SetEmitterLength( start_len, end_len )
	spr:SetEmitterCount( min, max )
	
	if SERVER then
		undo.Create("emitter")
			undo.AddEntity(spr)
			undo.SetPlayer(self.Owner)
		undo.Finish()
	end
end
