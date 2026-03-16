
include( "cl_vgui.lua")
include('shared.lua')

local LP = LocalPlayer()
local SW, SH = ScrW(), ScrH()
local SS = ScreenScale

SWEP.Category							= "ZDEV Editors"

SWEP.Author								= "ZCOM Studios"
SWEP.Contact							= "zcom.studios@gmail.com"
SWEP.Purpose							= ""
SWEP.Instructions						= ""

SWEP.ViewModelFOV					= 65
SWEP.BobScale						= 1.15
SWEP.SwayScale						= 1.33

SWEP.ViewModelFlip				=false
SWEP.ViewModelFlip1			 	=false
SWEP.ViewModelFlip2				= false
SWEP.AccurateCrosshair			= true
SWEP.CSMuzzleFlashes			= true
SWEP.CSMuzzleX					= true
SWEP.UseHands					= true
SWEP.SpeechBubbleLid			= false
SWEP.BounceWeaponIcon			= false
SWEP.DrawWeaponInfoBox			= true
SWEP.DrawAmmo					= false
SWEP.DrawCrosshair				= true
SWEP.WepSelectIcon				= ""

SWEP.RenderGroup					= RENDERGROUP_OPAQUE

SWEP.VGUI = {}

--function SWEP:AdjustMouseSensitivity( )	end
--function SWEP:CalcView( )	end
--function SWEP:CalcViewModelView( )	end
--function SWEP:CustomAmmoDisplay( )	end
--function SWEP:DrawWeaponSelection( )	end
--function SWEP:DrawWorldModel( )	end
--function SWEP:DrawWorldModelTranslucent( )	end
--function SWEP:FreezeMovement( )	end
--function SWEP:GetTracerOrigin( )	end
--function SWEP:GetViewModelPosition( )	end
--function SWEP:PostDrawViewModel( )	end
--function SWEP:PreDrawViewModel( )	end
--function SWEP:PrintWeaponInfo( )	end
--function SWEP:TranslateFOV( )	end
--function SWEP:ViewModelDrawn( )	end

function SWEP:HUDShouldDraw( )

	return true
	
end

local CrossHair = {}
CrossHair.Size = { w=8, h=8 }
CrossHair.Color = {
	default = Color(255,200,50,100),
	valid = Color(100,255,100,100),
	invalid = Color(255,100,100,100)
}
function SWEP:DoDrawCrosshair( x, y )

	local trace = self:GetTrace()
	local hitpos = trace.HitPos
	local normal = trace.HitNormal
	local tent = trace.Entity

	local w, h = CrossHair.Size.w, CrossHair.Size.h
	local clr = CrossHair.Color.default

	if IsValid(tent) and !tent:IsWorld() then
		clr = CrossHair.Color.valid
	end

	draw.RoundedBox( 0, x - w*0.5, y - h*0.5, w, h, clr )

end

function SWEP:DrawHUD( )

	local trace = self:GetTrace()
	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
	self:DoDrawCrosshair( x, y )
	
	--print( "DrawHUD" )
end

function SWEP:DrawHUDBackground( )

end

function SWEP:RenderScreen( )	

end

function SWEP:CreateMenu(  )

	local menu = DermaMenu( vgui.GetWorldPanel() )
	menu:AddOption( "Sprite", function() RunConsoleCommand( "ent_create", "effect_sprite" ) end )
	menu:AddOption( "Emitter", function() RunConsoleCommand( "ent_create", "effect_emitter" ) end ) -- The menu will remove itself, we don't have to do anything.
	menu:Center()
	menu:Open()

	self.VGUI.Menu_Create = menu

end


function SWEP:EditorMenu(  )

	local w, h = SW * 0.15, SH * 0.5
	local convars = self.ClientConVar

	local menu = vgui.Create( "DFrame", vgui.GetWorldPanel() )
	menu:SetPos( SW * 0.9 - w, SH * 0.9 - h  )
	menu:SetSize( w, h )
	menu:MakePopup( true )

	menu.pr = vgui.Create( "DProperties", menu )
	menu.pr:Dock( FILL )
	menu.pr.row = {}

	menu.pr.row.name = menu.pr:CreateRow( "Core", "Generic" )
	menu.pr.row.name:Setup( "Generic" )
	menu.pr.row.name:SetValue( "Custom Effect Name" )
	
	menu.pr.row.name = menu.pr:CreateRow( "Core", "Generic" )
	menu.pr.row.name:Setup( "Generic" )
	menu.pr.row.name:SetValue( "Custom Effect Name" )

	local convars_vals = self:GetClientConVars()
	MsgC( Color(255,100,255), "ConVar - Values:\n")
	PrintTable( convars_vals )

	local convars_keys = table.GetKeys( convars )
	MsgC( Color(255,100,255), "ConVar - Keys:\n")
	PrintTable( convars_keys )

	MsgC( Color(255,100,255), "ConVar - Menu Loop:\n")
	local i = 0
	for var, val in pairs( convars ) do

		local i = table.KeyFromValue( convars_keys, var )
		local name = val.name
		local cat

		if string.find( var, "_emitter_", 1, false ) then cat = "Emitter"
		elseif string.find( var, "_sprite_", 1, false ) then cat = "Sprite" end

		local property = val.property
		local value = convars_vals[ var ]
		MsgC( color_white, "----------------------------------------\n" )

		MsgC( Color(255,200,0), tostring(i) .. " " .. tostring(var) .. " " .. tostring(value) .. "\n" )
		PrintTable( val )
		
		MsgC( Color(200,200,200), " (" .. tostring( name) .. " " .. tostring( cat) .. " " .. tostring( property) .. " " .. tostring( value ) .. ") \n" )

		local row = menu.pr:CreateRow( cat, name )
		row:Setup( property, { min=val.min, max=val.max, waitforenter=true} )
		if property == "VectorColor" then
			local c = string.ToColor( value )
			value = Vector( c.r, c.g, c.b, c.a )
		elseif property == "Boolean" then
			value = tobool( value )
		end
		row:SetValue( value )
		row.DataChanged = function( self, data )
			print( self, var, data )
			RunConsoleCommand( var, data )
		end
	end

	self.VGUI.Menu_Editor = menu

end