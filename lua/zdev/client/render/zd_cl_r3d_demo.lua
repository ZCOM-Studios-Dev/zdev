local _f = 'zdev/client/render/zd_cl_r3d_demo.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_r3d_demo.lua — ZDEV.R3D showcase + reference
	Author: zcomstudios

	`zdev_r3d_demo` opens a model panel with:
	  - a live translate / rotate / scale gizmo you can grab and drag
	    (LEFT mouse = gizmo, RIGHT mouse = orbit camera)
	  - a togglable gallery of every primitive so the look is judgeable at a
	    glance.

	This file is also the canonical example for child addons: it shows the
	two-call contract (Draw in the 3D pass, Input in Think) and how to let a
	gizmo coexist with camera orbit via gizmo:IsActive().
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Command registered BEFORE the reload guard so it survives zdev_reload.
local function OpenDemo()  if ZDEV.R3D and ZDEV.R3D.OpenDemo     then ZDEV.R3D.OpenDemo()     end end
local function OpenSettings() if ZDEV.R3D and ZDEV.R3D.OpenSettings then ZDEV.R3D.OpenSettings() end end

if ZDEV.CMDS and ZDEV.CMDS.Register then
	ZDEV.CMDS.Register( "zdev_r3d_demo", OpenDemo, { help = "Open the ZDEV.R3D render-library showcase." } )
	ZDEV.CMDS.Register( "zdev_r3d_settings", OpenSettings, { help = "Open the ZDEV.R3D gizmo appearance settings." } )
else
	concommand.Add( "zdev_r3d_demo", OpenDemo )
	concommand.Add( "zdev_r3d_settings", OpenSettings )
end

if ZDEV.FILE.Loaded( _f ) then return end

local R3D = ZDEV.R3D

-- Path: ZDEV.R3D.OpenDemo
function R3D.OpenDemo()
	if IsValid( R3D._demoFrame ) then R3D._demoFrame:Remove() end

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 720, 560 )
	frame:Center()
	frame:SetTitle( "ZDEV.R3D — Render Utility Showcase" )
	frame:MakePopup()
	R3D._demoFrame = frame

	-- top toolbar
	local bar = vgui.Create( "DPanel", frame )
	bar:Dock( TOP )
	bar:SetTall( 30 )
	bar:DockMargin( 0, 0, 0, 4 )
	bar.Paint = function() end

	-- readout
	local readout = vgui.Create( "DLabel", frame )
	readout:Dock( BOTTOM )
	readout:SetTall( 20 )
	readout:SetText( "" )
	readout:SetContentAlignment( 5 )

	-- 3D viewport — plain DPanel container (NEVER DScrollPanel) then DModelPanel
	local view = vgui.Create( "DModelPanel", frame )
	view:Dock( FILL )
	view:SetModel( "models/player/kleiner.mdl" )

	-- state
	local mode      = "translate"
	local showGallery = false
	local ent       = view.Entity
	local center    = IsValid( ent ) and ent:LocalToWorld( ent:OBBCenter() ) or vector_origin

	local gizmo = R3D.NewGizmo( {
		mode  = mode,
		pos   = center,
		ang   = Angle( 0, 0, 0 ),
		size  = 22,
		space = "world",
		onChange = function( pos, ang, self )
			local s = self.scale
			readout:SetText( string.format(
				"pos  %.1f  %.1f  %.1f      ang  %.1f  %.1f  %.1f      scale  %.2f  %.2f  %.2f",
				pos.x, pos.y, pos.z, ang.p, ang.y, ang.r, s.x, s.y, s.z ) )
		end,
	} )

	-- Hit-test in panel-local space. Inside a DModelPanel ToScreen projects to the
	-- WHOLE screen, so PanelProjector rescales into the panel's own w/h and
	-- PanelCursor reads the cursor the same way. (See ZDEV.R3D.PanelProjector.)
	gizmo:SetProjector( R3D.PanelProjector( view ) )

	-- manual orbit camera (RIGHT mouse), leaves LEFT mouse for the gizmo
	local orbit = { yaw = -30, pitch = 20, dist = 90 }
	local lastRMB, lastMX, lastMY = false, 0, 0
	view.LayoutEntity = function( _, e ) return e end   -- kill auto-spin

	view.Think = function( self )
		local mx, my = R3D.PanelCursor( self )   -- panel-local, matches the projector
		local hovered = self:IsHovered() or gizmo:IsDragging()
		local lmb = hovered and input.IsMouseDown( MOUSE_LEFT )
		local rmb = hovered and input.IsMouseDown( MOUSE_RIGHT )

		-- gizmo first; it reports whether it owns the cursor
		gizmo:Input( mx, my, lmb )

		-- orbit only when the gizmo isn't hot and RIGHT mouse is held
		if rmb and not gizmo:IsActive() then
			if lastRMB then
				orbit.yaw   = orbit.yaw   - ( mx - lastMX ) * 0.5
				orbit.pitch = math.Clamp( orbit.pitch + ( my - lastMY ) * 0.5, -80, 80 )
			end
			lastRMB = true
		else
			lastRMB = false
		end
		lastMX, lastMY = mx, my

		local camAng = Angle( orbit.pitch, orbit.yaw, 0 )
		self:SetCamPos( center - camAng:Forward() * orbit.dist )
		self:SetLookAt( center )
	end

	view.PostDrawModel = function( self, e )
		local camPos = self:GetCamPos()
		gizmo:Draw( camPos )
		if showGallery then R3D._DrawGallery( center, camPos ) end
	end

	-- toolbar buttons
	local function mkBtn( label, fn, wide )
		local b = vgui.Create( "DButton", bar )
		b:Dock( LEFT )
		b:DockMargin( 2, 2, 2, 2 )
		b:SetWide( wide or 78 )
		b:SetText( label )
		b.DoClick = fn
		return b
	end
	mkBtn( "Translate", function() mode = "translate" gizmo:SetMode( mode ) end )
	mkBtn( "Rotate",    function() mode = "rotate"    gizmo:SetMode( mode ) end )
	mkBtn( "Scale",     function() mode = "scale"     gizmo:SetMode( mode ) end )
	mkBtn( "Gallery",   function() showGallery = not showGallery end )
	mkBtn( "World/Local", function()
		gizmo.space = ( gizmo.space == "world" ) and "local" or "world"
	end, 90 )
	mkBtn( "Reset", function()
		gizmo:SetTransform( center, Angle( 0, 0, 0 ) )
		gizmo.scale = Vector( 1, 1, 1 )
		gizmo.size = 22
	end )
	mkBtn( "Settings", function() R3D.OpenSettings() end )
end

-- Static gallery of every primitive, laid out in a row beside the model.
function R3D._DrawGallery( center, camPos )
	local base = center + Vector( 40, 0, 20 )
	local step = 26
	local white = color_white

	-- thick line vs thin line
	R3D.Line( base, base + Vector( 0, step, 0 ), R3D.COL_X, 4 )
	R3D.Line( base + Vector( 0, 0, -6 ), base + Vector( 0, step, -6 ), R3D.COL_X, 1 )
	R3D.Text( base + Vector( 0, step * 0.5, 8 ), "Line", white, "DermaDefault", 0.05, camPos )

	-- dashed line
	local b2 = base + Vector( step, 0, 0 )
	R3D.DashedLine( b2, b2 + Vector( 0, step, 0 ), R3D.COL_Y, 3, 3, 2 )

	-- ring + disc
	local b3 = base + Vector( step * 2, 0, 0 )
	R3D.Ring( b3, Vector( 1, 0, 0 ), 10, R3D.COL_Z, 3 )
	R3D.Disc( b3 + Vector( 0, 0, -22 ), Vector( 0, 0, 1 ), 9, Color( 120, 120, 255, 160 ) )

	-- sphere + wire sphere
	local b4 = base + Vector( step * 3, 0, 0 )
	R3D.Sphere( b4, 7, Color( 255, 160, 60 ) )
	R3D.WireSphere( b4 + Vector( 0, 0, -22 ), 8, Color( 255, 255, 255, 200 ) )

	-- wire box + arrow + cross
	local b5 = base + Vector( step * 4, 0, 0 )
	R3D.WireBox( b5, Angle(), Vector( -8, -8, -8 ), Vector( 8, 8, 8 ), R3D.COL_HL )
	R3D.Arrow( b5 + Vector( 0, 0, -22 ), b5 + Vector( 0, 16, -22 ), R3D.COL_Y, 3 )
	R3D.Cross( b5 + Vector( 0, 0, 20 ), 6, white, 2 )
end

ZDEV.FILE.SetLoaded( _f )
