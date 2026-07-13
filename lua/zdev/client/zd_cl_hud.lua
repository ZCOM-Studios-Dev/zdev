--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_hud.lua  —  ZDEV.CHUD  (Custom HUD framework — CORE)
	Author:      zcomstudios
	Description: Registry-driven, profile-persisted, editor-aware HUD pipeline.

	CHUD v2 replaces the legacy monolithic painters with a component system:

	  · ZDEV.CHUD.Register( id, def )  — declare a HUD element once; the core
	    handles anchoring, scaling, rotation, parallax, fade, visibility convar,
	    parameter schema and persistence.
	  · Elements draw in LOCAL space (0,0 .. w,h). The pipeline positions them
	    via a single model matrix per element (anchor + offset + rotation +
	    scale + parallax) so the editor can move/scale anything live.
	  · Layout + per-element parameters persist as JSON profiles in
	    data/zdev/hud/. The "_active" profile autoloads and autosaves.
	  · The in-game HUD Editor (zdev_edit_hud_toggle / zd_cl_menu_editor_hud.lua)
	    manipulates ZDEV.CHUD.Layout directly — everything here is live-read.

	Hot-path rules honoured (glua-2d-drawing Rule 5): convar handles, materials,
	matrices, vectors and angles are cached; no per-frame allocations in the
	pipeline itself.

	Built-in elements live in  zdev/client/hud/zd_cl_hud_elements.lua.
	The editor UI lives in     zdev/client/menu/zd_cl_menu_editor_hud.lua.

	PRESERVED PUBLIC API (consumed by zd_cl_hud_msg / zd_cl_hud_pickup / others):
	  ZDEV.CHUD.UpdateHUDOffset(), ZDEV.CHUD.GetParallax( name ),
	  ZDEV.CHUD.PushParallax( name ), ZDEV.CHUD.PushParallaxRotated( ... ),
	  ZDEV.CHUD.PopParallax(), ZDEV.CHUD.Paint, ZDEV.CHUD.HideDefault,
	  ZDEV.CHUD.Targets (legacy table, kept so nothing nils out).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local _f = 'zdev/client/zd_cl_hud.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[ ─── Convars (idempotent; BEFORE the reload guard per gmod-file-load-order) ─ ]]
-- Visor / parallax / curve tuning (canonical zdev_* names, legacy zd_* mirrors)
ZDEV.CONV.ClientVar("zdev_hud_visor_ang_strength", "15",   "Pixels of visor offset per degree of mouse movement", { legacy = "zd_hud_visor_ang_strength" })
ZDEV.CONV.ClientVar("zdev_hud_visor_ang_speed",    "20",   "Angle-smear lerp speed (higher = snappier, lower = more lag)", { legacy = "zd_hud_visor_ang_speed" })
ZDEV.CONV.ClientVar("zdev_hud_visor_scale",        "1.25", "Visor texture scale (>1.0 hides edges as it shifts)", { legacy = "zd_hud_visor_scale" })
ZDEV.CONV.ClientVar("zdev_hud_visor_aspect",       "0.85", "Visor height multiplier (relative to scale)", { legacy = "zd_hud_visor_aspect" })
ZDEV.CONV.ClientVar("zdev_hud_visor_headbob",          "1",   "Toggle head-bone driven visor drift (0/1)", { legacy = "zd_hud_visor_headbob" })
ZDEV.CONV.ClientVar("zdev_hud_visor_headbob_strength", "1.0", "Multiplier on head-bone screen-space delta", { legacy = "zd_hud_visor_headbob_strength" })
ZDEV.CONV.ClientVar("zdev_hud_visor_headbob_speed",    "6",   "Head-bone smoothing speed (lower = more delay/lag)", { legacy = "zd_hud_visor_headbob_speed" })
ZDEV.CONV.ClientVar("zdev_hud_visor_headbob_max",      "40",  "Max pixels the head-bob effect can offset the visor (clamp)", { legacy = "zd_hud_visor_headbob_max" })
ZDEV.CONV.ClientVar("zdev_hud_parallax",           "1",    "Master toggle: HUD elements drift with the visor (0/1)", { legacy = "zd_hud_parallax" })
ZDEV.CONV.ClientVar("zdev_hud_parallax_visor",     "1.0",  "Parallax multiplier for the visor itself", { legacy = "zd_hud_parallax_visor" })
ZDEV.CONV.ClientVar("zdev_hud_parallax_messages",  "0.10", "Parallax multiplier for HUD messages and markers", { legacy = "zd_hud_parallax_messages" })
ZDEV.CONV.ClientVar("zdev_hud_parallax_pickup",    "0.15", "Parallax multiplier for pickup notifications", { legacy = "zd_hud_parallax_pickup" })
ZDEV.CONV.ClientVar("zdev_hud_parallax_dev",       "0.0",  "Parallax multiplier for the dev/debug overlay", { legacy = "zd_hud_parallax_dev" })
ZDEV.CONV.ClientVar("zdev_chud_enabled",           "1",    "Master switch for the whole CHUD paint pipeline (crash bisect / emergencies)")
-- Retired per-element parallax/curve convars (vitals/ammo/info/crosshair) are now
-- per-element layout fields edited in the HUD editor; legacy convars left untouched.

if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.CHUD = ZDEV.CHUD or {}
local CHUD = ZDEV.CHUD

CHUD.Targets  = CHUD.Targets  or {}   -- legacy compat (old target-lock system)
CHUD.Elements = CHUD.Elements or {}
CHUD.Layout   = CHUD.Layout   or {}

local DRAW  = ZDEV.DRAW
local ANIM  = ZDEV.ANIM

local hook     = hook
local cam      = cam
local math     = math
local Clamp    = math.Clamp
local floor    = math.floor
local max, min = math.max, math.min
local pairs, ipairs = pairs, ipairs
local isstring, istable, isnumber = isstring, istable, isnumber

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	THEME COLOURS  (zdev_hud_clr_pri / zdev_hud_clr_sec — parsed once, cached,
	refreshed via change callback instead of string.ToColor every frame)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local clrPri = Color( 255, 150, 0, 255 )
local clrSec = Color( 255, 150, 0, 255 )

local function parseClrInto( str, c )
	local p = string.ToColor( str or "" )
	if p then c.r, c.g, c.b, c.a = p.r, p.g, p.b, p.a or 255 end
end

local cvClrPri = GetConVar( "zdev_hud_clr_pri" )
local cvClrSec = GetConVar( "zdev_hud_clr_sec" )
if cvClrPri then parseClrInto( cvClrPri:GetString(), clrPri ) end
if cvClrSec then parseClrInto( cvClrSec:GetString(), clrSec ) end
cvars.AddChangeCallback( "zdev_hud_clr_pri", function( _, _, new ) parseClrInto( new, clrPri ) end, "zdev_chud_theme" )
cvars.AddChangeCallback( "zdev_hud_clr_sec", function( _, _, new ) parseClrInto( new, clrSec ) end, "zdev_chud_theme" )

-- Elements read the live theme colours through this (returns the SAME Color
-- objects every call — do not mutate them).
function CHUD.GetColors()
	return clrPri, clrSec
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ANCHORS  —  9-point resolution-independent anchoring. An element's offset
	(layout.x / layout.y, in 1080p design pixels) is applied from its anchor
	point, and the element's OWN pivot mirrors the anchor (a "br"-anchored
	element positions its bottom-right corner). uiScale = ScrH()/1080.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local ANCHORS = {
	tl = { 0.0, 0.0 }, t = { 0.5, 0.0 }, tr = { 1.0, 0.0 },
	l  = { 0.0, 0.5 }, c = { 0.5, 0.5 }, r  = { 1.0, 0.5 },
	bl = { 0.0, 1.0 }, b = { 0.5, 1.0 }, br = { 1.0, 1.0 },
}
CHUD.AnchorNames = { "tl", "t", "tr", "l", "c", "r", "bl", "b", "br" }

function CHUD.UIScale()
	return ScrH() / 1080
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	REGISTRY

	ZDEV.CHUD.Register( id, def )
	  def = {
	    label      = "VITALS",              -- editor display name
	    size       = { w = 280, h = 70 },   -- design-space size (1080p px)
	    anchor     = "bl", x = 24, y = -24, -- default layout
	    scale      = 1, rot = 0,            -- default transform
	    parallax   = 0.2, alpha = 1,        -- visor-drift multiplier, opacity
	    order      = 50,                    -- paint order (low = behind)
	    convar     = "zdev_hud_vitals",     -- OPTIONAL existing vis convar;
	                                        -- else zdev_hud_el_<id> is created
	    adminOnly  = false,                 -- superadmin-gated element
	    fullscreen = false,                 -- skip transform; Paint(sw, sh, p)
	    params     = { key = { label=, type="number|int|bool|color|select|string",
	                           default=, min=, max=, decimals=, options={} } },
	    paramOrder = { "key", ... },        -- OPTIONAL stable inspector order
	    Paint      = function( self, w, h, p, pri, sec ) ... end,  -- LOCAL space
	  }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local sorted      = {}     -- paint-ordered array of ids (rebuilt when dirty)
local sortedDirty = true
local visConVars  = {}     -- id -> cached ConVar handle

local function rebuildSorted()
	sorted = {}
	for id in pairs( CHUD.Elements ) do sorted[ #sorted + 1 ] = id end
	table.sort( sorted, function( a, b )
		local ea, eb = CHUD.Elements[ a ], CHUD.Elements[ b ]
		if ea.order == eb.order then return a < b end
		return ( ea.order or 50 ) < ( eb.order or 50 )
	end )
	sortedDirty = false
end

-- Build a fresh layout state from an element's defaults.
local function defaultLayout( def )
	local l = {
		enabled  = def.enabled ~= false,
		anchor   = def.anchor or "tl",
		x        = def.x or 0,
		y        = def.y or 0,
		scale    = def.scale or 1,
		rot      = def.rot or 0,
		parallax = def.parallax or 0,
		alpha    = def.alpha or 1,
		params   = {},
	}
	if def.params then
		for k, p in pairs( def.params ) do
			local d = p.default
			if p.type == "color" and istable( d ) then
				d = Color( d.r or 255, d.g or 255, d.b or 255, d.a or 255 )
			end
			l.params[ k ] = d
		end
	end
	-- widget-tree elements: adopt a normalized copy of the default tree
	if def.tree then
		local W = CHUD.WIDG
		l.tree = ( W and W.SanitizeNode and W.SanitizeNode( def.tree ) ) or table.Copy( def.tree )
	end
	return l
end

function CHUD.Register( id, def )
	def.id    = id
	def.label = def.label or string.upper( id )
	def.size  = def.size or { w = 100, h = 40 }
	def.order = def.order or 50
	def._fadeKey = "chud:" .. id      -- precomputed (no per-frame concat)
	CHUD.Elements[ id ] = def
	sortedDirty = true

	-- visibility convar: reuse an existing one, or mint zdev_hud_el_<id>
	local cvName = def.convar or ( "zdev_hud_el_" .. id )
	if not def.convar then
		ZDEV.CONV.ClientVar( cvName, "1", "Toggle drawing of HUD element '" .. id .. "'" )
	end
	visConVars[ id ] = GetConVar( cvName )
	def._cvName = cvName

	-- adopt defaults; merge over any layout already loaded from the profile
	-- (profile may load before OR after registration — both orders work)
	local existing = CHUD.Layout[ id ]
	CHUD.Layout[ id ] = defaultLayout( def )
	if existing then CHUD.ApplyLayout( id, existing ) end
	return def
end

-- Merge a stored layout table (from a profile) over the element's current
-- layout — type-checked so a stale/corrupt profile can't poison the state.
function CHUD.ApplyLayout( id, src )
	local def = CHUD.Elements[ id ]
	local dst = CHUD.Layout[ id ]
	if not dst then CHUD.Layout[ id ] = src return end
	if not istable( src ) then return end

	if src.enabled ~= nil then dst.enabled = tobool( src.enabled ) end
	if isstring( src.anchor ) and ANCHORS[ src.anchor ] then dst.anchor = src.anchor end
	if isnumber( src.x )        then dst.x        = src.x end
	if isnumber( src.y )        then dst.y        = src.y end
	if isnumber( src.scale )    then dst.scale    = Clamp( src.scale, 0.1, 8 ) end
	if isnumber( src.rot )      then dst.rot      = Clamp( src.rot, -180, 180 ) end
	if isnumber( src.parallax ) then dst.parallax = Clamp( src.parallax, -2, 2 ) end
	if isnumber( src.alpha )    then dst.alpha    = Clamp( src.alpha, 0, 1 ) end

	-- widget tree + custom-element marker (sanitized; a corrupt profile can't
	-- inject unknown node types or unbounded depth)
	if istable( src.tree ) then
		local W = CHUD.WIDG
		local t = W and W.SanitizeNode and W.SanitizeNode( src.tree )
		dst.tree = t or table.Copy( src.tree )
	end
	if istable( src.custom ) then dst.custom = table.Copy( src.custom ) end

	if def and def.params and istable( src.params ) then
		for k, spec in pairs( def.params ) do
			local v = src.params[ k ]
			if v ~= nil then
				if spec.type == "color" then
					if istable( v ) then
						dst.params[ k ] = Color( v.r or 255, v.g or 255, v.b or 255, v.a or 255 )
					end
				elseif spec.type == "bool" then
					dst.params[ k ] = tobool( v )
				elseif spec.type == "number" or spec.type == "int" then
					v = tonumber( v )
					if v then
						if spec.min then v = max( v, spec.min ) end
						if spec.max then v = min( v, spec.max ) end
						dst.params[ k ] = ( spec.type == "int" ) and floor( v + 0.5 ) or v
					end
				else
					dst.params[ k ] = v
				end
			end
		end
	end
end

function CHUD.ResetElement( id )
	local def = CHUD.Elements[ id ]
	if not def then return end
	CHUD.Layout[ id ] = defaultLayout( def )
	CHUD.MarkDirty()
end

function CHUD.ResetAll()
	for id in pairs( CHUD.Elements ) do
		CHUD.Layout[ id ] = defaultLayout( CHUD.Elements[ id ] )
	end
	CHUD.MarkDirty()
end

-- Unregister an element entirely (used for user-created custom panels).
function CHUD.RemoveElement( id )
	if not CHUD.Elements[ id ] then return false end
	CHUD.Elements[ id ] = nil
	CHUD.Layout[ id ]   = nil
	visConVars[ id ]    = nil
	sortedDirty = true
	CHUD.MarkDirty()
	return true
end

-- Is the element currently visible (convar + layout + admin gate)?
function CHUD.IsElementVisible( id )
	local def = CHUD.Elements[ id ]
	if not def then return false end
	local cv = visConVars[ id ]
	if cv and not cv:GetBool() then return false end
	local l = CHUD.Layout[ id ]
	if l and l.enabled == false then return false end
	if def.adminOnly then
		local lp = LocalPlayer()
		if not ( IsValid( lp ) and lp.GetUserGroup and lp:GetUserGroup() == "superadmin" ) then
			return false
		end
	end
	return true
end

-- Screen-space rect { x, y, w, h } of an element (unrotated AABB, no parallax
-- — stable for editor hit-testing/dragging). Returns nil for fullscreen.
function CHUD.GetRect( id )
	local def = CHUD.Elements[ id ]
	local l   = CHUD.Layout[ id ]
	if not ( def and l ) or def.fullscreen then return nil end
	local s  = CHUD.UIScale() * ( l.scale or 1 )
	local w  = def.size.w * s
	local h  = def.size.h * s
	local a  = ANCHORS[ l.anchor ] or ANCHORS.tl
	local sw, sh = ScrW(), ScrH()
	local px = a[ 1 ] * sw + l.x * CHUD.UIScale()
	local py = a[ 2 ] * sh + l.y * CHUD.UIScale()
	-- pivot mirrors the anchor
	return px - a[ 1 ] * w, py - a[ 2 ] * h, w, h
end

-- Topmost element whose rect contains (mx,my) — editor hit-testing.
function CHUD.ElementAt( mx, my )
	if sortedDirty then rebuildSorted() end
	for i = #sorted, 1, -1 do
		local id = sorted[ i ]
		local def = CHUD.Elements[ id ]
		if not def.fullscreen and not def.noEditor then
			local x, y, w, h = CHUD.GetRect( id )
			if x and mx >= x and mx <= x + w and my >= y and my <= y + h then
				return id
			end
		end
	end
	return nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PERSISTENCE  —  JSON profiles in data/zdev/hud/. "_active" is the live
	autosaved state; named profiles are user snapshots.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local PROFILE_DIR = "zdev/hud"
file.CreateDir( PROFILE_DIR )

local function sanitizeProfileName( name )
	name = string.lower( tostring( name or "" ) )
	name = string.gsub( name, "[^%w_%-]", "" )
	return name ~= "" and name or nil
end

-- Serialise layout (Colors become plain {r,g,b,a} tables via TableToJSON).
function CHUD.SaveProfile( name )
	name = sanitizeProfileName( name )
	if not name then return false end
	local out = { version = 1, layout = CHUD.Layout }
	local json = util.TableToJSON( out, true )
	if not json then
		zdev.log( "E", "CHUD.SaveProfile: serialisation failed" )
		return false
	end
	file.Write( PROFILE_DIR .. "/" .. name .. ".json", json )
	return true
end

function CHUD.LoadProfile( name )
	name = sanitizeProfileName( name )
	if not name then return false end
	local raw = file.Read( PROFILE_DIR .. "/" .. name .. ".json", "DATA" )
	if not raw then return false end
	local data = util.JSONToTable( raw )
	if not ( istable( data ) and istable( data.layout ) ) then
		zdev.log( "E", "CHUD.LoadProfile: bad profile '" .. name .. "'" )
		return false
	end
	for id, l in pairs( data.layout ) do
		if CHUD.Elements[ id ] then
			CHUD.ApplyLayout( id, l )
		else
			CHUD.Layout[ id ] = l   -- element not registered (yet); kept verbatim
		end
	end
	-- re-create any user-made custom panels carried by this profile
	if CHUD.WIDG and CHUD.WIDG.RestoreCustomElements then
		CHUD.WIDG.RestoreCustomElements()
	end
	return true
end

function CHUD.DeleteProfile( name )
	name = sanitizeProfileName( name )
	if not name or name == "_active" then return false end
	file.Delete( PROFILE_DIR .. "/" .. name .. ".json" )
	return true
end

function CHUD.ListProfiles()
	local out = {}
	local files = file.Find( PROFILE_DIR .. "/*.json", "DATA" ) or {}
	for _, f in ipairs( files ) do
		local n = string.StripExtension( f )
		if n ~= "_active" then out[ #out + 1 ] = n end
	end
	table.sort( out )
	return out
end

-- Debounced autosave of the live state; the editor calls this after any edit.
function CHUD.MarkDirty()
	timer.Create( "ZDEV_CHUD_Autosave", 1.5, 1, function()
		CHUD.SaveProfile( "_active" )
	end )
end

-- Autoload the live state (elements registered later merge via Register()).
CHUD.LoadProfile( "_active" )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	VISOR OFFSET / SWAY  —  the shared per-frame HUD drift (angle smear +
	head-bone bob), unchanged behaviour from CHUD v1.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local CV = {
	ang_strength = GetConVar( "zdev_hud_visor_ang_strength" ),
	ang_speed    = GetConVar( "zdev_hud_visor_ang_speed" ),
	scale        = GetConVar( "zdev_hud_visor_scale" ),
	aspect       = GetConVar( "zdev_hud_visor_aspect" ),
	hb_enabled   = GetConVar( "zdev_hud_visor_headbob" ),
	hb_strength  = GetConVar( "zdev_hud_visor_headbob_strength" ),
	hb_speed     = GetConVar( "zdev_hud_visor_headbob_speed" ),
	hb_max       = GetConVar( "zdev_hud_visor_headbob_max" ),
	px_enabled   = GetConVar( "zdev_hud_parallax" ),
	px_visor     = GetConVar( "zdev_hud_parallax_visor" ),
	px_messages  = GetConVar( "zdev_hud_parallax_messages" ),
	px_pickup    = GetConVar( "zdev_hud_parallax_pickup" ),
	px_dev       = GetConVar( "zdev_hud_parallax_dev" ),
}
CHUD.CV = CV   -- elements (visor) read scale/aspect through this

local _VISOR = {
	headBoneId    = nil,
	headBoneModel = nil,
	hbRefScreen   = nil,
}

local _OFFSET = { x = 0, y = 0 }
CHUD.Offset = _OFFSET

local function ResolveHeadBone( ply )
	local mdl = ply:GetModel()
	if _VISOR.headBoneModel == mdl and _VISOR.headBoneId then
		return _VISOR.headBoneId
	end
	_VISOR.headBoneModel = mdl
	local bid = ply:LookupBone( "ValveBiped.Bip01_Head1" )
	if not bid then bid = ply:LookupBone( "bip01_head1" ) end
	if not bid then bid = ply:LookupBone( "head" ) end
	_VISOR.headBoneId = bid
	return bid
end

function CHUD.UpdateHUDOffset()
	local LP = LocalPlayer()
	if not IsValid( LP ) or CHUD.EditorActive then
		-- editor mode: freeze the HUD so elements are stable to click/drag
		_OFFSET.x, _OFFSET.y = 0, 0
		return
	end

	local eyeAng = LP:EyeAngles()
	local ft = FrameTime()

	if not CHUD.VisorLastAng then CHUD.VisorLastAng = eyeAng end
	local interp = Clamp( ft * CV.ang_speed:GetFloat(), 0, 1 )
	CHUD.VisorLastAng = LerpAngle( interp, CHUD.VisorLastAng, eyeAng )

	local angStrength = CV.ang_strength:GetFloat()
	local offsetX = math.AngleDifference( eyeAng.y, CHUD.VisorLastAng.y ) * angStrength
	local offsetY = math.AngleDifference( eyeAng.p, CHUD.VisorLastAng.p ) * -angStrength

	if CV.hb_enabled:GetBool() then
		-- Read the engine's cached bone matrix only. Do NOT force
		-- InvalidateBoneCache/SetupBones here: SetupBones re-enters every
		-- BuildBonePositions callback other addons attached to the player
		-- (VManip-style bone manipulators), and doing that from inside
		-- HUDPaint can recurse at the C level and hard-crash on spawn.
		-- Stale bones just yield a ~0 delta (weaker bob), never a crash.
		local boneId = ResolveHeadBone( LP )
		if boneId then
			local bonePos = LP:GetBonePosition( boneId )
			if bonePos then
				local screen = bonePos:ToScreen()
				if screen.visible ~= false then
					if not _VISOR.hbRefScreen then
						_VISOR.hbRefScreen = { x = screen.x, y = screen.y }
					end
					local hbInterp = Clamp( ft * CV.hb_speed:GetFloat(), 0, 1 )
					_VISOR.hbRefScreen.x = Lerp( hbInterp, _VISOR.hbRefScreen.x, screen.x )
					_VISOR.hbRefScreen.y = Lerp( hbInterp, _VISOR.hbRefScreen.y, screen.y )
					local hbStrength = CV.hb_strength:GetFloat()
					local hbMax      = CV.hb_max:GetFloat()
					offsetX = offsetX + Clamp( ( screen.x - _VISOR.hbRefScreen.x ) * hbStrength, -hbMax, hbMax )
					offsetY = offsetY + Clamp( ( screen.y - _VISOR.hbRefScreen.y ) * hbStrength, -hbMax, hbMax )
				end
			end
		end
	else
		_VISOR.hbRefScreen = nil
	end

	_OFFSET.x = offsetX
	_OFFSET.y = offsetY
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PARALLAX API  (PRESERVED)  —  named-consumer parallax for HUD files that
	paint in their own hooks (messages / pickup / dev). Element parallax is
	handled by the pipeline itself via layout.parallax.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local _PX_PUSH_DEPTH = 0
local _PX_CONVARS = {
	visor    = "px_visor",
	messages = "px_messages",
	pickup   = "px_pickup",
	dev      = "px_dev",
}

function CHUD.GetParallax( name )
	if not CV.px_enabled:GetBool() then return 0, 0 end
	-- registered element? use its live layout multiplier
	local l = CHUD.Layout[ name ]
	if l and CHUD.Elements[ name ] then
		local m = l.parallax or 0
		return _OFFSET.x * m, _OFFSET.y * m
	end
	local cvKey = _PX_CONVARS[ name ]
	local cv = cvKey and CV[ cvKey ]
	if not cv then return 0, 0 end
	local m = cv:GetFloat()
	return _OFFSET.x * m, _OFFSET.y * m
end

-- pooled matrix/vector/angle per push depth — zero per-frame allocation
local _MAT_POOL, _VEC_POOL, _ANG_POOL = {}, {}, {}
local function poolFor( depth )
	local m = _MAT_POOL[ depth ]
	if not m then
		m = Matrix()
		_MAT_POOL[ depth ] = m
		_VEC_POOL[ depth ] = Vector( 0, 0, 0 )
		_ANG_POOL[ depth ] = Angle( 0, 0, 0 )
	end
	return m, _VEC_POOL[ depth ], _ANG_POOL[ depth ]
end

function CHUD.PushParallax( name )
	local px, py = CHUD.GetParallax( name )
	local depth = _PX_PUSH_DEPTH + 1
	local m, v = poolFor( depth )
	m:Identity()
	v.x, v.y, v.z = px, py, 0
	m:SetTranslation( v )
	cam.PushModelMatrix( m, true )
	_PX_PUSH_DEPTH = depth
end

function CHUD.PushParallaxRotated( name, pivotX, pivotY, angleDeg )
	local px, py = CHUD.GetParallax( name )
	local depth = _PX_PUSH_DEPTH + 1
	local m, v, a = poolFor( depth )
	m:Identity()
	v.x, v.y, v.z = pivotX + px, pivotY + py, 0
	m:Translate( v )
	if angleDeg and angleDeg ~= 0 then
		a.y = angleDeg
		m:Rotate( a )
	end
	v.x, v.y, v.z = -pivotX, -pivotY, 0
	m:Translate( v )
	cam.PushModelMatrix( m, true )
	_PX_PUSH_DEPTH = depth
end

function CHUD.PopParallax()
	if _PX_PUSH_DEPTH <= 0 then return end
	cam.PopModelMatrix()
	_PX_PUSH_DEPTH = _PX_PUSH_DEPTH - 1
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PAINT PIPELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.EditorActive = CHUD.EditorActive or false
CHUD.EditorOverlay = CHUD.EditorOverlay   -- fn set by zd_cl_menu_editor_hud.lua

-- one pooled matrix/vector/angle for element transforms (never nested)
local elMat, elVec, elAng = Matrix(), Vector( 0, 0, 0 ), Angle( 0, 0, 0 )
local paintErrOnce = {}

local function paintElement( id )
	local def = CHUD.Elements[ id ]
	local l   = CHUD.Layout[ id ]
	if not ( def and l and def.Paint ) then return end

	local visible = CHUD.IsElementVisible( id )
	-- situational elements (e.g. no-weapon arsenal) — always drawn in editor
	if visible and def.ShouldDraw and not CHUD.EditorActive and not def.ShouldDraw( def ) then
		visible = false
	end
	-- fade toward shown/hidden; ghost hidden elements while the editor is open
	local fade = ANIM.Fade( def._fadeKey or id, visible, 10 )
	local alpha = fade
	if not visible then
		if CHUD.EditorActive and not def.fullscreen then
			alpha = max( fade, 0.15 )        -- ghosted but still visible/editable
		elseif fade < 0.01 then
			return
		end
	end
	alpha = alpha * ( l.alpha or 1 )
	if CHUD.EditorActive and not def.fullscreen then
		alpha = max( alpha, 0.15 )           -- keep editable even at alpha 0
	end
	if alpha <= 0.005 then return end

	if def.fullscreen then
		DRAW.PushAlpha( alpha )
		local ok, err = pcall( def.Paint, def, ScrW(), ScrH(), l.params, clrPri, clrSec )
		DRAW.PopAlpha()
		if not ok and not paintErrOnce[ id ] then
			paintErrOnce[ id ] = true
			zdev.log( "E", "CHUD element '" .. id .. "' paint error: " .. tostring( err ) )
		end
		return
	end

	local x, y, w, h = CHUD.GetRect( id )
	if not x then return end
	local s = CHUD.UIScale() * ( l.scale or 1 )

	-- parallax offset for this element
	local px, py = 0, 0
	if CV.px_enabled:GetBool() and not CHUD.EditorActive then
		local m = l.parallax or 0
		px, py = _OFFSET.x * m, _OFFSET.y * m
	end

	-- transform: translate to rect origin (+parallax), rotate about the
	-- element's pivot, scale into design space
	local a = ANCHORS[ l.anchor ] or ANCHORS.tl
	local pvx, pvy = x + a[ 1 ] * w, y + a[ 2 ] * h     -- screen pivot

	elMat:Identity()
	elVec.x, elVec.y, elVec.z = pvx + px, pvy + py, 0
	elMat:Translate( elVec )
	if l.rot and l.rot ~= 0 then
		elAng.y = l.rot
		elMat:Rotate( elAng )
		elAng.y = 0
	end
	elVec.x, elVec.y, elVec.z = s, s, 1
	elMat:Scale( elVec )
	-- pivot back in DESIGN space (post-scale)
	elVec.x, elVec.y, elVec.z = -a[ 1 ] * def.size.w, -a[ 2 ] * def.size.h, 0
	elMat:Translate( elVec )

	cam.PushModelMatrix( elMat, true )
	DRAW.PushAlpha( alpha )
	local ok, err = pcall( def.Paint, def, def.size.w, def.size.h, l.params, clrPri, clrSec )
	DRAW.PopAlpha()
	cam.PopModelMatrix()

	if not ok and not paintErrOnce[ id ] then
		paintErrOnce[ id ] = true
		zdev.log( "E", "CHUD element '" .. id .. "' paint error: " .. tostring( err ) )
	end
end

local cvChudEnabled = GetConVar( "zdev_chud_enabled" )

function CHUD.Paint()
	if cvChudEnabled and not cvChudEnabled:GetBool() then return end
	local LP = LocalPlayer()
	if not ( IsValid( LP ) and LP:IsPlayer() ) then return end
	if not LP:Alive() and not CHUD.EditorActive then return end

	CHUD.UpdateHUDOffset()

	if sortedDirty then rebuildSorted() end
	for i = 1, #sorted do
		paintElement( sorted[ i ] )
	end

	if CHUD.EditorActive and CHUD.EditorOverlay then
		local ok, err = pcall( CHUD.EditorOverlay )
		if not ok and not paintErrOnce._editor then
			paintErrOnce._editor = true
			zdev.log( "E", "CHUD editor overlay error: " .. tostring( err ) )
		end
	end
end

hook.Add( "HUDPaint", "ZDEV.CHUD.Paint", function() CHUD.Paint() end )

-- Editor entry/exit (the editor menu file drives this)
function CHUD.SetEditorMode( active )
	CHUD.EditorActive = tobool( active )
	paintErrOnce._editor = nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HIDE DEFAULT HL2 HUD  (PRESERVED behaviour)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local hide = {
	[ 'CHudHealth' ]        = "zdev_hud_vitals",
	[ 'CHudBattery' ]       = "zdev_hud_vitals",
	[ 'CHudCrosshair' ]     = "zdev_hud_crosshair",
	[ 'CHudAmmo' ]          = "zdev_hud_ammo",
	[ 'CHudSecondaryAmmo' ] = "zdev_hud_ammo",
}
local hideCv = {}
for name, cvname in pairs( hide ) do hideCv[ name ] = GetConVar( cvname ) end

function CHUD.HideDefault( name )
	local cv = hideCv[ name ]
	if cv and cv:GetBool() then return false end
end
hook.Add( "HUDShouldDraw", "ZDEV.CHUD.HideDefault", CHUD.HideDefault )

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )
