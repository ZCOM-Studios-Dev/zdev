local _f = 'zdev/client/draw/zd_cl_draw_anim.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw_anim.lua  —  ZDEV.TWEEN (easing) + ZDEV.ANIM (animators)

	ZDEV.TWEEN  — value tweens with a full easing library. Create with
	              ZDEV.TWEEN.Tween(from, to, dur, easeFn) then call :Update().

	ZDEV.ANIM   — stateful, key-addressed animators for the common HUD needs
	              (fade in/out, slide, flicker, pulse, typewriter) that must
	              persist their progress across frames. State is stored in a
	              single registry so callers stay stateless:

	                  local a = ZDEV.ANIM.Fade( "my_panel", visible, 6 )   -- 0..1
	                  ZDEV.DRAW.Rect( x, y, w, h, ZDEV.DRAW.Alpha( clr, a*255 ) )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.TWEEN = ZDEV.TWEEN or {}
ZDEV.ANIM  = ZDEV.ANIM  or {}

local TWEEN = ZDEV.TWEEN
local ANIM  = ZDEV.ANIM

local sin, cos, pow, sqrt = math.sin, math.cos, math.pow, math.sqrt
local pi   = math.pi
local Clamp = math.Clamp
local Approach = math.Approach

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	EASING LIBRARY  (all take t in 0..1, return eased 0..1)
	Reference curves: https://easings.net
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function TWEEN.EaseLinear( t ) return t end

function TWEEN.EaseInQuad( t )    return t * t end
function TWEEN.EaseOutQuad( t )   return t * ( 2 - t ) end
function TWEEN.EaseInOutQuad( t ) return t < 0.5 and 2 * t * t or -1 + ( 4 - 2 * t ) * t end

function TWEEN.EaseInCubic( t )    return t * t * t end
function TWEEN.EaseOutCubic( t )   local u = t - 1 return u * u * u + 1 end
function TWEEN.EaseInOutCubic( t ) if t < 0.5 then return 4 * t * t * t else local u = 2 * t - 2 return 0.5 * u * u * u + 1 end end

function TWEEN.EaseInQuart( t )    return t * t * t * t end
function TWEEN.EaseOutQuart( t )   local u = t - 1 return 1 - u * u * u * u end
function TWEEN.EaseInOutQuart( t ) if t < 0.5 then return 8 * t * t * t * t else local u = t - 1 return 1 - 8 * u * u * u * u end end

function TWEEN.EaseInQuint( t )    return t ^ 5 end
function TWEEN.EaseOutQuint( t )   return 1 + ( t - 1 ) ^ 5 end
function TWEEN.EaseInOutQuint( t ) if t < 0.5 then return 16 * t ^ 5 else return 1 + 16 * ( t - 1 ) ^ 5 end end

function TWEEN.EaseInSine( t )    return 1 - cos( ( t * pi ) / 2 ) end
function TWEEN.EaseOutSine( t )   return sin( ( t * pi ) / 2 ) end
function TWEEN.EaseInOutSine( t ) return -( cos( pi * t ) - 1 ) / 2 end

function TWEEN.EaseInExpo( t )    return t == 0 and 0 or pow( 2, 10 * t - 10 ) end
function TWEEN.EaseOutExpo( t )   return t == 1 and 1 or 1 - pow( 2, -10 * t ) end
function TWEEN.EaseInOutExpo( t )
	if t == 0 then return 0 elseif t == 1 then return 1 end
	if t < 0.5 then return pow( 2, 20 * t - 10 ) / 2 else return ( 2 - pow( 2, -20 * t + 10 ) ) / 2 end
end

function TWEEN.EaseInCirc( t )    return 1 - sqrt( 1 - t * t ) end
function TWEEN.EaseOutCirc( t )   return sqrt( 1 - ( t - 1 ) ^ 2 ) end
function TWEEN.EaseInOutCirc( t )
	if t < 0.5 then return ( 1 - sqrt( 1 - ( 2 * t ) ^ 2 ) ) / 2 else return ( sqrt( 1 - ( -2 * t + 2 ) ^ 2 ) + 1 ) / 2 end
end

local c1, c3 = 1.70158, 2.70158
function TWEEN.EaseInBack( t )  return c3 * t * t * t - c1 * t * t end
function TWEEN.EaseOutBack( t ) local u = t - 1 return 1 + c3 * u * u * u + c1 * u * u end
function TWEEN.EaseInOutBack( t )
	local c2 = c1 * 1.525
	if t < 0.5 then return ( ( 2 * t ) ^ 2 * ( ( c2 + 1 ) * 2 * t - c2 ) ) / 2
	else return ( ( 2 * t - 2 ) ^ 2 * ( ( c2 + 1 ) * ( t * 2 - 2 ) + c2 ) + 2 ) / 2 end
end

function TWEEN.EaseInElastic( t )
	if t == 0 then return 0 elseif t == 1 then return 1 end
	return -pow( 2, 10 * t - 10 ) * sin( ( t * 10 - 10.75 ) * ( ( 2 * pi ) / 3 ) )
end
function TWEEN.EaseOutElastic( t )
	if t == 0 then return 0 elseif t == 1 then return 1 end
	return pow( 2, -10 * t ) * sin( ( t * 10 - 0.75 ) * ( ( 2 * pi ) / 3 ) ) + 1
end
function TWEEN.EaseInOutElastic( t )
	if t == 0 then return 0 elseif t == 1 then return 1 end
	local c5 = ( 2 * pi ) / 4.5
	if t < 0.5 then return -( pow( 2, 20 * t - 10 ) * sin( ( 20 * t - 11.125 ) * c5 ) ) / 2
	else return ( pow( 2, -20 * t + 10 ) * sin( ( 20 * t - 11.125 ) * c5 ) ) / 2 + 1 end
end

function TWEEN.EaseOutBounce( t )
	local n1, d1 = 7.5625, 2.75
	if t < 1 / d1 then return n1 * t * t
	elseif t < 2 / d1 then t = t - 1.5 / d1 return n1 * t * t + 0.75
	elseif t < 2.5 / d1 then t = t - 2.25 / d1 return n1 * t * t + 0.9375
	else t = t - 2.625 / d1 return n1 * t * t + 0.984375 end
end
function TWEEN.EaseInBounce( t )   return 1 - TWEEN.EaseOutBounce( 1 - t ) end
function TWEEN.EaseInOutBounce( t )
	if t < 0.5 then return ( 1 - TWEEN.EaseOutBounce( 1 - 2 * t ) ) / 2
	else return ( 1 + TWEEN.EaseOutBounce( 2 * t - 1 ) ) / 2 end
end

-- Resolve an easing argument that may be a function OR a string name ("OutCubic").
function TWEEN.Resolve( ease )
	if isfunction( ease ) then return ease end
	if isstring( ease ) then return TWEEN[ "Ease" .. ease ] or TWEEN.EaseLinear end
	return TWEEN.EaseLinear
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TWEEN OBJECT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local Tween = {}
Tween.__index = Tween

function Tween:Update()
	if not self.isActive then return self.End end
	local elapsed = CurTime() - self.startTime
	local progress = Clamp( elapsed / self.duration, 0, 1 )
	if progress >= 1 then
		self.isActive = false
		if self.onDone then self.onDone() end
		return self.End
	end
	return Lerp( self.ease( progress ), self.start, self.End )
end

function Tween:IsActive() return self.isActive end

function Tween:Reset()
	self.startTime = CurTime()
	self.isActive = true
	return self
end

function Tween:Retarget( newEnd )
	self.start = self:Update()
	self.End = newEnd
	self:Reset()
	return self
end

-- Create a tween. easeFunc may be a function or an easing name string.
function TWEEN.Tween( startValue, endValue, duration, easeFunc, onDone )
	return setmetatable( {
		start     = startValue,
		End       = endValue,
		duration  = duration or 1,
		startTime = CurTime(),
		ease      = TWEEN.Resolve( easeFunc ),
		onDone    = onDone,
		isActive  = true,
	}, Tween )
end

TWEEN._activeTweens = TWEEN._activeTweens or {}

function TWEEN.Add( tween )
	TWEEN._activeTweens[ #TWEEN._activeTweens + 1 ] = tween
	return tween
end

function TWEEN.UpdateAll()
	local list = TWEEN._activeTweens
	local i = 1
	while i <= #list do
		if list[ i ]:IsActive() then list[ i ]:Update() ; i = i + 1
		else table.remove( list, i ) end
	end
end

function TWEEN.ClearAll() TWEEN._activeTweens = {} end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ANIM  —  key-addressed stateful animators
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
ANIM._state = ANIM._state or {}

-- Linearly approach `target` from the value last stored at `key`, moving at a
-- constant `rate` units/second. Frame-rate independent. Returns the new value.
function ANIM.Value( key, target, rate )
	local s = ANIM._state
	local cur = s[ key ]
	if cur == nil then cur = target end
	cur = Approach( cur, target, ( rate or 100 ) * FrameTime() )
	s[ key ] = cur
	return cur
end

-- Exponential smoothing toward target (nicer than linear Approach for UI).
-- `speed` ~ how fast it converges (higher = snappier). Returns smoothed value.
function ANIM.Smooth( key, target, speed )
	local s = ANIM._state
	local cur = s[ key ]
	if cur == nil then cur = target end
	cur = Lerp( Clamp( ( speed or 8 ) * FrameTime(), 0, 1 ), cur, target )
	s[ key ] = cur
	return cur
end

-- Fade helper: returns a 0..1 alpha fraction that eases toward 1 when `shown`
-- is truthy and toward 0 otherwise. `speed` (default 6) controls the rate.
function ANIM.Fade( key, shown, speed )
	return ANIM.Smooth( "fade:" .. key, shown and 1 or 0, speed or 6 )
end

-- Slide helper: smoothed scalar position toward `target` (e.g. an X offset).
function ANIM.Slide( key, target, speed )
	return ANIM.Smooth( "slide:" .. key, target, speed or 10 )
end

-- Sine pulse between lo and hi at `speed` Hz-ish. Stateless (time-based).
function ANIM.Pulse( speed, lo, hi )
	lo = lo or 0 ; hi = hi or 1
	return lo + ( hi - lo ) * ( 0.5 + 0.5 * sin( RealTime() * ( speed or 2 ) ) )
end

-- Square blink: returns true/false toggling at `speed` Hz.
function ANIM.Blink( speed )
	return sin( RealTime() * ( speed or 4 ) ) > 0
end

-- Random flicker fraction (0..1). `stability` 0..1: higher = steadier.
-- Persists per key so it doesn't strobe every frame; refreshes ~30/s.
function ANIM.Flicker( key, stability )
	local s = ANIM._state
	local rec = s[ "flick:" .. key ]
	local now = RealTime()
	if not rec or now - rec.t > 0.033 then
		local base = stability or 0.5
		rec = { t = now, v = Clamp( base + ( 1 - base ) * ( math.random() ), 0, 1 ) }
		s[ "flick:" .. key ] = rec
	end
	return rec.v
end

-- One-shot timeline: given a start stamp and duration, returns eased 0..1
-- progress. Useful for intro/outro sweeps without allocating a tween object.
function ANIM.Progress( startTime, duration, ease )
	local p = Clamp( ( CurTime() - startTime ) / ( duration or 1 ), 0, 1 )
	return TWEEN.Resolve( ease )( p )
end

-- Per-channel smoothed colour toward `target`. Returns a persistent Color that is
-- mutated in place each frame (technique from HUD Mk.2 Nene.LerpColor). `speed`
-- ~ convergence rate (default 8). Great for state-based tints that must not pop.
function ANIM.SmoothColor( key, target, speed )
	local s = ANIM._state
	local k = "col:" .. key
	local cur = s[ k ]
	if not cur then
		cur = Color( target.r, target.g, target.b, target.a or 255 )
		s[ k ] = cur
		return cur
	end
	local f = Clamp( ( speed or 8 ) * FrameTime(), 0, 1 )
	cur.r = cur.r + ( target.r - cur.r ) * f
	cur.g = cur.g + ( target.g - cur.g ) * f
	cur.b = cur.b + ( target.b - cur.b ) * f
	cur.a = cur.a + ( ( target.a or 255 ) - cur.a ) * f
	return cur
end

-- Asymmetric attack/decay envelope (technique from HoloHUD2's blur glow): while
-- `active`, rise toward 1 over `attack` seconds; otherwise fall toward 0 over
-- `decay` seconds. Optional `floor` raises the idle minimum. Returns 0..1.
-- Use for glows/highlights that flare fast and fade slow.
function ANIM.Envelope( key, active, attack, decay, floorV )
	local s = ANIM._state
	local k = "env:" .. key
	local cur = s[ k ] or 0
	local dt = FrameTime()
	if active then
		cur = cur + dt / ( attack or 0.1 )
		if cur > 1 then cur = 1 end
	else
		cur = cur - dt / ( decay or 1 )
		if cur < 0 then cur = 0 end
	end
	s[ k ] = cur
	if floorV then return floorV + cur * ( 1 - floorV ) end
	return cur
end

-- Panel deploy/retract progress (technique from HoloHUD2 AnimatedPanel): rises
-- over `deployT` when `shown`, falls over `retractT` when hidden — asymmetric so
-- open snaps and close eases out. Optional `ease` (fn or name) shapes the result.
-- Pair with a scissor/alpha to build a reveal. Returns 0..1.
function ANIM.Reveal( key, shown, deployT, retractT, ease )
	local s = ANIM._state
	local k = "reveal:" .. key
	local cur = s[ k ]
	if cur == nil then cur = shown and 1 or 0 end
	local dt = FrameTime()
	if shown then
		cur = cur + dt / ( deployT or 0.18 )
		if cur > 1 then cur = 1 end
	else
		cur = cur - dt / ( retractT or 0.35 )
		if cur < 0 then cur = 0 end
	end
	s[ k ] = cur
	if ease then return TWEEN.Resolve( ease )( cur ) end
	return cur
end

-- Smoothed "rolling" number toward `value` (odometer feel). Returns the smoothed
-- number, and — if `fmt` is given — a formatted string as the first return value.
function ANIM.RollNumber( key, value, speed, fmt )
	local v = ANIM.Smooth( "roll:" .. key, value, speed or 8 )
	if fmt then return string.format( fmt, v ), v end
	return v
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HUD SWAY / PARALLAX  (DepthHUD-inspired; techniques from HoloHUD2 sway.lua
	and Smart Vision's eye-lag). Returns an (x,y) pixel offset that lags the
	player's view — add it (scaled) to panel positions so the HUD floats.

		local dx, dy = ZDEV.ANIM.Sway( 1 )      -- mode 2 (camera + movement)
		DrawPanel( x + dx * 0.3, y + dy * 0.3 )  -- 0.3 = parallax depth

	Computed once per frame (guarded) so many callers share one consistent sway.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local SWAY_CAMERA, SWAY_MOVEMENT, SWAY_HEADBOB = 1, 2, 3
ANIM.SWAY_CAMERA   = SWAY_CAMERA
ANIM.SWAY_MOVEMENT = SWAY_MOVEMENT
ANIM.SWAY_HEADBOB  = SWAY_HEADBOB
ANIM._sway = ANIM._sway or { camx = 0, camy = 0, movx = 0, movy = 0, bob = 0, last = nil, frame = -1, rx = 0, ry = 0 }

local AngleDifference = math.AngleDifference

function ANIM.Sway( mul, speed, mode )
	mul   = mul or 1
	speed = speed or 1
	mode  = mode or SWAY_MOVEMENT
	local sw = ANIM._sway
	local fn = FrameNumber()
	if sw.frame == fn then return sw.rx, sw.ry end       -- once per frame; shared
	sw.frame = fn

	local ply = LocalPlayer()
	if not IsValid( ply ) then return sw.rx, sw.ry end
	local dt = FrameTime()

	-- camera-based sway (smoothed frame-to-frame view delta)
	local ang = ply:EyeAngles()
	if not sw.last then sw.last = ang end
	local x = AngleDifference( ang.y, sw.last.y ) * mul
	local y = -AngleDifference( ang.p, sw.last.p ) * mul
	local sp = Clamp( dt * 8 * speed, 0, 1 )
	sw.camx = sw.camx + ( x - sw.camx ) * sp
	sw.camy = sw.camy + ( y - sw.camy ) * sp
	sw.last = ang

	if mode == SWAY_CAMERA then
		sw.rx, sw.ry = sw.camx, sw.camy
		return sw.rx, sw.ry
	end

	-- movement-based sway (strafe + fall velocity)
	local vel = ply:GetVelocity()
	local strafe = -vel:Dot( ply:GetAngles():Right() ) / 128
	local fall   = vel.z / 128
	sw.movx = Lerp( Clamp( dt * 8, 0, 1 ), sw.movx, Clamp( strafe, -5, 5 ) * mul )
	sw.movy = Lerp( Clamp( dt * 8, 0, 1 ), sw.movy, math.min( fall, 5 ) * mul )

	-- head bobbing
	if mode == SWAY_HEADBOB and ply:OnGround() and not ply:InVehicle() then
		local vl = math.min( vel:Length() / 350, 1 )
		sw.camx = sw.camx + sin( sw.bob * 3 ) * 0.45 * vl
		sw.camy = sw.camy + sin( sw.bob * 9 ) * 0.45 * vl
		sw.bob = sw.bob + dt * Lerp( vl, 1, 2.5 ) * speed
	end

	sw.rx, sw.ry = sw.camx + sw.movx, sw.camy + sw.movy
	return sw.rx, sw.ry
end

-- Clear stored animator state (all, or a single key prefix).
function ANIM.Clear( key )
	if key then
		for k in pairs( ANIM._state ) do
			if k == key or string.StartWith( k, key ) then ANIM._state[ k ] = nil end
		end
	else
		ANIM._state = {}
	end
end

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )
