local _f = 'zdev/client/render/zd_cl_r3d_widget.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_r3d_widget.lua — ZDEV.R3D interactive gizmo controller
	Author: zcomstudios

	Grab-and-drag translate / rotate / scale gizmos. Hit-testing and drag
	math are screen-space (Vector:ToScreen), so this works identically in a
	world hook and inside a DModelPanel — no ScreenToLocal needed because
	ToScreen and input.GetCursorPos are both absolute.

	CALLER CONTRACT (two calls per frame):
	  1) inside the 3D pass  (PostDrawModel / PostDraw*Renderables):
	         gizmo:Draw( camPos )      -- draws + caches screen projections
	  2) in a 2D/think pass  (panel Think, HUDPaint, etc.):
	         gizmo:Input( mx, my, leftDown )   -- hover + drag, fires onChange
	     use gizmo:IsActive() to suppress your own camera-orbit while a handle
	     is hovered or being dragged.

	Config (ZDEV.R3D.NewGizmo{ ... }):
	  mode      "translate" | "rotate" | "scale"   (default translate)
	  pos, ang  initial transform
	  size      handle length / ring radius in world units (default 16)
	  space     "local" (axes follow ang) | "world"    (default local)
	  axes      { x=true, y=true, z=true }
	  pick      screen-space grab tolerance in px      (default 10)
	  onChange  function( pos, ang, self ) — fired while dragging
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.R3D = ZDEV.R3D or {}
local R3D = ZDEV.R3D

if ZDEV.FILE.Loaded( _f ) then return end

local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_deg  = math.deg

local GIZMO = R3D._GizmoMeta or {}
GIZMO.__index = GIZMO
R3D._GizmoMeta = GIZMO

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	2D screen-space math
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Shortest distance from point (px,py) to segment (ax,ay)-(bx,by).
local function DistToSeg( px, py, ax, ay, bx, by )
	local dx, dy = bx - ax, by - ay
	local l2 = dx * dx + dy * dy
	if l2 <= 0 then
		local ex, ey = px - ax, py - ay
		return math_sqrt( ex * ex + ey * ey )
	end
	local t = ( ( px - ax ) * dx + ( py - ay ) * dy ) / l2
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	local cx, cy = ax + dx * t, ay + dy * t
	local ex, ey = px - cx, py - cy
	return math_sqrt( ex * ex + ey * ey )
end

-- Shortest angular delta a-b in degrees, wrapped to (-180,180].
local function AngDiff( a, b )
	local d = ( a - b ) % 360
	if d > 180 then d = d - 360 end
	return d
end

local AXIS_ORDER = { "x", "y", "z" }

-- Planar (two-axis slide) handles for translate mode.
-- { id, axisA, axisB, tintAxis(perpendicular) }
local PLANE_LIST = {
	{ "xy", "x", "y", "z" },
	{ "yz", "y", "z", "x" },
	{ "xz", "x", "z", "y" },
}
local PLANE_AXES = { xy = { "x", "y" }, yz = { "y", "z" }, xz = { "x", "z" } }

-- Which axes a hot handle should light up (a plane lights its two axes; the
-- uniform centre lights all three).
local function AxisHot( g, id )
	local h = g._hot
	if not h then return false end
	if h == id then return true end
	if h == "uniform" then return true end
	local pa = PLANE_AXES[ h ]
	return pa ~= nil and ( pa[1] == id or pa[2] == id )
end

-- Resolve an axis colour live from the appearance convars, applying the hover
-- highlight when the axis is (directly or indirectly) hot.
local function AxisCol( g, id )
	if AxisHot( g, id ) and R3D.VarB( "gizmo_highlight", true ) then
		return R3D.GizmoColor( "hl" )
	end
	return R3D.GizmoColor( id )
end

-- Point-in-convex-quad via consistent edge-cross sign. q = { {x,y} x4 }.
local function PointInQuad( px, py, q )
	local sign
	for i = 1, 4 do
		local a = q[ i ]
		local b = q[ i % 4 + 1 ]
		local cross = ( b[1] - a[1] ) * ( py - a[2] ) - ( b[2] - a[2] ) * ( px - a[1] )
		if cross ~= 0 then
			local s = cross > 0
			if sign == nil then sign = s elseif sign ~= s then return false end
		end
	end
	return true
end

-- Reused fill colour for plane quads (no per-frame allocation).
local planeFill = Color( 255, 255, 255, 70 )

local function GetComp( v, axis )
	if axis == "x" then return v.x elseif axis == "y" then return v.y else return v.z end
end
local function SetComp( v, axis, val )
	if axis == "x" then v.x = val elseif axis == "y" then v.y = val else v.z = val end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CONSTRUCTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Path: ZDEV.R3D.NewGizmo
function R3D.NewGizmo( cfg )
	cfg = cfg or {}
	local g = setmetatable( {}, GIZMO )
	g.mode     = cfg.mode or "translate"
	g.pos      = cfg.pos and Vector( cfg.pos ) or Vector()
	g.ang      = cfg.ang and Angle( cfg.ang ) or Angle()
	g.scale    = cfg.scale and Vector( cfg.scale ) or Vector( 1, 1, 1 )
	g.size     = cfg.size or 16
	g.space    = cfg.space or "local"
	g.axes     = cfg.axes or { x = true, y = true, z = true }
	g.pick     = cfg.pick or 10
	g.onChange = cfg.onChange
	g._project = cfg.project   -- optional function(vec) -> x, y, visible

	g._proj  = {}      -- per-axis cached screen data from last Draw
	g._hot   = nil     -- currently hovered axis id
	g._drag  = nil     -- active drag state
	return g
end

function GIZMO:SetTransform( pos, ang )
	if pos then self.pos = Vector( pos ) end
	if ang then self.ang = Angle( ang ) end
end
function GIZMO:GetTransform() return self.pos, self.ang end
function GIZMO:GetScale() return self.scale end
function GIZMO:SetMode( m ) self.mode = m end
function GIZMO:IsDragging() return self._drag ~= nil end
function GIZMO:IsActive() return self._drag ~= nil or self._hot ~= nil end

-- Set how world points map to the cursor's coordinate space. For a DModelPanel,
-- pass function(v) local s=v:ToScreen(); local x,y=panel:ScreenToLocal(s.x,s.y);
-- return x,y,s.visible end  — and feed Input() the panel-local cursor.
function GIZMO:SetProjector( fn ) self._project = fn end

-- World -> hit-test space. Uses the projector when set, else absolute ToScreen.
function GIZMO:_ToScreen( v )
	local f = self._project
	if f then return f( v ) end
	local s = v:ToScreen()
	return s.x, s.y, s.visible
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	DRAW (3D pass) — draw handles, cache screen projections
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function GIZMO:Draw( camPos )
	local pos = self.pos
	local x, y, z = R3D.AxisDirs( self.ang, self.space )
	local dirs = { x = x, y = y, z = z }
	local proj = self._proj

	-- rebuild the active-handle id list each frame (mode switches drop stale ones)
	proj._ids = proj._ids or {}
	for i = #proj._ids, 1, -1 do proj._ids[ i ] = nil end

	-- centre screen point (shared by all handles)
	local cx, cy, cvis = self:_ToScreen( pos )
	proj._cx, proj._cy, proj._cvis = cx, cy, cvis

	local width = R3D.GizmoWidth( self.size )

	if self.mode == "rotate" then
		self:_DrawRotate( pos, dirs, width, proj )
	elseif self.mode == "scale" then
		self:_DrawScale( pos, dirs, width, proj )
	else
		self:_DrawTranslate( pos, dirs, width, proj )
	end
end

function GIZMO:_DrawTranslate( pos, dirs, width, proj )
	local ids = proj._ids
	R3D.Sphere( pos, math.max( width * 0.9, 0.6 ), R3D.GizmoColor( "w" ), 10 )

	-- single-axis arrows
	for _, id in ipairs( AXIS_ORDER ) do
		if self.axes[ id ] then
			local dir = dirs[ id ]
			local tip = pos + dir * self.size
			R3D.Arrow( pos, tip, AxisCol( self, id ), width )
			local tx, ty = self:_ToScreen( tip )
			local p = proj[ id ] or {}
			p.dir, p.tipx, p.tipy, p.kind = dir, tx, ty, "seg"
			proj[ id ] = p
			ids[ #ids + 1 ] = id
		end
	end

	-- two-axis slide planes
	local near = self.size * 0.32
	local far  = near + self.size * 0.26
	for _, pl in ipairs( PLANE_LIST ) do
		local id = pl[1]
		if self.axes[ pl[2] ] and self.axes[ pl[3] ] then
			local a, b = dirs[ pl[2] ], dirs[ pl[3] ]
			local c1 = pos + a * near + b * near
			local c2 = pos + a * far  + b * near
			local c3 = pos + a * far  + b * far
			local c4 = pos + a * near + b * far
			local hot = self._hot == id
			local col = hot and R3D.GizmoColor( "hl" ) or R3D.GizmoColor( pl[4] )
			planeFill.r, planeFill.g, planeFill.b = col.r, col.g, col.b
			planeFill.a = hot and 170 or 60
			R3D.Quad( c1, c2, c3, c4, planeFill )
			R3D.Line( c1, c2, col, width ) R3D.Line( c2, c3, col, width )
			R3D.Line( c3, c4, col, width ) R3D.Line( c4, c1, col, width )

			local p = proj[ id ] or {}
			p.kind, p.a, p.b = "plane", a, b
			p.scr = p.scr or { {}, {}, {}, {} }
			local sc = p.scr
			sc[1][1], sc[1][2] = self:_ToScreen( c1 )
			sc[2][1], sc[2][2] = self:_ToScreen( c2 )
			sc[3][1], sc[3][2] = self:_ToScreen( c3 )
			sc[4][1], sc[4][2] = self:_ToScreen( c4 )
			proj[ id ] = p
			ids[ #ids + 1 ] = id
		end
	end
end

function GIZMO:_DrawScale( pos, dirs, width, proj )
	local ids = proj._ids
	local hb  = Vector( width * 2, width * 2, width * 2 )

	-- centre cube = uniform-scale handle (lights all axes when hot)
	local uni = self._hot == "uniform"
	local ch  = math.max( width * 2.6, 1.2 )
	local chb = Vector( ch, ch, ch )
	R3D.Box( pos, self.ang, -chb, chb, uni and R3D.GizmoColor( "hl" ) or R3D.GizmoColor( "w" ) )
	local uc = proj.uniform or {}
	uc.kind, uc.cx, uc.cy, uc.rad = "center", proj._cx, proj._cy, math.max( self.pick, 11 )
	proj.uniform = uc
	ids[ #ids + 1 ] = "uniform"

	-- per-axis stalks + box handles
	for _, id in ipairs( AXIS_ORDER ) do
		if self.axes[ id ] then
			local dir = dirs[ id ]
			local tip = pos + dir * self.size
			local col = AxisCol( self, id )
			R3D.Line( pos, tip, col, width )
			R3D.Box( tip, self.ang, -hb, hb, col )
			local tx, ty = self:_ToScreen( tip )
			local p = proj[ id ] or {}
			p.dir, p.tipx, p.tipy, p.kind = dir, tx, ty, "seg"
			proj[ id ] = p
			ids[ #ids + 1 ] = id
		end
	end
end

function GIZMO:_DrawRotate( pos, dirs, width, proj )
	local SEG = 40
	local ids = proj._ids
	for _, id in ipairs( AXIS_ORDER ) do
		if self.axes[ id ] then
			local normal = dirs[ id ]
			local col = AxisCol( self, id )
			R3D.Ring( pos, normal, self.size, col, width, SEG )

			-- cache ring screen points for polyline hit-test
			local ax, ay = R3D.PlaneBasis( normal )
			local p = proj[ id ] or {}
			local pts = p.pts or {}
			local n = 0
			for i = 0, SEG do
				local t = ( i / SEG ) * math.pi * 2
				local wp = pos + ( ax * math.cos( t ) + ay * math.sin( t ) ) * self.size
				local sx, sy = self:_ToScreen( wp )
				n = n + 1
				pts[ n ] = pts[ n ] or {}
				pts[ n ][ 1 ] = sx
				pts[ n ][ 2 ] = sy
			end
			p.pts, p.n, p.dir, p.kind = pts, n, normal, "ring"
			proj[ id ] = p
			ids[ #ids + 1 ] = id
		end
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	INPUT (2D pass) — hover + drag
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Returns the handle id under the cursor, or nil. Plane handles win on a hit
-- (they sit near the centre, over the axis bases).
function GIZMO:_Pick( mx, my )
	local proj = self._proj
	local ids  = proj._ids
	if not ids then return nil end
	local best, bestD = nil, self.pick
	for _, id in ipairs( ids ) do
		local p = proj[ id ]
		if p then
			local k = p.kind
			if k == "plane" then
				if PointInQuad( mx, my, p.scr ) then return id end
			elseif k == "center" then
				local dx, dy = mx - ( p.cx or 0 ), my - ( p.cy or 0 )
				local d = math_sqrt( dx * dx + dy * dy )
				if d < ( p.rad or self.pick ) and d < bestD then best, bestD = id, d end
			elseif k == "ring" then
				local d = self.pick + 1
				for i = 1, p.n - 1 do
					local a, b = p.pts[ i ], p.pts[ i + 1 ]
					local dd = DistToSeg( mx, my, a[1], a[2], b[1], b[2] )
					if dd < d then d = dd end
				end
				if d < bestD then best, bestD = id, d end
			else
				local d = DistToSeg( mx, my, proj._cx or 0, proj._cy or 0, p.tipx or 0, p.tipy or 0 )
				if d < bestD then best, bestD = id, d end
			end
		end
	end
	return best
end

function GIZMO:Input( mx, my, down )
	-- drag in progress (routed by the grabbed handle's kind, not the mode)
	if self._drag then
		if not down then
			self._drag = nil
		else
			local k = self._drag.kind
			if k == "ring" then
				self:_DragRotate( mx, my )
			elseif k == "plane" then
				self:_DragPlane( mx, my )
			elseif k == "center" then
				self:_DragUniform( mx, my )
			else
				self:_DragTranslate( mx, my )
			end
			if self.onChange then self.onChange( self.pos, self.ang, self ) end
		end
		return true
	end

	-- idle: hover test, maybe begin drag
	self._hot = self:_Pick( mx, my )
	if self._hot and down then
		self:_BeginDrag( self._hot, mx, my )
		return true
	end
	return self._hot ~= nil
end

function GIZMO:_BeginDrag( id, mx, my )
	local proj = self._proj
	local p = proj[ id ]
	if not p then return end
	local cx, cy = proj._cx or mx, proj._cy or my
	local d = { axis = id, kind = p.kind, dir = p.dir, mx0 = mx, my0 = my }

	if p.kind == "ring" then
		d.cx, d.cy    = cx, cy
		d.lastMouse   = math_deg( math_atan2( my - cy, mx - cx ) )
		d.accum       = 0
		d.startAng    = Angle( self.ang )
	elseif p.kind == "center" then
		d.startScaleV = Vector( self.scale )
		d.startDist   = math_sqrt( ( mx - cx ) ^ 2 + ( my - cy ) ^ 2 )
	elseif p.kind == "plane" then
		d.startPos    = Vector( self.pos )
		d.a, d.b      = p.a, p.b
		d.size        = self.size
		local pa, pb  = PLANE_AXES[ id ][1], PLANE_AXES[ id ][2]
		local ta, tb  = proj[ pa ], proj[ pb ]
		d.sax, d.say  = ( ta and ta.tipx or cx ) - cx, ( ta and ta.tipy or cy ) - cy
		d.sbx, d.sby  = ( tb and tb.tipx or cx ) - cx, ( tb and tb.tipy or cy ) - cy
	else -- seg (single-axis translate or scale)
		d.startPos    = Vector( self.pos )
		d.sax, d.say  = ( p.tipx or cx ) - cx, ( p.tipy or cy ) - cy   -- screen axis for `size` units
		d.startScale  = self.size
		d.startComp   = GetComp( self.scale, id )
	end
	self._drag = d
end

-- slide on two axes: solve the 2x2 screen-space system for (tA, tB)
function GIZMO:_DragPlane( mx, my )
	local d = self._drag
	local ax, ay, bx, by = d.sax, d.say, d.sbx, d.sby
	local det = ax * by - bx * ay
	if math.abs( det ) < 1 then return end       -- axes near-colinear on screen (edge-on)
	local dx, dy = mx - d.mx0, my - d.my0
	local tA = ( dx * by - bx * dy ) / det
	local tB = ( ax * dy - dx * ay ) / det
	self.pos = d.startPos + d.a * ( tA * d.size ) + d.b * ( tB * d.size )
end

-- uniform scale: drag away from centre grows all axes, toward centre shrinks
function GIZMO:_DragUniform( mx, my )
	local d = self._drag
	local cx, cy = self._proj._cx or d.mx0, self._proj._cy or d.my0
	local cur = math_sqrt( ( mx - cx ) ^ 2 + ( my - cy ) ^ 2 )
	local factor = 1 + ( cur - d.startDist ) / 90
	if factor < 0.05 then factor = 0.05 end
	self.scale = d.startScaleV * factor
end

function GIZMO:_DragTranslate( mx, my )
	local d = self._drag
	local sax, say = d.sax, d.say
	local l2 = sax * sax + say * say
	if l2 <= 0 then return end
	local t = ( ( mx - d.mx0 ) * sax + ( my - d.my0 ) * say ) / l2  -- fraction of `size`
	if self.mode == "scale" then
		local factor = 1 + t
		if factor < 0.05 then factor = 0.05 end
		SetComp( self.scale, d.axis, d.startComp * factor )
	else
		self.pos = d.startPos + d.dir * ( t * d.startScale )
	end
end

function GIZMO:_DragRotate( mx, my )
	local d = self._drag
	local cur = math_deg( math_atan2( my - d.cy, mx - d.cx ) )
	d.accum   = d.accum + AngDiff( cur, d.lastMouse )
	d.lastMouse = cur
	local na = Angle( d.startAng )
	na:RotateAroundAxis( d.dir, d.accum )
	self.ang = na
end

ZDEV.FILE.SetLoaded( _f )
