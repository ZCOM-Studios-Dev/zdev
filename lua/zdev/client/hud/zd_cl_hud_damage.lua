--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_hud_damage.lua  —  ZDEV.CHUD.DMG  (Visor damage / overlay effects)

	A severity-driven overlay stack rendered ON the visor glass and parented to
	it (rides CHUD.GlassOffset() so cracks/blood/etc. move with the visor). Two
	input paths feed a set of decaying "channels":

	  · Health-driven (automatic): a client-side watcher raises `physical` and
	    `blood` on health loss, with a low-health floor.
	  · Event-driven (gameplay): ZDEV.CHUD.DMG.Hit( channel, amount ) — called
	    locally, or from the server via ZDEV.SendVisorDamage( ply, ch, amt )
	    (net "zdev_hud_visor_dmg") for hacking / signal-jamming / shock events.

	Channels decay over time, so effects fade unless re-hit; multiple hot
	channels overlap. Each channel drives one or more LAYERS:

	  · sprite  — PNG/VTF decals under materials/visor/dmg/<channel>_<nn>.*
	              (auto-discovered; drop a file in, no code needed). Variants
	              cross-fade in as the channel level rises (damage "spreads").
	  · fx      — procedural, built on ZDEV.DRAW.FX (electrical arcs, digital
	              glitch/distortion, signal static). Frequency/intensity scale
	              with the channel level.
	  · tint    — the whole-glass damaged tint, keyed to total severity.

	Everything is convar-tunable/toggleable per gmod-convar-registry:
	  zdev_hud_visor_dmg            master on/off (CHUD element visibility)
	  zdev_hud_visor_dmg_intensity  global intensity multiplier (0..2)
	  zdev_hud_visor_dmg_decay      global decay-rate multiplier (0..4)
	  zdev_hud_visor_dmg_health     health-driven auto damage (0/1)
	  zdev_hud_visor_dmg_<channel>  per-channel intensity (0..2)

	Test:   zdev_hud_visor_dmg_test <channel> [amount]   /   ..._dmg_clear
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local _f = 'zdev/client/hud/zd_cl_hud_damage.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

ZDEV.CHUD = ZDEV.CHUD or {}
local CHUD = ZDEV.CHUD
CHUD.DMG   = CHUD.DMG or {}
local DMG  = CHUD.DMG

--[[ ─── Channel definitions (ordered) — decay is level lost per second ─── ]]
-- Sprite channels (physical/blood/dust/fluid) also accept auto-discovered
-- decals; procedural channels (electrical/digital/signal) drive FX layers.
DMG.ChannelOrder = { "physical", "blood", "dust", "fluid", "electrical", "digital", "signal" }
DMG.ChannelDef   = {
	physical   = { decay = 0.20, label = "Cracked Glass" },
	blood      = { decay = 0.12, label = "Blood Spatter" },
	dust       = { decay = 0.05, label = "Dust / Debris" },
	fluid      = { decay = 0.10, label = "Fluid / Water" },
	electrical = { decay = 0.90, label = "Electrical Arc" },
	digital    = { decay = 1.10, label = "Digital Glitch" },
	signal     = { decay = 0.55, label = "Signal Jam" },
}
-- fast set lookup (auto-discovery only registers sprites for known channels)
DMG.Channels = {}
for _, ch in ipairs( DMG.ChannelOrder ) do DMG.Channels[ ch ] = true end

--[[ ─── Convars (idempotent; BEFORE the reload guard) ─── ]]
ZDEV.CONV.ClientVar( "zdev_hud_visor_dmg",           "1",   "Master toggle: visor damage / overlay effects (0/1)" )
ZDEV.CONV.ClientVar( "zdev_hud_visor_dmg_intensity", "1.0", "Global intensity multiplier for all visor damage effects", { } )
ZDEV.CONV.ClientVar( "zdev_hud_visor_dmg_decay",     "1.0", "Global decay-rate multiplier (higher = effects fade faster)" )
ZDEV.CONV.ClientVar( "zdev_hud_visor_dmg_health",    "1",   "Drive physical/blood damage from health loss (0/1)" )
for _, ch in ipairs( DMG.ChannelOrder ) do
	ZDEV.CONV.ClientVar( "zdev_hud_visor_dmg_" .. ch, "1.0",
		"Per-channel intensity for visor '" .. ch .. "' damage (0 disables)" )
end

--[[ ─── Test / debug concommands (BEFORE the guard per gmod-file-load-order) ─── ]]
if ZDEV.CMDS and ZDEV.CMDS.Register then
	ZDEV.CMDS.Register( "zdev_hud_visor_dmg_test", function( ply, cmd, args )
		local ch  = tostring( args[ 1 ] or "" ):lower()
		local amt = tonumber( args[ 2 ] ) or 0.6
		if not DMG.Channels[ ch ] then
			MsgC( Color( 255, 120, 120 ), "[ZDEV] Unknown channel '" .. ch .. "'. Valid: "
				.. table.concat( DMG.ChannelOrder, ", " ) .. "\n" )
			return
		end
		DMG.Hit( ch, amt )
	end, {
		help = "Inject visor damage: zdev_hud_visor_dmg_test <channel> [amount]",
		autocomplete = function( cmd, argStr )
			local out = {}
			for _, ch in ipairs( DMG.ChannelOrder ) do out[ #out + 1 ] = cmd .. " " .. ch end
			return out
		end,
	} )

	ZDEV.CMDS.Register( "zdev_hud_visor_dmg_clear", function()
		DMG.Clear()
	end, { help = "Clear all visor damage channels" } )
end

if ZDEV.FILE.Loaded( _f ) then return end

local DRAW = ZDEV.DRAW
local FX   = ZDEV.DRAW.FX
local Clamp = math.Clamp
local floor = math.floor
local max   = math.max
local Rand  = math.Rand
local rand  = math.random
local surface = surface

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	STATE  +  PUBLIC API
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
DMG.State = DMG.State or {}                   -- channel -> level (0..1)
for _, ch in ipairs( DMG.ChannelOrder ) do DMG.State[ ch ] = DMG.State[ ch ] or 0 end
DMG.State.severity = DMG.State.severity or 0  -- derived (max of channels)

-- Raise a channel's level. amount may be negative to relieve it.
function DMG.Hit( channel, amount )
	channel = tostring( channel or "" ):lower()
	if not DMG.Channels[ channel ] then return end
	DMG.State[ channel ] = Clamp( ( DMG.State[ channel ] or 0 ) + ( tonumber( amount ) or 0 ), 0, 1 )
end

function DMG.Get( channel )
	return DMG.State[ channel ] or 0
end

function DMG.Set( channel, level )
	channel = tostring( channel or "" ):lower()
	if not DMG.Channels[ channel ] then return end
	DMG.State[ channel ] = Clamp( tonumber( level ) or 0, 0, 1 )
end

function DMG.Clear()
	for _, ch in ipairs( DMG.ChannelOrder ) do DMG.State[ ch ] = 0 end
	DMG.State.severity = 0
end

-- cached convar handles (the master on/off is the CHUD element's visibility
-- convar "zdev_hud_visor_dmg", enforced by CHUD.IsElementVisible)
local cvIntensity = GetConVar( "zdev_hud_visor_dmg_intensity" )
local cvDecay     = GetConVar( "zdev_hud_visor_dmg_decay" )
local cvHealth    = GetConVar( "zdev_hud_visor_dmg_health" )
local cvChannel   = {}
for _, ch in ipairs( DMG.ChannelOrder ) do cvChannel[ ch ] = GetConVar( "zdev_hud_visor_dmg_" .. ch ) end

local function channelMult( ch )
	local cv = cvChannel[ ch ]
	return cv and cv:GetFloat() or 1
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	UPDATE  —  decay + health-driven auto damage (Think, cheap)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
DMG._lastHP = nil

function DMG.Update( ft )
	local decayMult = ( cvDecay and cvDecay:GetFloat() or 1 )
	for _, ch in ipairs( DMG.ChannelOrder ) do
		local lvl = DMG.State[ ch ]
		if lvl > 0 then
			local def = DMG.ChannelDef[ ch ]
			DMG.State[ ch ] = max( 0, lvl - def.decay * decayMult * ft )
		end
	end

	local LP = LocalPlayer()
	if IsValid( LP ) and LP:IsPlayer() and LP:Alive() and cvHealth and cvHealth:GetBool() then
		local hp    = LP:Health()
		local maxhp = LP:GetMaxHealth()
		if not ( maxhp and maxhp > 0 ) then maxhp = 100 end

		if DMG._lastHP == nil then DMG._lastHP = hp end
		if hp < DMG._lastHP then
			local frac = ( DMG._lastHP - hp ) / maxhp
			DMG.Hit( "physical", frac * 1.2 )
			DMG.Hit( "blood",    frac * 1.5 )
		end
		DMG._lastHP = hp

		-- low-health floor: sustained cracks/blood while critically wounded
		local ratio = hp / maxhp
		if ratio < 0.35 then
			local floorLvl = ( 0.35 - ratio ) / 0.35
			if DMG.State.physical < floorLvl * 0.6 then DMG.State.physical = floorLvl * 0.6 end
			if DMG.State.blood    < floorLvl * 0.4 then DMG.State.blood    = floorLvl * 0.4 end
		end
	else
		DMG._lastHP = nil   -- reset on death/respawn so a full-heal spawn doesn't spike
	end

	-- derived severity (drives the base damaged-glass tint)
	local sev = 0
	for _, ch in ipairs( DMG.ChannelOrder ) do
		if DMG.State[ ch ] > sev then sev = DMG.State[ ch ] end
	end
	DMG.State.severity = sev
end

hook.Add( "Think", "ZDEV.CHUD.DMG.Update", function()
	DMG.Update( FrameTime() )
end )

-- server-pushed typed damage (hacking / jamming / shock)
net.Receive( "zdev_hud_visor_dmg", function()
	local ch  = net.ReadString()
	local amt = net.ReadFloat()
	DMG.Hit( ch, amt )
end )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LAYER REGISTRY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
DMG.Layers = DMG.Layers or {}
local layerSorted, layerDirty = {}, true

-- def = { channel, threshold=0.05, order=50, draw = function( ctx, eff ) ... end }
-- ctx = { sw, sh, grx, gry, gw, gh }  (glass rect, glass-offset already baked in)
-- eff = effective level = state * channelMult * globalIntensity (>=0, may exceed 1)
function DMG.RegisterLayer( id, def )
	def.id        = id
	def.threshold = def.threshold or 0.05
	def.order     = def.order or 50
	DMG.Layers[ id ] = def
	layerDirty = true
end

local function rebuildLayers()
	layerSorted = {}
	for id in pairs( DMG.Layers ) do layerSorted[ #layerSorted + 1 ] = id end
	table.sort( layerSorted, function( a, b )
		local da, db = DMG.Layers[ a ], DMG.Layers[ b ]
		if da.order == db.order then return a < b end
		return da.order < db.order
	end )
	layerDirty = false
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SPRITE AUTO-DISCOVERY  —  materials/visor/dmg/<channel>_<nn>.(png|vtf)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local spriteClr = Color( 255, 255, 255, 255 )

local function makeSpriteLayer( channel, materials, order )
	local n = #materials
	DMG.RegisterLayer( "sprite_" .. channel, {
		channel   = channel,
		threshold = 0.02,
		order     = order or 20,
		draw = function( ctx, eff )
			-- variants cross-fade in sequence as the level climbs (spread)
			for i = 1, n do
				local vis = Clamp( ( eff - ( i - 1 ) / n ) * n, 0, 1 )
				if vis > 0.01 then
					spriteClr.a = floor( Clamp( vis, 0, 1 ) * 255 )
					DRAW.TexturedRect( ctx.grx, ctx.gry, ctx.gw, ctx.gh, materials[ i ], spriteClr )
				end
			end
		end,
	} )
end

function DMG.DiscoverSprites()
	local files = {}
	for _, ext in ipairs( { "png", "vtf" } ) do
		for _, fn in ipairs( file.Find( "materials/visor/dmg/*." .. ext, "GAME" ) or {} ) do
			files[ #files + 1 ] = fn
		end
	end

	local byChannel = {}
	for _, fn in ipairs( files ) do
		local base = fn:gsub( "%.png$", "" ):gsub( "%.vtf$", "" )
		local ch   = base:match( "^(%a+)_%d+$" ) or base:match( "^(%a+)" )
		if ch and DMG.Channels[ ch ] then
			-- PNG materials must keep the .png extension; VTFs drop it.
			local path = "visor/dmg/" .. fn:gsub( "%.vtf$", "" )
			byChannel[ ch ] = byChannel[ ch ] or {}
			byChannel[ ch ][ #byChannel[ ch ] + 1 ] = path
		end
	end

	local count = 0
	for ch, paths in pairs( byChannel ) do
		table.sort( paths )
		local mats = {}
		for i, path in ipairs( paths ) do mats[ i ] = Material( path, "noclamp smooth" ) end
		makeSpriteLayer( ch, mats, 20 )
		count = count + #mats
	end
	return count
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	BASE DAMAGED-GLASS TINT  (keyed to total severity)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local matDmgGlow = Material( "visor/visor_holo_glow_dmg.png" )
local tintClr    = Color( 255, 255, 255, 0 )

DMG.RegisterLayer( "base_tint", {
	channel   = "severity",
	threshold = 0.03,
	order     = 5,   -- under everything else
	draw = function( ctx, eff )
		tintClr.a = floor( Clamp( eff, 0, 1 ) * 90 )
		DRAW.TexturedRect( ctx.grx, ctx.gry, ctx.gw, ctx.gh, matDmgGlow, tintClr )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PROCEDURAL FX LAYERS  (electrical / digital / signal)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- Jagged electrical arc between two points (random-walk polyline).
local function drawArc( x1, y1, x2, y2, clr, segs, jitter )
	segs = segs or 6
	surface.SetDrawColor( clr.r, clr.g, clr.b, clr.a )
	local px, py = x1, y1
	for i = 1, segs do
		local t  = i / segs
		local nx = ( x1 + ( x2 - x1 ) * t ) + ( i < segs and Rand( -jitter, jitter ) or 0 )
		local ny = ( y1 + ( y2 - y1 ) * t ) + ( i < segs and Rand( -jitter, jitter ) or 0 )
		surface.DrawLine( px, py, nx, ny )
		px, py = nx, ny
	end
end

local arcClr  = Color( 180, 220, 255, 255 )
local arcCore = Color( 255, 255, 255, 255 )

-- ELECTRICAL — flickering sparks/arcs skittering across the glass.
DMG.RegisterLayer( "fx_electrical", {
	channel   = "electrical",
	threshold = 0.05,
	order     = 60,
	draw = function( ctx, eff )
		local n = floor( Clamp( eff, 0, 1 ) * 6 + 0.5 )
		for _ = 1, n do
			local x1 = ctx.grx + rand( 0, ctx.gw )
			local y1 = ctx.gry + rand( 0, ctx.gh )
			local len = 40 + eff * 120
			local x2 = x1 + Rand( -len, len )
			local y2 = y1 + Rand( -len, len )
			local a  = floor( Clamp( eff, 0, 1 ) * 200 + 40 )
			arcClr.a  = a
			arcCore.a = a
			drawArc( x1, y1, x2, y2, arcClr, 7, 10 )
			drawArc( x1, y1, x2, y2, arcCore, 7, 4 )
			if rand() < 0.4 then FX.Glow( x2, y2, 26, arcClr ) end
		end
	end,
} )

-- DIGITAL — intermittent glitch/distortion of the whole display (internal
-- screen damage). Bursts gate on a time cycle so it's not constant.
DMG.RegisterLayer( "fx_digital", {
	channel   = "digital",
	threshold = 0.05,
	order     = 70,
	draw = function( ctx, eff )
		local e = Clamp( eff, 0, 1 )
		-- burst window widens with intensity (RealTime cycle ~0.6s)
		local phase = ( RealTime() % 0.6 ) / 0.6
		if phase < 0.15 + e * 0.5 then
			FX.Glitch( ctx.grx, ctx.gry, ctx.gw, ctx.gh, e )
		end
		-- mild continuous wobble + scanlines even between bursts
		FX.Distort( ctx.grx, ctx.gry, ctx.gw, ctx.gh, 2 + e * 6, 6, 3, 0.05 )
		FX.Scanlines( ctx.grx, ctx.gry, ctx.gw, ctx.gh, 3, Color( 0, 0, 0, floor( e * 70 ) ), 30 )
	end,
} )

-- SIGNAL — jamming/interference: static speckle + rolling scanlines + occasional
-- horizontal desync.
DMG.RegisterLayer( "fx_signal", {
	channel   = "signal",
	threshold = 0.05,
	order     = 65,
	draw = function( ctx, eff )
		local e = Clamp( eff, 0, 1 )
		FX.Noise( ctx.grx, ctx.gry, ctx.gw, ctx.gh, e * 0.18, 2 )
		FX.Scanlines( ctx.grx, ctx.gry, ctx.gw, ctx.gh, 4, Color( 0, 0, 0, floor( e * 90 ) ), 60 )
		if e > 0.55 and ( RealTime() % 0.4 ) < 0.08 then
			FX.Distort( ctx.grx, ctx.gry, ctx.gw, ctx.gh, e * 24, 3, 6, 0.03 )
		end
	end,
} )

-- discover any sprite decals present now (safe to call again after adding files)
DMG.DiscoverSprites()

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PAINT  —  registered as a fullscreen CHUD element (rides the glass offset,
	drawn above the data HUD so display-glitch corrupts the readouts too).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local _ctx = { sw = 0, sh = 0, grx = 0, gry = 0, gw = 0, gh = 0 }

function DMG.Paint( self, sw, sh, p )
	if CHUD.EditorActive then return end          -- never overlay the HUD editor
	local gI = cvIntensity and cvIntensity:GetFloat() or 1

	-- glass rect (matches the visor element's own scale/aspect + shared drift)
	local scale  = CHUD.CV.scale:GetFloat()
	local aspect = CHUD.CV.aspect:GetFloat()
	local gx, gy = CHUD.GlassOffset()
	local gw = sw * scale
	local gh = sh * ( scale * aspect )
	_ctx.sw, _ctx.sh = sw, sh
	_ctx.gw, _ctx.gh = gw, gh
	_ctx.grx = ( sw - gw ) * 0.5 + gx
	_ctx.gry = ( sh - gh ) * 0.5 + gy

	if layerDirty then rebuildLayers() end
	for i = 1, #layerSorted do
		local def = DMG.Layers[ layerSorted[ i ] ]
		local eff = ( DMG.State[ def.channel ] or 0 ) * channelMult( def.channel ) * gI
		if eff > def.threshold then
			def.draw( _ctx, eff )
		end
	end
end

CHUD.Register( "visordmg", {
	label      = "VISOR DAMAGE",
	convar     = "zdev_hud_visor_dmg",
	fullscreen = true,
	noEditor   = true,
	order      = 88,        -- above the data HUD (40), below dev/editmode (90/95)
	Paint      = DMG.Paint,
} )

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )
