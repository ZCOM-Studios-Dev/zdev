local _f = 'zdev/client/render/zd_cl_r3d.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_r3d.lua — ZDEV.R3D  (3D Render Utility Library)
	Author: zcomstudios

	Foundational, reusable 3D world-space render primitives for helpers,
	markers, gizmos and widgets. Built so child addons (Weapons / SNPCs)
	never have to hand-stitch circles out of line segments or fake thick
	lines with offset thin ones again.

	ALL draw functions must be called inside a 3D rendering context:
	  - a world hook: PostDrawTranslucentRenderables / PostDrawOpaqueRenderables
	  - a model panel: DModelPanel:PostDrawModel
	They rely on render.* which is only valid there.

	Thick lines are real camera-facing beams (render.DrawBeam), not stacked
	thin lines. Rings sample an orthonormal basis around a normal. Filled
	shapes are triangle meshes. Everything is vertex-coloured via
	render.SetColorMaterial() so there is zero external material dependency.

	The interactive gizmo controller lives in zd_cl_r3d_widget.lua.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.R3D = ZDEV.R3D or {}
local R3D = ZDEV.R3D

if ZDEV.FILE.Loaded( _f ) then return end

local render          = render
local mesh            = mesh
local math_cos        = math.cos
local math_sin        = math.sin
local math_rad        = math.rad
local math_pi         = math.pi
local TWO_PI          = math.pi * 2
local color_white     = color_white

-- Default palette for axis-coloured gizmos (X/Y/Z = R/G/B, industry standard).
R3D.COL_X = Color( 235,  70,  70 )
R3D.COL_Y = Color(  90, 220,  90 )
R3D.COL_Z = Color(  80, 150, 255 )
R3D.COL_HL = Color( 255, 235, 120 )   -- hover / active highlight

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MATH HELPERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Two unit vectors that span the plane whose normal is `normal`.
-- Path: ZDEV.R3D.PlaneBasis
function R3D.PlaneBasis( normal )
	local ang = normal:Angle()
	return ang:Right(), ang:Up()
end
local PlaneBasis = R3D.PlaneBasis

-- Project a world position to absolute screen space.
-- Returns x, y, visible. `visible` is false when the point is behind the camera.
-- Absolute coords match input.GetCursorPos(), so hit-testing works in both
-- world hooks and model panels without ScreenToLocal.
-- Path: ZDEV.R3D.ToScreen
function R3D.ToScreen( pos )
	local s = pos:ToScreen()
	return s.x, s.y, s.visible
end

-- Projector + cursor pair for hit-testing a gizmo inside a DModelPanel.
--
-- Inside a model panel, Vector:ToScreen() projects as if the panel's 3D view
-- filled the WHOLE screen — it returns coords in [0..ScrW]x[0..ScrH], NOT the
-- panel's on-screen rectangle. So a plain ScreenToLocal (offset only) can't line
-- it up: the error scales with distance from view-centre. Rescaling the full-
-- screen coords into the panel's own width/height space fixes it, and the cursor
-- read the same way lands in the identical space.
--
--   gizmo:SetProjector( ZDEV.R3D.PanelProjector( panel ) )
--   -- each frame, feed Input the matching cursor:
--   gizmo:Input( ZDEV.R3D.PanelCursor( panel ) )   -- returns mx, my ; add , down
--
-- Path: ZDEV.R3D.PanelProjector
function R3D.PanelProjector( panel )
	return function( v )
		local s = v:ToScreen()
		return s.x / ScrW() * panel:GetWide(), s.y / ScrH() * panel:GetTall(), s.visible
	end
end

-- Panel-local cursor in the SAME space PanelProjector produces.
-- Path: ZDEV.R3D.PanelCursor
function R3D.PanelCursor( panel )
	local ax, ay = input.GetCursorPos()
	return panel:ScreenToLocal( ax, ay )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PRIMITIVES — LINES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Thick, camera-facing 3D line. width is in WORLD units.
-- nil/0 width = engine 1px line. ANY positive width renders a real beam —
-- including sub-1 widths, which matter up close: a 0.1-unit beam 10 units from
-- the camera is visibly thick on screen. (The old `width <= 1` cutoff collapsed
-- close-range gizmos to 1px lines because gizmo width scales with distance.)
-- Path: ZDEV.R3D.Line
function R3D.Line( startPos, endPos, color, width )
	color = color or color_white
	if not width or width <= 0 then
		render.DrawLine( startPos, endPos, color, false )
		return
	end
	render.SetColorMaterial()
	render.DrawBeam( startPos, endPos, width, 0, 1, color )
end
local Line = R3D.Line

-- Dashed 3D line. dashLen/gapLen in world units.
-- Path: ZDEV.R3D.DashedLine
function R3D.DashedLine( startPos, endPos, color, width, dashLen, gapLen )
	dashLen = dashLen or 4
	gapLen  = gapLen or dashLen
	local dir  = endPos - startPos
	local full = dir:Length()
	if full <= 0 then return end
	dir:Div( full )
	local step = dashLen + gapLen
	local d = 0
	while d < full do
		local a = startPos + dir * d
		local b = startPos + dir * math.min( d + dashLen, full )
		Line( a, b, color, width )
		d = d + step
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PRIMITIVES — CIRCLES / RINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Ring outline in 3D. `normal` is the ring's axis. Real thickness via beams.
-- arcStart/arcEnd (degrees) default to a full 0..360 circle.
-- Path: ZDEV.R3D.Ring
function R3D.Ring( pos, normal, radius, color, width, segments, arcStart, arcEnd )
	color    = color or color_white
	width    = width or 0   -- nil/0 = 1px lines; any positive width = beams (see R3D.Line)
	segments = segments or 48
	arcStart = arcStart or 0
	arcEnd   = arcEnd or 360
	local ax, ay = PlaneBasis( normal )
	local span   = math_rad( arcEnd - arcStart )
	local base   = math_rad( arcStart )

	local beam = width > 0
	if beam then render.SetColorMaterial() end

	local prev
	for i = 0, segments do
		local t = base + span * ( i / segments )
		local p = pos + ( ax * math_cos( t ) + ay * math_sin( t ) ) * radius
		if prev then
			if beam then
				render.DrawBeam( prev, p, width, 0, 1, color )
			else
				render.DrawLine( prev, p, color, false )
			end
		end
		prev = p
	end
end
local Ring = R3D.Ring

-- Filled disc (triangle fan mesh) facing `normal`.
-- Path: ZDEV.R3D.Disc
function R3D.Disc( pos, normal, radius, color, segments )
	color    = color or color_white
	segments = segments or 48
	local ax, ay = PlaneBasis( normal )
	local r, g, b, a = color.r, color.g, color.b, color.a or 255

	render.SetColorMaterial()
	mesh.Begin( MATERIAL_TRIANGLES, segments )
	for i = 0, segments - 1 do
		local t1 = TWO_PI * ( i / segments )
		local t2 = TWO_PI * ( ( i + 1 ) / segments )
		local p1 = pos + ( ax * math_cos( t1 ) + ay * math_sin( t1 ) ) * radius
		local p2 = pos + ( ax * math_cos( t2 ) + ay * math_sin( t2 ) ) * radius

		mesh.Color( r, g, b, a ) mesh.Position( pos ) mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p1 )  mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p2 )  mesh.AdvanceVertex()
	end
	mesh.End()
end

-- Filled convex quad from 4 world corners (2 triangles).
-- Path: ZDEV.R3D.Quad
function R3D.Quad( p1, p2, p3, p4, color )
	color = color or color_white
	local r, g, b, a = color.r, color.g, color.b, color.a or 255
	render.SetColorMaterial()
	mesh.Begin( MATERIAL_TRIANGLES, 2 )
	mesh.Color( r, g, b, a ) mesh.Position( p1 ) mesh.AdvanceVertex()
	mesh.Color( r, g, b, a ) mesh.Position( p2 ) mesh.AdvanceVertex()
	mesh.Color( r, g, b, a ) mesh.Position( p3 ) mesh.AdvanceVertex()
	mesh.Color( r, g, b, a ) mesh.Position( p1 ) mesh.AdvanceVertex()
	mesh.Color( r, g, b, a ) mesh.Position( p3 ) mesh.AdvanceVertex()
	mesh.Color( r, g, b, a ) mesh.Position( p4 ) mesh.AdvanceVertex()
	mesh.End()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PRIMITIVES — VOLUMES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Path: ZDEV.R3D.Sphere
function R3D.Sphere( pos, radius, color, steps )
	steps = steps or 16
	render.SetColorMaterial()
	render.DrawSphere( pos, radius, steps, steps, color or color_white )
end
local Sphere = R3D.Sphere

-- Path: ZDEV.R3D.WireSphere
function R3D.WireSphere( pos, radius, color, steps )
	steps = steps or 16
	render.DrawWireframeSphere( pos, radius, steps, steps, color or color_white, false )
end

-- Path: ZDEV.R3D.Box
function R3D.Box( pos, ang, mins, maxs, color )
	render.SetColorMaterial()
	render.DrawBox( pos, ang or angle_zero, mins, maxs, color or color_white )
end

-- Path: ZDEV.R3D.WireBox
function R3D.WireBox( pos, ang, mins, maxs, color )
	render.DrawWireframeBox( pos, ang or angle_zero, mins, maxs, color or color_white, false )
end

-- Solid cone: base circle around `baseCenter` (perp to `dir`) up to `tip`.
-- Path: ZDEV.R3D.Cone
function R3D.Cone( baseCenter, dir, radius, tip, color, segments )
	color    = color or color_white
	segments = segments or 14
	local ax, ay = PlaneBasis( dir:GetNormalized() )
	local r, g, b, a = color.r, color.g, color.b, color.a or 255

	render.SetColorMaterial()
	mesh.Begin( MATERIAL_TRIANGLES, segments * 2 )
	for i = 0, segments - 1 do
		local t1 = TWO_PI * ( i / segments )
		local t2 = TWO_PI * ( ( i + 1 ) / segments )
		local p1 = baseCenter + ( ax * math_cos( t1 ) + ay * math_sin( t1 ) ) * radius
		local p2 = baseCenter + ( ax * math_cos( t2 ) + ay * math_sin( t2 ) ) * radius

		-- side
		mesh.Color( r, g, b, a ) mesh.Position( tip ) mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p1 )  mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p2 )  mesh.AdvanceVertex()
		-- base cap (reverse winding so it is visible from behind)
		mesh.Color( r, g, b, a ) mesh.Position( baseCenter ) mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p2 ) mesh.AdvanceVertex()
		mesh.Color( r, g, b, a ) mesh.Position( p1 ) mesh.AdvanceVertex()
	end
	mesh.End()
end
local Cone = R3D.Cone

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PRIMITIVES — MARKERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Directional arrow: shaft beam + solid cone head. headLen/headRad optional.
-- Path: ZDEV.R3D.Arrow
function R3D.Arrow( startPos, endPos, color, width, headLen, headRad )
	color = color or color_white
	width = width or 2
	local dir  = endPos - startPos
	local len  = dir:Length()
	if len <= 0 then return end
	dir:Div( len )
	headLen = headLen or math.min( len * 0.34, math.max( width * 3, 5 ) )
	headRad = headRad or ( width * 1.6 + 1 )
	local base = endPos - dir * headLen
	Line( startPos, base, color, width )
	Cone( base, dir, headRad, endPos, color )
end

-- 3-axis tick marker (small +). `ang` optional (world axes if nil).
-- Path: ZDEV.R3D.Cross
function R3D.Cross( pos, size, color, width, ang )
	size = size or 4
	local fx, fy, fz
	if ang then
		fx, fy, fz = ang:Forward(), ang:Right(), ang:Up()
	else
		fx, fy, fz = Vector( 1, 0, 0 ), Vector( 0, 1, 0 ), Vector( 0, 0, 1 )
	end
	Line( pos - fx * size, pos + fx * size, color, width )
	Line( pos - fy * size, pos + fy * size, color, width )
	Line( pos - fz * size, pos + fz * size, color, width )
end

-- Flat camera-facing marker quad (a "point"). camPos defaults to the player eye;
-- pass a model panel's :GetCamPos() when drawing inside one.
-- Path: ZDEV.R3D.Point
function R3D.Point( pos, size, color, camPos )
	size = size or 3
	local n = ( ( camPos or EyePos() ) - pos )
	if n:LengthSqr() <= 0 then n = Vector( 0, 0, 1 ) else n:Normalize() end
	render.SetColorMaterial()
	render.DrawQuadEasy( pos, n, size, size, color or color_white, 0 )
end

-- Billboard text pinned to a world point. camAng defaults to the player view;
-- pass a model panel's cam angle when inside one. Uppercase yaw-billboard keeps
-- text upright from any pitch.
-- Path: ZDEV.R3D.Text
function R3D.Text( pos, text, color, font, scale, camPos )
	font  = font or "DermaDefault"
	scale = scale or 0.06
	color = color or color_white
	local cpos = camPos or EyePos()
	local hDir = Vector( cpos.x - pos.x, cpos.y - pos.y, 0 )
	if hDir:LengthSqr() <= 0 then hDir = Vector( 1, 0, 0 ) else hDir:Normalize() end
	local ang = Angle( 0, math.deg( math.atan2( hDir.y, hDir.x ) ) - 90, 90 )

	cam.Start3D2D( pos, ang, scale )
		draw.SimpleText( text, font, 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	cam.End3D2D()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	COMPOSITE — STATELESS GIZMO DRAWERS
	These just DRAW. For grab/drag interaction use ZDEV.R3D.NewGizmo
	(zd_cl_r3d_widget.lua), which composes these.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Resolve the 3 axis directions for a transform.
-- space "world" = global axes; "local" = relative to `ang`.
-- Path: ZDEV.R3D.AxisDirs
function R3D.AxisDirs( ang, space )
	if space == "world" or not ang then
		return Vector( 1, 0, 0 ), Vector( 0, 1, 0 ), Vector( 0, 0, 1 )
	end
	return ang:Forward(), ang:Right(), ang:Up()
end
local AxisDirs = R3D.AxisDirs

-- RGB XYZ axis triad (three arrows + centre node). Read-only helper.
-- Path: ZDEV.R3D.DrawAxisTriad
function R3D.DrawAxisTriad( pos, ang, size, width, space )
	size  = size or 16
	width = width or 2
	local x, y, z = AxisDirs( ang, space )
	R3D.Arrow( pos, pos + x * size, R3D.COL_X, width )
	R3D.Arrow( pos, pos + y * size, R3D.COL_Y, width )
	R3D.Arrow( pos, pos + z * size, R3D.COL_Z, width )
	Sphere( pos, width * 0.9, color_white, 10 )
end

-- Translate gizmo drawing. `hot` (optional "x"/"y"/"z") highlights one axis.
-- Path: ZDEV.R3D.DrawTranslateGizmo
function R3D.DrawTranslateGizmo( pos, ang, size, width, space, hot )
	size  = size or 16
	width = width or 2
	local x, y, z = AxisDirs( ang, space )
	R3D.Arrow( pos, pos + x * size, hot == "x" and R3D.COL_HL or R3D.COL_X, width )
	R3D.Arrow( pos, pos + y * size, hot == "y" and R3D.COL_HL or R3D.COL_Y, width )
	R3D.Arrow( pos, pos + z * size, hot == "z" and R3D.COL_HL or R3D.COL_Z, width )
	Sphere( pos, width * 0.9, color_white, 10 )
end

-- Rotate gizmo drawing (three rings). `hot` highlights one ring.
-- Path: ZDEV.R3D.DrawRotateGizmo
function R3D.DrawRotateGizmo( pos, ang, radius, width, space, hot )
	radius = radius or 16
	width  = width or 2
	local x, y, z = AxisDirs( ang, space )
	Ring( pos, x, radius, hot == "x" and R3D.COL_HL or R3D.COL_X, width )
	Ring( pos, y, radius, hot == "y" and R3D.COL_HL or R3D.COL_Y, width )
	Ring( pos, z, radius, hot == "z" and R3D.COL_HL or R3D.COL_Z, width )
end

-- Scale gizmo drawing (axis stalks with box handles). `hot` highlights one.
-- Path: ZDEV.R3D.DrawScaleGizmo
function R3D.DrawScaleGizmo( pos, ang, size, width, space, hot )
	size  = size or 16
	width = width or 2
	local x, y, z = AxisDirs( ang, space )
	local hb = Vector( width, width, width )
	local function stalk( dir, col, id )
		local c = hot == id and R3D.COL_HL or col
		local tip = pos + dir * size
		Line( pos, tip, c, width )
		R3D.Box( tip, ang, -hb, hb, c )
	end
	stalk( x, R3D.COL_X, "x" )
	stalk( y, R3D.COL_Y, "y" )
	stalk( z, R3D.COL_Z, "z" )
	R3D.Box( pos, ang, -hb, hb, color_white )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	APPEARANCE CONVARS  (registry-driven, per gmod-convar-registry rule)
	Every tunable is registered once here; the settings panel and the live
	widget both read FROM this registry so they can never drift apart.
	All are archived (persist across sessions) and read live each frame.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

R3D.CONVARS      = R3D.CONVARS or {}
R3D.CONVAR_ORDER = R3D.CONVAR_ORDER or {}

-- Path: ZDEV.R3D.RegisterVar
function R3D.RegisterVar( def )
	local name = "zdev_r3d_" .. def.s
	if R3D.CONVARS[ name ] then return R3D.CONVARS[ name ] end
	def.name = name
	def.cvar = CreateClientConVar( name, tostring( def.d ), true, false, def.help or "", def.min, def.max )
	R3D.CONVARS[ name ] = def
	R3D.CONVAR_ORDER[ #R3D.CONVAR_ORDER + 1 ] = name
	return def
end

local DEFS = {
	{ s = "gizmo_thickness", d = 0.035,         kind = "float", min = 0.005, max = 0.3, dec = 3, help = "Gizmo line width, as a fraction of gizmo size (0.035 = 0.25x the old default)." },
	{ s = "gizmo_alpha",     d = 1,             kind = "float", min = 0.1,   max = 1,   dec = 2, help = "Gizmo opacity." },
	{ s = "gizmo_highlight", d = 1,             kind = "bool",  min = 0, max = 1,                help = "Highlight the axis under the cursor." },
	{ s = "gizmo_col_x",     d = "235 70 70",   kind = "color", help = "X axis colour." },
	{ s = "gizmo_col_y",     d = "90 220 90",   kind = "color", help = "Y axis colour." },
	{ s = "gizmo_col_z",     d = "80 150 255",  kind = "color", help = "Z axis colour." },
	{ s = "gizmo_col_hl",    d = "255 235 120", kind = "color", help = "Highlight colour." },
}
for _, d in ipairs( DEFS ) do R3D.RegisterVar( d ) end

-- live numeric / bool accessors (safe if a var is missing)
function R3D.VarN( suffix, fallback )
	local d = R3D.CONVARS[ "zdev_r3d_" .. suffix ]
	return d and d.cvar:GetFloat() or fallback or 0
end
function R3D.VarB( suffix, fallback )
	local d = R3D.CONVARS[ "zdev_r3d_" .. suffix ]
	if not d then return fallback == true end
	return d.cvar:GetBool()
end

-- cached, mutable colours — no per-frame allocation (glua-2d-drawing Rule 5)
R3D._gcol = R3D._gcol or {
	x = Color( 255, 255, 255 ), y = Color( 255, 255, 255 ), z = Color( 255, 255, 255 ),
	hl = Color( 255, 255, 255 ), w = Color( 255, 255, 255 ),
}

local function ParseRGB( str )
	local r, g, b = string.match( tostring( str ), "(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)" )
	return math.Clamp( tonumber( r ) or 255, 0, 255 ),
	       math.Clamp( tonumber( g ) or 255, 0, 255 ),
	       math.Clamp( tonumber( b ) or 255, 0, 255 )
end
R3D.ParseRGB = ParseRGB

-- Path: ZDEV.R3D._RefreshColors
function R3D._RefreshColors()
	for _, id in ipairs( { "x", "y", "z", "hl" } ) do
		local d = R3D.CONVARS[ "zdev_r3d_gizmo_col_" .. id ]
		if d then
			local c = R3D._gcol[ id ]
			c.r, c.g, c.b = ParseRGB( d.cvar:GetString() )
		end
	end
end
R3D._RefreshColors()

-- identifier => replaces (not stacks) on hot-reload (gmod-deprecation-aliasing Rule 4)
for _, id in ipairs( { "x", "y", "z", "hl" } ) do
	cvars.AddChangeCallback( "zdev_r3d_gizmo_col_" .. id, function() R3D._RefreshColors() end, "zdev_r3d_gcol" )
end

-- Path: ZDEV.R3D.GizmoColor  (id "x"/"y"/"z"/"hl"/"w") — cached, alpha applied live
function R3D.GizmoColor( id )
	local c = R3D._gcol[ id ] or R3D._gcol.w
	c.a = math.Clamp( math.floor( R3D.VarN( "gizmo_alpha", 1 ) * 255 ), 0, 255 )
	return c
end

-- Path: ZDEV.R3D.GizmoWidth  — resolves the live gizmo line width for a size
function R3D.GizmoWidth( size )
	local w = size * R3D.VarN( "gizmo_thickness", 0.035 )
	if w < 0.4 then w = 0.4 end
	return w
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	AUTO-GENERATED SETTINGS PANEL  (built from the registry above)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Path: ZDEV.R3D.OpenSettings
function R3D.OpenSettings()
	if IsValid( R3D._setFrame ) then R3D._setFrame:Remove() end
	local f = vgui.Create( "DFrame" )
	f:SetSize( 340, 540 )
	f:Center()
	f:SetTitle( "ZDEV.R3D — Gizmo Appearance" )
	f:MakePopup()
	R3D._setFrame = f

	local reset = vgui.Create( "DButton", f )
	reset:Dock( BOTTOM )
	reset:SetTall( 26 )
	reset:SetText( "Reset to defaults" )

	local scroll = vgui.Create( "DScrollPanel", f )
	scroll:Dock( FILL )

	local function addRow( def )
		if def.kind == "bool" then
			local cb = vgui.Create( "DCheckBoxLabel", scroll )
			cb:Dock( TOP ) cb:DockMargin( 8, 8, 8, 0 )
			cb:SetText( def.help or def.s )
			cb:SetConVar( def.name )
			cb:SetValue( def.cvar:GetBool() )
		elseif def.kind == "color" then
			local lbl = vgui.Create( "DLabel", scroll )
			lbl:Dock( TOP ) lbl:DockMargin( 8, 10, 8, 0 )
			lbl:SetText( def.help or def.s )
			local mix = vgui.Create( "DColorMixer", scroll )
			mix:Dock( TOP ) mix:DockMargin( 8, 2, 8, 0 )
			mix:SetTall( 120 )
			mix:SetPalette( false ) mix:SetAlphaBar( false ) mix:SetWangs( true )
			local r, g, b = ParseRGB( def.cvar:GetString() )
			mix:SetColor( Color( r, g, b ) )
			mix.ValueChanged = function( _, col )
				RunConsoleCommand( def.name, col.r .. " " .. col.g .. " " .. col.b )
			end
		else
			local sl = vgui.Create( "DNumSlider", scroll )
			sl:Dock( TOP ) sl:DockMargin( 8, 8, 8, 0 )
			sl:SetText( def.s )
			sl:SetMin( def.min or 0 ) sl:SetMax( def.max or 1 ) sl:SetDecimals( def.dec or 2 )
			sl:SetConVar( def.name )
			sl:SetTooltip( def.help )
		end
	end

	for _, nm in ipairs( R3D.CONVAR_ORDER ) do addRow( R3D.CONVARS[ nm ] ) end

	reset.DoClick = function()
		for _, nm in ipairs( R3D.CONVAR_ORDER ) do
			RunConsoleCommand( nm, tostring( R3D.CONVARS[ nm ].d ) )
		end
		timer.Simple( 0, function() if IsValid( f ) then R3D.OpenSettings() end end )
	end
end

ZDEV.FILE.SetLoaded( _f )
