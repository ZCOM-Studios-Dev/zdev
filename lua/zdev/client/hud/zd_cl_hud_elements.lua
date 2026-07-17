local _f = 'zdev/client/hud/zd_cl_hud_elements.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_hud_elements.lua  —  built-in ZDEV.CHUD elements

	Every element is registered through ZDEV.CHUD.Register and draws in LOCAL
	design space (0,0 .. w,h @1080p). Position/scale/rotation/parallax/alpha
	are handled by the CHUD core and edited live in the HUD Editor
	(zdev_edit_hud_editor). Styling follows docs/reference/VISUAL_STYLE_GUIDE.md:
	near-black ground, grey hairline structure, INVERSION title chips, one
	accent hue on live/focal data only, semantic colour only with meaning,
	letter-spaced micro-labels, LED numbers with ghost zeros, segmented meters
	with micro-numeral annotations. Style values come from ZDEV.DRAW.UI.THEME.

	DOCUMENTED DEVIATION (guide §8 "ConVar per visual tunable"): element
	parameters are registered through the CHUD schema and persisted via HUD
	Editor profiles (data/zdev/hud/*.json) instead of one ConVar per tunable —
	same goal (live-tunable without code edits), one source of truth, and the
	schema auto-generates the editor UI. Element VISIBILITY remains ConVar-based
	(zdev_hud_* / zdev_hud_el_*), as do the visor/parallax tunables.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Fonts (idempotent; before the reload guard so hot-reload keeps them)
if ZDEV.FONT and ZDEV.FONT.Register then
	ZDEV.FONT.Register( "ZDEV_HUD_Label",  { font = "Rajdhani",       size = 14, weight = 600, extended = true, antialias = true } )
	ZDEV.FONT.Register( "ZDEV_HUD_Title",  { font = "Rajdhani",       size = 18, weight = 700, extended = true, antialias = true, shadow = true } )
	ZDEV.FONT.Register( "ZDEV_HUD_LED",    { font = "Digital-7 Mono", size = 42, weight = 500, extended = true, antialias = true } )
	ZDEV.FONT.Register( "ZDEV_HUD_LED_Sm", { font = "Digital-7 Mono", size = 24, weight = 500, extended = true, antialias = true } )
end

if ZDEV.FILE.Loaded( _f ) then return end

local CHUD = ZDEV.CHUD
local DRAW = ZDEV.DRAW
local UI   = ZDEV.DRAW.UI
local FX   = ZDEV.DRAW.FX

local SimpleText  = draw.SimpleText
local floor       = math.floor
local A_C, A_L = TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT
local A_T      = TEXT_ALIGN_TOP

-- Memoised letter-spacing (DRAW.LetterSpace allocates; labels repeat per frame)
local lsCache = {}
local function LS( s )
	local v = lsCache[ s ]
	if not v then
		v = DRAW.LetterSpace( s )
		lsCache[ s ] = v
	end
	return v
end

-- Style values come from the single reskin point (VISUAL_STYLE_GUIDE.md §8).
local TH = ZDEV.DRAW.UI.THEME
local SetFont, GetTextSize = surface.SetFont, surface.GetTextSize

-- Resolve an element's accent: theme primary unless the element overrides it.
local function accentOf( p, pri )
	if p.useTheme == false and IsColor( p.accent ) then return p.accent end
	if p.useTheme == false and istable( p.accent ) then return p.accent end
	return pri
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	VISOR  (fullscreen overlay; applies its own parallax like CHUD v1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local visor_mat = {
	base = Material( "visor/visor_holo.png" ),
	blur = Material( "visor/visor_holo_blur.png" ),
	glow = Material( "visor/visor_holo_glow.png" ),
}
local visorClr = { base = Color( 255, 255, 255, 5 ), blur = Color( 255, 255, 255, 50 ), glow = Color( 255, 255, 255, 5 ) }

CHUD.Register( "visor", {
	label      = "VISOR OVERLAY",
	convar     = "zdev_hud_visor",
	fullscreen = true,
	order      = 10,
	params     = {
		baseAlpha = { label = "Base Alpha", type = "int", default = 5,  min = 0, max = 255 },
		blurAlpha = { label = "Blur Alpha", type = "int", default = 50, min = 0, max = 255 },
		glowAlpha = { label = "Glow Alpha", type = "int", default = 5,  min = 0, max = 255 },
	},
	paramOrder = { "baseAlpha", "blurAlpha", "glowAlpha" },
	Paint = function( self, sw, sh, p )
		local CV = CHUD.CV
		-- Shared glass drift — the exact same offset every on-glass HUD element
		-- rides, so the visor and the data all move together as one pane.
		local ox, oy = CHUD.GlassOffset()

		local scale  = CV.scale:GetFloat()
		local aspect = CV.aspect:GetFloat()
		local w = sw * scale
		local h = sh * ( scale * aspect )
		local x = ( sw - w ) * 0.5 + ox
		local y = ( sh - h ) * 0.5 + oy

		visorClr.base.a = p.baseAlpha or 5
		visorClr.blur.a = p.blurAlpha or 50
		visorClr.glow.a = p.glowAlpha or 5
		DRAW.TexturedRect( x, y, w, h, visor_mat.base, visorClr.base )
		DRAW.TexturedRect( x, y, w, h, visor_mat.blur, visorClr.blur )
		DRAW.TexturedRect( x, y, w, h, visor_mat.glow, visorClr.glow )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	VITALS  —  health / armor cluster (bottom-left).  WIDGET TREE: every part
	(chip, LED, bar, labels) is a child node — selectable, reparentable and
	fully parametrised in the HUD Editor hierarchy.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local WIDG = CHUD.WIDG
local elemParams, elemParamOrder = WIDG.ElementParams()

CHUD.Register( "vitals", {
	label    = "VITALS",
	convar   = "zdev_hud_vitals",
	size     = { w = 300, h = 84 },
	anchor   = "bl", x = 28, y = -28,
	parallax = 1.0, rot = 0,       -- depth on the visor glass (1 = flush)
	order    = 40,
	params   = elemParams, paramOrder = elemParamOrder,
	Paint    = WIDG.TreePaint,
	tree = {
		type = "panel", name = "VITALS ROOT",
		children = {
			{ type = "shape", name = "PANEL BG", x = 0, y = 0, w = 300, h = 84,
				props = { kind = "cutbox", cut = 10, corners = 5, colorMode = "border", fillMode = "bg" } },
			{ type = "brackets", name = "FRAME", x = 0, y = 0, w = 300, h = 84,
				props = { len = 9, thickness = 1, colorMode = "border" } },
			{ type = "chip", name = "TITLE CHIP", x = 8, y = 5, w = 70, h = 16,
				props = { text = "VITALS", font = "ZDEV_HUD_Label", lowBind = "health", lowFrac = 0.33 } },
			{ type = "text", name = "STATUS", x = 168, y = 8, w = 120, h = 12,
				props = { text = "NOMINAL", font = "ZDEV_HUD_Label", alignH = "right", colorMode = "dim",
					letterspace = true, lowBind = "health", lowFrac = 0.33, lowText = "CRITICAL" } },
			{ type = "led", name = "HEALTH LED", x = 14, y = 26, w = 90, h = 28,
				props = { bind = "health", digits = 3, font = "ZDEV_HUD_LED", colorMode = "accent",
					glow = true, glowSize = 40, glowAlpha = 50, lowBind = "health", lowFrac = 0.33 } },
			{ type = "text", name = "HP LABEL", x = 100, y = 50, w = 30, h = 12,
				props = { text = "HP", font = "ZDEV_HUD_Label", colorMode = "dim", letterspace = true } },
			{ type = "text", name = "HP READOUT", x = 188, y = 40, w = 100, h = 12,
				props = { bind = "health_pair", font = "ZDEV_HUD_Label", alignH = "right", colorMode = "dim" } },
			{ type = "bar", name = "HEALTH BAR", x = 12, y = 54, w = 276, h = 8,
				props = { bind = "health", segments = 14, loss = true, border = true,
					fillMode = "accent", lowFrac = 0.33 } },
			{ type = "text", name = "ARMOR LABEL", x = 12, y = 67, w = 34, h = 12,
				props = { text = "ARM", font = "ZDEV_HUD_Label", colorMode = "dim", letterspace = true } },
			{ type = "segbar", name = "ARMOR PIPS", x = 48, y = 70, w = 196, h = 6,
				props = { bind = "armor", count = 10, gap = 3, onMode = "text" } },
			{ type = "text", name = "ARMOR LED", x = 228, y = 62, w = 60, h = 20,
				props = { bind = "armor", format = "%03d", font = "ZDEV_HUD_LED_Sm",
					alignH = "right", colorMode = "text" } },
		},
	},
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ARSENAL  —  weapon / ammo cluster (bottom-right)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.Register( "ammo", {
	label    = "ARSENAL",
	convar   = "zdev_hud_ammo",
	size     = { w = 300, h = 84 },
	anchor   = "br", x = -28, y = -28,
	parallax = 1.0, rot = 0,       -- depth on the visor glass (1 = flush)
	order    = 40,
	params   = elemParams, paramOrder = elemParamOrder,
	Paint    = WIDG.TreePaint,
	-- hide outside the editor when the held weapon has no ammo concept
	ShouldDraw = function( def )
		local LP = LocalPlayer()
		if not IsValid( LP ) then return false end
		local wep = LP:GetActiveWeapon()
		if not IsValid( wep ) then return false end
		local hasClip = wep:Clip1() >= 0 and wep:GetMaxClip1() > 0
		return hasClip or wep:GetPrimaryAmmoType() >= 0
	end,
	tree = {
		type = "panel", name = "ARSENAL ROOT",
		children = {
			{ type = "shape", name = "PANEL BG", x = 0, y = 0, w = 300, h = 84,
				props = { kind = "cutbox", cut = 10, corners = 10, colorMode = "border", fillMode = "bg" } },
			{ type = "brackets", name = "FRAME", x = 0, y = 0, w = 300, h = 84,
				props = { len = 9, thickness = 1, colorMode = "border" } },
			{ type = "chip", name = "WEAPON CHIP", x = 8, y = 5, w = 160, h = 16,
				props = { bind = "weapon_name", font = "ZDEV_HUD_Label", maxChars = 24,
					uppercase = true, lowBind = "clip", lowFrac = 0.33 } },
			{ type = "text", name = "STATUS", x = 168, y = 8, w = 120, h = 12,
				props = { text = "ARMED", font = "ZDEV_HUD_Label", alignH = "right", colorMode = "dim",
					letterspace = true, lowBind = "clip", lowFrac = 0.33, lowText = "RELOAD" } },
			{ type = "led", name = "AMMO LED", x = 186, y = 26, w = 100, h = 28,
				props = { bind = "ammo_display", digits = 3, font = "ZDEV_HUD_LED", colorMode = "accent",
					alignH = "right", glow = true, glowSize = 40, glowAlpha = 50,
					lowBind = "clip", lowFrac = 0.33 } },
			{ type = "text", name = "RESERVE", x = 88, y = 48, w = 80, h = 16,
				props = { bind = "reserve", format = "/ %03d", font = "ZDEV_HUD_LED_Sm",
					alignH = "right", colorMode = "text" } },
			{ type = "text", name = "RES LABEL", x = 12, y = 50, w = 34, h = 12,
				props = { text = "RES", font = "ZDEV_HUD_Label", colorMode = "dim", letterspace = true } },
			{ type = "text", name = "CLIP READOUT", x = 12, y = 52, w = 80, h = 12,
				props = { bind = "clip_pair", font = "ZDEV_HUD_Label", colorMode = "dim" } },
			{ type = "bar", name = "CLIP BAR", x = 12, y = 66, w = 276, h = 8,
				props = { bind = "clip", loss = true, border = true, fillMode = "accent", lowFrac = 0.33 } },
		},
	},
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PLAYER INFO  —  identity tear-sheet (top-left)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.Register( "info", {
	label    = "PLAYER INFO",
	convar   = "zdev_hud_info",
	size     = { w = 240, h = 66 },
	anchor   = "tl", x = 24, y = 24,
	parallax = 1.0, rot = 0,       -- depth on the visor glass (1 = flush)
	order    = 40,
	params   = elemParams, paramOrder = elemParamOrder,
	Paint    = WIDG.TreePaint,
	tree = {
		type = "panel", name = "INFO ROOT",
		children = {
			{ type = "shape", name = "PANEL BG", x = 0, y = 0, w = 240, h = 66,
				props = { kind = "rect", colorMode = "bg" } },
			{ type = "shape", name = "EDGE LINE", x = 0, y = 0, w = 2, h = 66,
				props = { kind = "line_v", thickness = 2, colorMode = "border" } },
			{ type = "brackets", name = "FRAME", x = 0, y = 0, w = 240, h = 66,
				props = { len = 8, thickness = 1, colorMode = "border" } },
			{ type = "chip", name = "TITLE CHIP", x = 8, y = 5, w = 80, h = 16,
				props = { text = "OPERATOR", font = "ZDEV_HUD_Label" } },
			{ type = "text", name = "PLAYER NAME", x = 12, y = 24, w = 216, h = 20,
				props = { bind = "player_name", font = "ZDEV_HUD_Title", colorMode = "text" } },
			{ type = "text", name = "RANK", x = 12, y = 46, w = 120, h = 12,
				props = { bind = "rank", font = "ZDEV_HUD_Label", colorMode = "dim",
					uppercase = true, letterspace = true } },
			{ type = "text", name = "STEAMID", x = 110, y = 46, w = 120, h = 12, visible = false,
				props = { bind = "steamid", font = "ZDEV_HUD_Label", alignH = "right", colorMode = "dim" } },
		},
	},
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CROSSHAIR  —  parametrised reticle (screen centre)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.Register( "crosshair", {
	label    = "CROSSHAIR",
	convar   = "zdev_hud_crosshair",
	size     = { w = 96, h = 96 },
	anchor   = "c", x = 0, y = 0,
	parallax = 1.0, rot = 0,       -- depth on the visor glass (1 = flush)
	order    = 30,
	params   = {
		useTheme  = { label = "Use Theme Colour", type = "bool",   default = false },
		accent    = { label = "Accent",           type = "color",  default = Color( 235, 240, 245 ) },
		style     = { label = "Style",            type = "select", default = "target", options = { "target", "lock", "bracket", "dot" } },
		size      = { label = "Size",             type = "int",    default = 16, min = 4, max = 48 },
		gap       = { label = "Gap",              type = "int",    default = 7,  min = 0, max = 32 },
		thickness = { label = "Thickness",        type = "int",    default = 1,  min = 1, max = 5 },
		ring      = { label = "Ring",             type = "bool",   default = true },
		dot       = { label = "Centre Dot",       type = "bool",   default = true },
		showDist  = { label = "Distance Readout", type = "bool",   default = false },
	},
	paramOrder = { "useTheme", "accent", "style", "size", "gap", "thickness", "ring", "dot", "showDist" },
	Paint = function( self, w, h, p, pri, sec )
		local acc = accentOf( p, pri )
		local cx, cy = w * 0.5, h * 0.5
		UI.Reticle( cx, cy, {
			style = p.style or "target",
			size = p.size or 16, gap = p.gap or 7,
			thickness = p.thickness or 1,
			clr = acc, ring = p.ring, dot = p.dot,
		} )
		if p.showDist then
			local LP = LocalPlayer()
			if IsValid( LP ) then
				local tr = LP:GetEyeTrace()
				local d = floor( LP:GetShootPos():Distance( tr.HitPos ) )
				SimpleText( d .. " HU", "ZDEV_HUD_Label", cx, cy + ( p.size or 16 ) + 10,
					TH.textDim, A_C, A_T )
			end
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	VERSION WATERMARK  (top-centre)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.Register( "version", {
	label    = "VERSION TAG",
	size     = { w = 200, h = 20 },
	anchor   = "t", x = 0, y = 16,
	parallax = 1.0,                -- depth on the visor glass (1 = flush)
	order    = 20,
	params   = elemParams, paramOrder = elemParamOrder,
	Paint    = WIDG.TreePaint,
	tree = {
		type = "panel", name = "VERSION ROOT",
		children = {
			{ type = "text", name = "VERSION TEXT", x = 0, y = 0, w = 200, h = 20,
				props = { bind = "version", font = "ZDEV_HUD_Label", alignH = "center", alignV = "center",
					colorMode = "dim", alpha = 150, letterspace = true } },
		},
	},
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	DEV OVERLAY  (superadmin; sections gated by zdev_dev_hud_* convars)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local devCv
local function devConvars()
	if devCv then return devCv end
	devCv = {
		time    = GetConVar( "zdev_dev_hud_time" ),
		xhair   = GetConVar( "zdev_dev_hud_xhair" ),
		grid    = GetConVar( "zdev_dev_hud_grid" ),
		entinfo = GetConVar( "zdev_dev_hud_entinfo" ),
		ents    = GetConVar( "zdev_dev_hud_ents" ),
	}
	return devCv
end

local devInfoEnt, devInfoKV = nil, nil

CHUD.Register( "dev", {
	label      = "DEV OVERLAY",
	fullscreen = true,
	adminOnly  = true,
	order      = 90,
	Paint = function( self, sw, sh, p, pri, sec )
		local LP = LocalPlayer()
		if not IsValid( LP ) then return end
		local cv = devConvars()

		if cv.time and cv.time:GetBool() then
			local rows = {
				{ "CurTime",       CurTime() },
				{ "RealTime",      RealTime() },
				{ "FrameTime",     FrameTime() },
				{ "RealFrameTime", RealFrameTime() },
			}
			for i = 1, #rows do
				SimpleText( rows[ i ][ 1 ] .. ": " .. string.format( "%.4f", rows[ i ][ 2 ] ),
					"ConsoleText", sw * 0.05, sh * 0.33 + i * 12, TH.textDim, A_L, A_T )
			end
		end

		if cv.grid and cv.grid:GetBool() then
			FX.GridLines( sw * 0.5 - 256, sh * 0.5 - 256, 512, 512, 32, TH.line, 1 )
			DRAW.Cross( sw * 0.5, sh * 0.5, 260, 0, 1, DRAW.Alpha( pri, 60 ) )
		end

		if cv.xhair and cv.xhair:GetBool() then
			local tr = LP:GetEyeTrace()
			local hx, hy = ZDEV.UTIL.PosToScreen( tr.HitPos )
			DRAW.Rect( hx - 3, hy - 3, 6, 6, pri )
			UI.CornerBrackets( hx - 24, hy - 24, 48, 48, 8, 1, DRAW.Alpha( pri, 150 ) )
			local e = tr.Entity
			if IsValid( e ) then
				local ex, ey = ZDEV.UTIL.PosToScreen( e:WorldSpaceCenter() )
				UI.Marker( ex, ey, { style = "bracket", size = 14, clr = sec, label = e:GetClass() } )
				if cv.entinfo and cv.entinfo:GetBool() then
					if devInfoEnt ~= e then
						devInfoEnt = e
						devInfoKV = e:GetSaveTable()
					end
					local iy = sh * 0.3
					SimpleText( tostring( e ), "ConsoleText", sw * 0.3, iy, color_white, A_L, A_T )
					if devInfoKV then
						local i = 0
						for k, v in SortedPairs( devInfoKV ) do
							i = i + 1
							if i > 28 then break end
							SimpleText( tostring( k ) .. " = " .. tostring( v ), "ConsoleText",
								sw * 0.3, iy + i * 11, TH.textDim, A_L, A_T )
						end
					end
				end
			end
		end

		if cv.ents and cv.ents:GetBool() then
			local shootPos = LP:GetShootPos()
			for _, e in ipairs( ents.GetAll() ) do
				if IsValid( e ) and not e:IsWorld() then
					local d = shootPos:Distance( e:GetPos() )
					if d < 1600 then
						local ex, ey = ZDEV.UTIL.PosToScreen( e:GetPos() )
						local a = 200 * ( 1 - d / 1600 )
						DRAW.Rect( ex - 2, ey - 2, 4, 4, Color( 200, 200, 200, a + 40 ) )
						SimpleText( e:GetClass(), "ConsoleText", ex + 5, ey, Color( 200, 200, 200, a ), A_L, A_C )
					end
				end
			end
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	EDIT-MODE BANNER  —  env / particle editor state strip (top edge).
	(The HUD editor draws its own overlay via the CHUD core.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local editCv
local function editConvars()
	if editCv then return editCv end
	editCv = {
		env      = GetConVar( "zdev_edit_env_toggle" ),
		envTool  = GetConVar( "zdev_edit_env_tool_mode" ),
		particle = GetConVar( "zdev_edit_particle_toggle" ),
	}
	return editCv
end

-- Edge status strip + centred INVERSION chip; amber = semantic "active edit
-- mode" warning (VISUAL_STYLE_GUIDE §3 — colour only as a badge with meaning).
local function paintBanner( sw, title )
	DRAW.Rect( 0, 0, sw, 26, TH.bg )
	DRAW.Rect( 0, 26, sw, 1, TH.border )
	FX.Scanlines( 0, 0, sw, 26, 3, Color( 0, 0, 0, 60 ) )
	local spaced = LS( title )
	SetFont( "ZDEV_HUD_Title" )
	local tw = GetTextSize( spaced )
	UI.TitleChip( ( sw - tw - 16 ) * 0.5, 3, spaced,
		{ font = "ZDEV_HUD_Title", bg = TH.warn, fg = TH.chipText, padX = 8, padY = 2 } )
end

CHUD.Register( "editmode", {
	label      = "EDITOR BANNERS",
	fullscreen = true,
	noEditor   = true,
	order      = 95,
	Paint = function( self, sw, sh, p, pri, sec )
		local cv = editConvars()

		if cv.env and cv.env:GetBool() then
			paintBanner( sw, "ZDEV // ENVIRONMENT EDIT MODE" )
			local toolIdx = cv.envTool and cv.envTool:GetInt() or 0
			local tool = ZDEV.EDIT and ZDEV.EDIT.ENVM and ZDEV.EDIT.ENVM.Tool[ toolIdx ]
			if tool then
				UI.Badge( sw * 0.05, sh * 0.25, "TOOL: " .. string.upper( tool.Name or "?" ),
					{ accent = TH.warn, font = "ZDEV_HUD_Label" } )
			end
			return
		end

		if cv.particle and cv.particle:GetBool() then
			paintBanner( sw, "ZDEV // PARTICLE EDIT MODE" )
		end
	end,
} )

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )
