local _f = 'zdev/client/hud/zd_cl_hud_msg.lua';
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if not ZDEV.CHUD then ZDEV.CHUD = {} end
ZDEV.CHUD.MSGS = ZDEV.CHUD.MSGS or {}

local LP = LocalPlayer()
local lp_pos, lp_ang, lp_fwd
local SW, SH = ScrW(), ScrH()
local SS = ScreenScale

local function CONV_HUD_CLR_PRI() return string.ToColor( GetConVarString("zdev_hud_clr_pri") ) end
local function CONV_HUD_CLR_SEC() return string.ToColor( GetConVarString("zdev_hud_clr_sec") ) end

local icon = {
	info = "vgui/icon/ui/Info.png",
	help = "vgui/icon/ui/Help.png",
	warn = "vgui/icon/ui/Warning.png",
	busy = "vgui/icon/ui/busy.png",
	comm = "vgui/icon/ui/Comment.png",
	flag = "vgui/icon/ui/flag.png",
	wrld = "vgui/icon/ui/world.png"
}

--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	MESSAGE SYSTEM (2D on-screen)
	Displays typed notifications: info, hints, warnings, errors, announcements.
	Messages are positioned by type and stack vertically. Each has a duration
	after which it automatically fades out and is removed.

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

local MSG_TYPES = {
	[HUDMSG_INFO]     = { x = SW*0.05,  y = SH*0.50, fnt = "roboto-cn", icon = Material(icon.info), prefix = "INFO",    al_h = TEXT_ALIGN_LEFT,   clr = Color(200,200,200),  time = 3 },
	[HUDMSG_HINT]     = { x = SW*0.05,  y = SH*0.30, fnt = "extros",    icon = Material(icon.help), prefix = "HINT",    al_h = TEXT_ALIGN_LEFT,   clr = Color(255,200,50),   time = 3 },
	[HUDMSG_WARN]     = { x = SW*0.05,  y = SH*0.30, fnt = "extros",    icon = Material(icon.warn), prefix = "WARNING", al_h = TEXT_ALIGN_LEFT,   clr = Color(255,150,0),    time = 3 },
	[HUDMSG_ERROR]    = { x = SW*0.05,  y = SH*0.30, fnt = "extros",    icon = Material(icon.busy), prefix = "ERROR",   al_h = TEXT_ALIGN_LEFT,   clr = Color(255,100,50),   time = 3 },
	[HUDMSG_ANNOUNCE] = { x = SW*0.5,   y = SH*0.2,  fnt = "unica",     icon = Material(icon.comm), prefix = "/!\\",    al_h = TEXT_ALIGN_CENTER, clr = Color(255,255,255),  time = 3 },
}

-- Active message stack: sequential integer-indexed table for draw order
local MESSAGES = {}
local i_msgid = 0

local m_mar = { L = 3, T = 4, R = 3, B = 4 }
local m_pad = { L = 6, T = 3, R = 6, B = 3 }
local MSG_FADE_TIME = 0.5

local function PaintMessages()
	LP = LocalPlayer()
	if not (LP and IsValid(LP)) then return end

	local now = RealTime()
	local slot = 0

	for i = #MESSAGES, 1, -1 do
		local m = MESSAGES[i]
		local def = MSG_TYPES[m.type]
		if not def then
			table.remove(MESSAGES, i)
		else
			local elapsed = now - m.startTime
			local remaining = m.time - elapsed

			-- Remove expired messages
			if remaining <= 0 then
				table.remove(MESSAGES, i)
			else
				-- Calculate alpha for fade-in/fade-out
				local alpha = 255
				if elapsed < 0.3 then
					alpha = (elapsed / 0.3) * 255
				elseif remaining < MSG_FADE_TIME then
					alpha = (remaining / MSG_FADE_TIME) * 255
				end
				alpha = math.Clamp(alpha, 0, 255)

				local m_fnt = def.fnt
				local m_clr = ColorAlpha(def.clr, alpha)
				local m_x, m_y = def.x, def.y
				local m_mat_w, m_mat_h = 24, 24

				local m_pre_w, m_pre_h = ZDEV.UTIL.GetTextSize(def.prefix, m_fnt)
				local m_txt_w, m_txt_h = ZDEV.UTIL.GetTextSize(m.text, m_fnt)
				local m_w = m_mat_w + m_pad.L + m_pre_w + m_pad.L + m_txt_w + m_pad.R
				local m_h = math.max(m_mat_h, m_pre_h, m_txt_h) + m_pad.T + m_pad.B

				local m_y_1 = m_y + slot * (m_h + m_mar.T)
				slot = slot + 1

				-- Background box
				draw.RoundedBox(6, m_x - m_pad.L, m_y_1 - m_pad.T, m_w, m_h, ColorAlpha(Color(0, 0, 0, 150), alpha / 255))

				-- Icon
				ZDEV.DRAW.TexturedRect(m_x, m_y_1, m_mat_w, m_mat_h, def.icon, ColorAlpha(color_white, alpha))

				-- Prefix
				draw.DrawText(def.prefix, m_fnt, m_x + m_mat_w + m_pad.L, m_y_1, m_clr, def.al_h, TEXT_ALIGN_CENTER)

				-- Main text
				draw.DrawText(m.text, m_fnt, m_x + m_mat_w + m_pad.L + m_pre_w + m_pad.L, m_y_1, m_clr, def.al_h, TEXT_ALIGN_CENTER)
			end
		end
	end
end


--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	MARKER SYSTEM (3D world-positioned)
	Markers track a world position or entity and project to screen space.

	Lifecycle:
	  1. CALLOUT PHASE (0 → calloutDuration):
	     Icon + text are both visible, text fades out at the end.
	  2. ICON-ONLY PHASE (calloutDuration → duration):
	     Only the icon is drawn at the marker position.
	     Text reappears if the player is looking within ~15 degrees
	     AND is within lookDistance units of the marker.
	  3. EXPIRY: marker fades out and is removed after duration.

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

-- Marker defaults (can be overridden per-marker)
local MARKER_DEFAULTS = {
	icon        = Material(icon.flag),
	iconW       = 24,
	iconH       = 24,
	iconClr     = Color(100, 255, 100, 255),
	font        = "roboto-cn",
	textClr     = Color(255, 255, 255, 255),
	bgClr       = Color(0, 0, 0, 160),
	duration    = 10,
	calloutDur  = 3,
	lookAngle   = 15,
	lookDist    = 1500,
}

local MARKERS = {}
local i_markerid = 0

-- Cosine of the look-angle threshold (precomputed for default, recalculated per marker)
local COS_15 = math.cos(math.rad(15))

local function PaintMarkers()
	LP = LocalPlayer()
	if not (LP and IsValid(LP)) then return end

	lp_pos = LP:EyePos()
	lp_fwd = LP:EyeAngles():Forward()
	local now = RealTime()

	for i = #MARKERS, 1, -1 do
		local mk = MARKERS[i]

		-- Resolve world position from entity or static pos
		local wpos
		if mk.ent and IsValid(mk.ent) then
			wpos = mk.ent:WorldSpaceCenter() or mk.ent:GetPos()
		elseif mk.pos then
			wpos = mk.pos
		end

		if wpos then
			local elapsed = now - mk.startTime
			local remaining = mk.duration - elapsed

			-- Remove expired markers
			if remaining <= 0 then
				table.remove(MARKERS, i)
			else
				-- Screen projection
				local scrData = wpos:ToScreen()
				if scrData.visible then
					local sx, sy = scrData.x, scrData.y

					-- Distance and look-direction from player
					local dirToMarker = (wpos - lp_pos)
					local dist = dirToMarker:Length()
					dirToMarker:Normalize()
					local dotProduct = lp_fwd:Dot(dirToMarker)
					local cosThreshold = math.cos(math.rad(mk.lookAngle))

					-- Determine phase
					local inCallout = elapsed < mk.calloutDur
					local isLooking = (dotProduct >= cosThreshold) and (dist <= mk.lookDist)

					-- Whether to show text this frame
					local showText = inCallout or isLooking

					-- Master alpha: fade in at start, fade out near expiry
					local masterAlpha = 255
					if elapsed < 0.3 then
						masterAlpha = (elapsed / 0.3) * 255
					elseif remaining < 0.5 then
						masterAlpha = (remaining / 0.5) * 255
					end
					masterAlpha = math.Clamp(masterAlpha, 0, 255)

					-- Text alpha: additional fade at end of callout phase
					local textAlpha = masterAlpha
					if inCallout then
						local calloutRemaining = mk.calloutDur - elapsed
						if calloutRemaining < 0.5 and not isLooking then
							textAlpha = (calloutRemaining / 0.5) * masterAlpha
						end
					elseif isLooking then
						-- Smooth text fade-in when player starts looking at marker
						textAlpha = masterAlpha
					end
					textAlpha = math.Clamp(textAlpha, 0, 255)

					-- Scale icon by distance (shrink with distance, clamp range)
					local distFrac = math.Clamp(1 - (dist / mk.lookDist), 0.4, 1.0)
					local iw = mk.iconW * distFrac
					local ih = mk.iconH * distFrac

					-- Draw icon (always visible while marker is alive)
					ZDEV.DRAW.TexturedRect(sx - iw * 0.5, sy - ih * 0.5, iw, ih, mk.icon, ColorAlpha(mk.iconClr, masterAlpha))

					-- Draw text (callout phase or looking at marker)
					if showText and textAlpha > 5 then
						local txt_w, txt_h = ZDEV.UTIL.GetTextSize(mk.text, mk.font)
						local box_w = txt_w + 12
						local box_h = txt_h + 6
						local bx = sx - box_w * 0.5
						local by = sy - ih * 0.5 - box_h - 4

						-- Background
						draw.RoundedBox(4, bx, by, box_w, box_h, ColorAlpha(mk.bgClr, textAlpha * 0.7))

						-- Text
						draw.DrawText(mk.text, mk.font, sx, by + 3, ColorAlpha(mk.textClr, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
					end
				end
			end
		end
	end
end


--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	HUDPAINT HOOKS

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

-- ZDEV_UID: ZDEV_FUNC_2E1DF3A6 | Path: ZDEV.CHUD.DrawMessages
function ZDEV.CHUD.DrawMessages()
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive()) then return end

	if GetConVar("zdev_hud_messages"):GetBool() then
		if ZDEV.CHUD.PushParallax then ZDEV.CHUD.PushParallax("messages") end
		PaintMessages()
		if ZDEV.CHUD.PopParallax then ZDEV.CHUD.PopParallax() end
	end
end
hook.Add("HUDPaint", "ZDEV.CHUD.DrawMessages", ZDEV.CHUD.DrawMessages)

-- ZDEV_UID: ZDEV_FUNC_2018274D | Path: ZDEV.CHUD.DrawMarkers
function ZDEV.CHUD.DrawMarkers()
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive()) then return end

	if GetConVar("zdev_hud_markers"):GetBool() then
		-- Markers project from world positions; we deliberately do NOT push
		-- parallax on them — the world-space projection already accounts for
		-- camera movement, and shifting them by the visor offset would make
		-- them detach from their referenced entities.
		PaintMarkers()
	end
end
hook.Add("HUDPaint", "ZDEV.CHUD.DrawMarkers", ZDEV.CHUD.DrawMarkers)


--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	PUBLIC API: ZDEV.CHUD.AddMessage
	Add a 2D HUD message to the stack.

	@param msgType  number   HUDMSG_INFO / HUDMSG_HINT / HUDMSG_WARN / HUDMSG_ERROR / HUDMSG_ANNOUNCE
	@param text     string   Message text to display
	@param duration number   (optional) seconds to display, defaults to type default
	@return         number   Message ID (can be used to remove early)

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

function ZDEV.CHUD.AddMessage(msgType, text, duration)
	local def = MSG_TYPES[msgType]
	if not def then
		ErrorNoHalt("[ZDEV] Unknown message type: " .. tostring(msgType) .. "\n")
		return
	end

	i_msgid = i_msgid + 1

	table.insert(MESSAGES, {
		id        = i_msgid,
		type      = msgType,
		text      = text or "",
		time      = duration or def.time,
		startTime = RealTime(),
	})

	return i_msgid
end

function ZDEV.CHUD.RemoveMessage(id)
	for i, m in ipairs(MESSAGES) do
		if m.id == id then
			table.remove(MESSAGES, i)
			return true
		end
	end
	return false
end


--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	PUBLIC API: ZDEV.CHUD.AddMarker
	Add a 3D world marker to the draw stack.

	@param opts table  Marker configuration:
		.text        string   Text displayed during callout / look-at
		.pos         Vector   (required if no .ent) World position to track
		.ent         Entity   (optional) Entity to track (overrides pos)
		.icon        IMaterial (optional) Icon material
		.iconW       number   (optional) Icon width in pixels
		.iconH       number   (optional) Icon height in pixels
		.iconClr     Color    (optional) Icon tint color
		.font        string   (optional) Font name for text
		.textClr     Color    (optional) Text color
		.bgClr       Color    (optional) Background box color
		.duration    number   (optional) Total marker lifetime in seconds
		.calloutDur  number   (optional) Seconds text is shown initially
		.lookAngle   number   (optional) Degrees of tolerance for look-at reveal
		.lookDist    number   (optional) Max distance for look-at reveal
	@return          number   Marker ID (can be used to remove early)

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

function ZDEV.CHUD.AddMarker(opts)
	if not opts then return end
	if not opts.pos and not (opts.ent and IsValid(opts.ent)) then
		ErrorNoHalt("[ZDEV] AddMarker requires .pos (Vector) or .ent (Entity)\n")
		return
	end

	i_markerid = i_markerid + 1

	local mk = {
		id         = i_markerid,
		text       = opts.text or "",
		pos        = opts.pos,
		ent        = opts.ent,
		icon       = opts.icon       or MARKER_DEFAULTS.icon,
		iconW      = opts.iconW      or MARKER_DEFAULTS.iconW,
		iconH      = opts.iconH      or MARKER_DEFAULTS.iconH,
		iconClr    = opts.iconClr    or MARKER_DEFAULTS.iconClr,
		font       = opts.font       or MARKER_DEFAULTS.font,
		textClr    = opts.textClr    or MARKER_DEFAULTS.textClr,
		bgClr      = opts.bgClr      or MARKER_DEFAULTS.bgClr,
		duration   = opts.duration   or MARKER_DEFAULTS.duration,
		calloutDur = opts.calloutDur or MARKER_DEFAULTS.calloutDur,
		lookAngle  = opts.lookAngle  or MARKER_DEFAULTS.lookAngle,
		lookDist   = opts.lookDist   or MARKER_DEFAULTS.lookDist,
		startTime  = RealTime(),
	}

	table.insert(MARKERS, mk)

	zdev.log("I", "Added marker #" .. i_markerid .. ": " .. mk.text)
	return i_markerid
end

function ZDEV.CHUD.RemoveMarker(id)
	for i, mk in ipairs(MARKERS) do
		if mk.id == id then
			table.remove(MARKERS, i)
			zdev.log("I", "Removed marker #" .. id)
			return true
		end
	end
	return false
end

function ZDEV.CHUD.RemoveMarkerByName(name)
	for i = #MARKERS, 1, -1 do
		if MARKERS[i].text == name then
			table.remove(MARKERS, i)
		end
	end
end


--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	NET RECEIVERS
	Server → Client message delivery for both systems.

▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]

-- Receive 2D HUD messages from server (via ply:SendHUDMessage)
net.Receive("zdev_hud_msg_send", function()
	local txt  = net.ReadString()
	local mtyp = net.ReadUInt(3)
	local time = net.ReadFloat()

	-- For MARKER/WORLD types from old server API, route to marker system
	if mtyp == HUDMSG_MARKER then
		local data = net.ReadTable()
		if data.ent and IsValid(data.ent) then
			ZDEV.CHUD.AddMarker({
				text = txt,
				ent  = data.ent,
				duration = time,
			})
		end
		return
	elseif mtyp == HUDMSG_WORLD then
		local data = net.ReadTable()
		if data.pos then
			ZDEV.CHUD.AddMarker({
				text = txt,
				pos  = data.pos,
				duration = time,
			})
		end
		return
	end

	ZDEV.CHUD.AddMessage(mtyp, txt, time)
end)

-- Receive entity markers from server (via ply:AddEntMarker)
net.Receive("zdev_hud_marker_ent", function()
	local mid  = net.ReadString()
	local ent  = net.ReadEntity()
	local pos  = net.ReadVector()
	local mat  = net.ReadString()
	local clr  = net.ReadColor()
	local time = net.ReadFloat()

	if not (ent and IsValid(ent)) then return end

	ZDEV.CHUD.AddMarker({
		text     = mid,
		ent      = ent,
		pos      = pos,
		icon     = Material(mat),
		iconClr  = clr,
		duration = time,
	})
end)

-- Receive world markers (via ply:AddWorldMarker) with full opts
net.Receive("zdev_hud_marker_world", function()
	local text = net.ReadString()
	local pos  = net.ReadVector()
	local opts = net.ReadTable()

	-- Merge server opts into marker config
	local cfg = {
		text = text,
		pos  = pos,
	}
	if opts.icon     then cfg.icon     = Material(opts.icon) end
	if opts.iconClr  then cfg.iconClr  = opts.iconClr end
	if opts.iconW    then cfg.iconW    = opts.iconW end
	if opts.iconH    then cfg.iconH    = opts.iconH end
	if opts.textClr  then cfg.textClr  = opts.textClr end
	if opts.bgClr    then cfg.bgClr    = opts.bgClr end
	if opts.font     then cfg.font     = opts.font end
	if opts.duration then cfg.duration = opts.duration end
	if opts.calloutDur then cfg.calloutDur = opts.calloutDur end
	if opts.lookAngle then cfg.lookAngle = opts.lookAngle end
	if opts.lookDist  then cfg.lookDist  = opts.lookDist end

	ZDEV.CHUD.AddMarker(cfg)
end)

-- Remove entity marker by name
net.Receive("zdev_hud_marker_ent_remove", function()
	local mid = net.ReadString()
	local ent = net.ReadEntity()

	if not (ent and IsValid(ent)) then
		ErrorNoHalt("Cannot Remove HUD-Marker. Entity invalid\n")
		return
	end

	ZDEV.CHUD.RemoveMarkerByName(mid)
	zdev.log("I", "Removed HUD-Marker (" .. tostring(mid) .. ") for Entity: " .. tostring(ent))
end)

ZDEV.FILE.SetLoaded(_f)
