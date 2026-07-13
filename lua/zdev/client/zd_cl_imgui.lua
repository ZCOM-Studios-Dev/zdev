--local _f = 'zdev/client/zd_cl_imgui.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
--if ZDEV.FILE.Loaded( _f ) then return end

-- Singleton: re-includes return the already-built instance so every consumer
-- (render module, entities, etc.) shares one input/render state instead of
-- each spawning its own PreRender input hook.
if ZDEV and ZDEV.IMGUI and ZDEV.IMGUI.Start3D2D then return ZDEV.IMGUI end

local imgui = {}

imgui.skin = {
	background = Color(0, 0, 0, 0),
	backgroundHover = Color(0, 0, 0, 0),

	border = Color(255, 255, 255),
	borderHover = Color(255, 127, 0),
	borderPress = Color(255, 80, 0),

	foreground = Color(255, 255, 255),
	foregroundHover = Color(255, 127, 0),
	foregroundPress = Color(255, 80, 0),
}

local devCvar = GetConVar("developer")
function imgui.IsDeveloperMode()
	return not imgui.DisableDeveloperMode and devCvar:GetInt() > 0
end

local _devMode = false -- cached local variable updated once in a while

function imgui.Hook(name, id, callback)
	local hookUniqifier = debug.getinfo(4).short_src
	hook.Add(name, "IMGUI / " .. id .. " / " .. hookUniqifier, callback)
end

local localPlayer
local gState = {}

local function shouldAcceptInput()
	-- don't process input during non-main renderpass
	if render.GetRenderTarget() ~= nil then
		return false
	end

	-- don't process input if we're doing VGUI stuff (and not in context menu)
	if vgui.CursorVisible() and vgui.GetHoveredPanel() ~= g_ContextMenu and not vgui.IsHoveringWorld() then
		return false
	end

	return true
end

imgui.Hook("PreRender", "Input", function()
	-- calculate mouse state
	if shouldAcceptInput() then
		local useBind = input.LookupBinding("+use", true)
		local attackBind = input.LookupBinding("+attack", true)
		local USE = useBind and input.GetKeyCode(useBind)
		local ATTACK = attackBind and input.GetKeyCode(attackBind)

		local wasPressing = gState.pressing
		gState.pressing = (USE and input.IsButtonDown(USE)) or (ATTACK and input.IsButtonDown(ATTACK))
		gState.pressed = not wasPressing and gState.pressing
	end

	-- reset per-frame tracking counters
	imgui._allFrameCalls      = {}
	imgui._callsThisFrame     = 0
	imgui._contextsThisFrame  = 0
	imgui._perfFrame          = 0
end)

imgui.Hook("PostRender", "Tracking", function()
	if imgui._tracking then
		imgui._lastContexts = imgui._allFrameCalls
	end
	imgui._lastCallsPerFrame    = imgui._callsThisFrame    or 0
	imgui._lastContextsPerFrame = imgui._contextsThisFrame or 0

	local head = (imgui._perfHistoryHead % 120) + 1
	imgui._perfHistory[head]   = (imgui._perfFrame or 0) * 1000
	imgui._perfHistoryHead     = head
end)

hook.Add("NotifyShouldTransmit", "IMGUI / ClearRenderBounds", function(ent, shouldTransmit)
	if shouldTransmit and ent._imguiRBExpansion then
		ent._imguiRBExpansion = nil
	end
end)

local traceResultTable = {}
local traceQueryTable = { output = traceResultTable, filter = {} }
local function isObstructed(eyePos, hitPos, ignoredEntity, ignoreParent)
	local q = traceQueryTable
	q.start = eyePos
	q.endpos = hitPos
	q.filter[1] = localPlayer
	q.filter[2] = ignoredEntity
	if ignoreParent == true and IsValid(ignoredEntity) then
		local parent = ignoredEntity:GetParent()
		if IsValid(parent) then
			q.filter[3] = parent
		else
			q.filter[3] = nil
		end
	else
		q.filter[3] = nil
	end

	local tr = util.TraceLine(q)
	if tr.Hit then
		return true, tr.Entity
	else
		return false
	end
end

function imgui.Start3D2D(pos, angles, scale, distanceHide, distanceFadeStart)
	if not IsValid(localPlayer) then
		localPlayer = LocalPlayer()
	end

	local _C_ok    = Color(80, 255, 120)
	local _C_skip  = Color(255, 200, 60)
	local _C_err   = Color(255, 80, 80)
	local _C_info  = Color(130, 200, 255)
	local _C_label = Color(180, 180, 180)

	if gState.shutdown == true then
		-- MsgC(_C_err, "[IMGUI] Start3D2D: SKIPPED — pipeline shut down\n")
		return
	end

	if gState.rendering == true then
		-- MsgC(_C_err, "[IMGUI] Start3D2D: ERROR — new context started while previous still rendering! Shutting down.\n")
		gState.shutdown = true
		return false
	end

	-- MsgC(_C_info, "[IMGUI] Start3D2D: pos=" .. tostring(pos) .. " scale=" .. tostring(scale) .. "\n")

	_devMode = imgui.IsDeveloperMode()

	local eyePos = localPlayer:EyePos()
	local eyePosToPos = pos - eyePos

	-- OPTIMIZATION: Test that we are in front of the UI
	do
		local normal = angles:Up()
		local dot = eyePosToPos:Dot(normal)

		if _devMode then gState._devDot = dot end

		-- since normal is pointing away from surface towards viewer, dot<0 is visible
		if dot >= 0 then
			-- MsgC(_C_skip, "[IMGUI] Start3D2D: CULLED — dot=" .. string.format("%.2f", dot) .. " (panel facing away)\n")
			return false
		end
	end

	-- OPTIMIZATION: Distance based fade/hide
	if distanceHide then
		local distance = eyePosToPos:Length()
		if distance > distanceHide then
			-- MsgC(_C_skip, "[IMGUI] Start3D2D: CULLED — dist=" .. string.format("%.1f", distance) .. " > hide=" .. tostring(distanceHide) .. "\n")
			return false
		end

		if _devMode then
			gState._devDist = distance
			gState._devHideDist = distanceHide
		end

		if distanceHide and distanceFadeStart and distance > distanceFadeStart then
			local blend = math.min(math.Remap(distance, distanceFadeStart, distanceHide, 1, 0), 1)
			render.SetBlend(blend)
			surface.SetAlphaMultiplier(blend)
		end
	end

	gState.rendering = true
	gState.pos = pos
	gState.angles = angles
	gState.scale = scale
	gState._contextStart = SysTime()
	if imgui._tracking then
		imgui._frameCalls = {}
		imgui._contextsThisFrame = imgui._contextsThisFrame + 1
	end

	--MsgC(Color(80,255,120), "[IMGUI] Start3D2D: cam.Start3D2D called — rendering OPEN\n")
	cam.Start3D2D(pos, angles, scale)
	draw.NoTexture()

	-- calculate mousepos
	if not vgui.CursorVisible() or vgui.IsHoveringWorld() then
		local tr = localPlayer:GetEyeTrace()
		local eyepos = tr.StartPos
		local eyenormal

		if vgui.CursorVisible() and vgui.IsHoveringWorld() then
			eyenormal = imgui.ScreenToVector(input.GetCursorPos())
		else
			eyenormal = tr.Normal
		end

		local planeNormal = angles:Up()

		local hitPos = util.IntersectRayWithPlane(eyepos, eyenormal, pos, planeNormal)
		if hitPos then
			local obstructed, obstructer = isObstructed(eyepos, hitPos, gState.entity, true)
			if obstructed then
				gState.mx = nil
				gState.my = nil

				if _devMode then gState._devInputBlocker = "collision " .. obstructer:GetClass() .. "/" .. obstructer:EntIndex() end
			else
				local diff = pos - hitPos

				-- This cool code is from Willox's keypad CalculateCursorPos
				local x = diff:Dot(-angles:Forward()) / scale
				local y = diff:Dot(-angles:Right()) / scale

				gState.mx = x
				gState.my = y
			end
		else
			gState.mx = nil
			gState.my = nil

			if _devMode then gState._devInputBlocker = "not looking at plane" end
		end
	else
		gState.mx = nil
		gState.my = nil

		if _devMode then gState._devInputBlocker = "not hovering world" end
	end

	if _devMode then gState._renderStarted = gState._contextStart end

	return true
end

function imgui.ScreenToVector(x, y)
	local view = render.GetViewSetup()
	local w, h = ScrW(), ScrH()
	local fov = view.fov
	if gState.weapon then
		fov = view.fovviewmodel
	end

	return util.AimVector(view.angles, fov, x, y, w, h)
end

function imgui.Weapon3D2D(weapon, pos, ang, scale, ...)
	gState.weapon = weapon
	local ret = imgui.Start3D2D(pos, ang, scale, ...)
	if not ret then
		gState.weapon = nil
	end
	return ret
end

function imgui.Entity3D2D(ent, lpos, lang, scale, ...)
	gState.entity = ent
	local ret = imgui.Start3D2D(ent:LocalToWorld(lpos), ent:LocalToWorldAngles(lang), scale, ...)
	if not ret then
		gState.entity = nil
	end
	return ret
end

local function calculateRenderBounds(x, y, w, h)
	local pos = gState.pos
	local fwd, right = gState.angles:Forward(), gState.angles:Right()
	local scale = gState.scale
	local firstCorner, secondCorner =
		pos + fwd * x * scale + right * y * scale,
		pos + fwd * (x + w) * scale + right * (y + h) * scale

	local minrb, maxrb = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)

	minrb.x = math.min(minrb.x, firstCorner.x, secondCorner.x)
	minrb.y = math.min(minrb.y, firstCorner.y, secondCorner.y)
	minrb.z = math.min(minrb.z, firstCorner.z, secondCorner.z)
	maxrb.x = math.max(maxrb.x, firstCorner.x, secondCorner.x)
	maxrb.y = math.max(maxrb.y, firstCorner.y, secondCorner.y)
	maxrb.z = math.max(maxrb.z, firstCorner.z, secondCorner.z)

	return minrb, maxrb
end

function imgui.ExpandRenderBoundsFromRect(x, y, w, h)
	local ent = gState.entity
	if IsValid(ent) then
		-- make sure we're not applying same expansion twice
		local expansion = ent._imguiRBExpansion
		if expansion then
			local ex, ey, ew, eh = unpack(expansion)
			if ex == x and ey == y and ew == w and eh == h then
				return
			end
		end

		local minrb, maxrb = calculateRenderBounds(x, y, w, h)

		ent:SetRenderBoundsWS(minrb, maxrb)
		if _devMode then
			--print("[IMGUI] Updated renderbounds of ", ent, " to ", minrb, "x", maxrb)
		end

		ent._imguiRBExpansion = {x, y, w, h}
	else
		if _devMode then
			--print("[IMGUI] Attempted to update renderbounds when entity is not valid!! ", debug.traceback())
		end
	end
end

local devOffset = Vector(0, 0, 30)
local devColours = {
	background = Color(0, 0, 0, 200),
	title = Color(78, 205, 196),
	mouseHovered = Color(0, 255, 0),
	mouseUnhovered = Color(255, 0, 0),
	pos = Color(255, 255, 255),
	distance = Color(200, 200, 200, 200),
	ang = Color(255, 255, 255),
	dot = Color(200, 200, 200, 200),
	angleToEye = Color(200, 200, 200, 200),
	renderTime = Color(255, 255, 255),
	renderBounds = Color(0, 0, 255)
}

local function developerText(str, x, y, clr)
	draw.SimpleText(
		str, "DefaultFixedDropShadow", x, y, clr, TEXT_ALIGN_CENTER, nil
	)
end

local function drawDeveloperInfo()
	local camAng = localPlayer:EyeAngles()
	camAng:RotateAroundAxis(camAng:Right(), 90)
	camAng:RotateAroundAxis(camAng:Up(), -90)

	cam.IgnoreZ(true)
	cam.Start3D2D(gState.pos + devOffset, camAng, 0.15)

	local bgCol = devColours["background"]
	surface.SetDrawColor(bgCol.r, bgCol.g, bgCol.b, bgCol.a)
	surface.DrawRect(-100, 0, 200, 140)

	local titleCol = devColours["title"]
	developerText("imgui developer", 0, 5, titleCol)

	surface.SetDrawColor(titleCol.r, titleCol.g, titleCol.b)
	surface.DrawLine(-50, 16, 50, 16)

	local mx, my = gState.mx, gState.my
	if mx and my then
		developerText(
			string.format("mouse: hovering %d x %d", mx, my),
			0, 20, devColours["mouseHovered"]
		)
	else
		developerText(
			string.format("mouse: %s", gState._devInputBlocker or ""),
			0, 20, devColours["mouseUnhovered"]
		)
	end

	local pos = gState.pos
	developerText(
		string.format("pos: %.2f %.2f %.2f", pos.x, pos.y, pos.z),
		0, 40, devColours["pos"]
	)

	developerText(
		string.format("distance %.2f / %.2f", gState._devDist or 0, gState._devHideDist or 0),
		0, 53, devColours["distance"]
	)

	local ang = gState.angles
	developerText(string.format("ang: %.2f %.2f %.2f", ang.p, ang.y, ang.r), 0, 75, devColours["ang"])
	developerText(string.format("dot %d", gState._devDot or 0), 0, 88, devColours["dot"])

	local angToEye = (pos - localPlayer:EyePos()):Angle()
	angToEye:RotateAroundAxis(ang:Up(), -90)
	angToEye:RotateAroundAxis(ang:Right(), 90)

	developerText(
		string.format("angle to eye (%d,%d,%d)", angToEye.p, angToEye.y, angToEye.r),
		0, 100, devColours["angleToEye"]
	)

	developerText(
		string.format("rendertime avg: %.2fms", (gState._devBenchAveraged or 0) * 1000),
		0, 120, devColours["renderTime"]
	)

	cam.End3D2D()
	cam.IgnoreZ(false)

	local ent = gState.entity
	if IsValid(ent) and ent._imguiRBExpansion then
		local ex, ey, ew, eh = unpack(ent._imguiRBExpansion)
		local minrb, maxrb = calculateRenderBounds(ex, ey, ew, eh)
		render.DrawWireframeBox(vector_origin, angle_zero, minrb, maxrb, devColours["renderBounds"])
	end
end

local function _track(callType, props)
	if not imgui._tracking then return end
	local entry = { type = callType }
	if props then for k, v in pairs(props) do entry[k] = v end end
	imgui._frameCalls[#imgui._frameCalls + 1] = entry
	imgui._callsThisFrame = imgui._callsThisFrame + 1
end

function imgui.xDebugRect(x, y, w, h, label, color)
	if not _devMode then return end
	_track("xDebugRect", {x=x, y=y, w=w, h=h, label=label})
	color = color or Color(0, 255, 0, 200)
	surface.SetDrawColor(color)
	surface.DrawOutlinedRect(x, y, w, h)
	if label then
		draw.SimpleText(label, "DefaultFixed", x + 2, y + 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

function imgui.xDebugText(x, y, text, color)
	if not _devMode then return end
	_track("xDebugText", {x=x, y=y, text=tostring(text)})
	draw.SimpleText(tostring(text), "DefaultFixed", x, y, color or Color(255, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function imgui.xDebugWatch(key, value)
	if not _devMode then return end
	_track("xDebugWatch", {key=tostring(key), value=tostring(value)})
	if not gState._watches then gState._watches = {} end
	gState._watches[#gState._watches + 1] = tostring(key) .. ": " .. tostring(value)
end

imgui.debugWatchX = 0
imgui.debugWatchY = 0

local _watchLineH = 14
local _watchBg    = Color(0, 0, 0, 180)
local _watchFg    = Color(255, 255, 150)

local function drawWatches()
	local watches = gState._watches
	if not watches then return end
	local wx, wy = imgui.debugWatchX, imgui.debugWatchY
	surface.SetDrawColor(_watchBg)
	surface.DrawRect(wx, wy, 200, #watches * _watchLineH + 4)
	for i, line in ipairs(watches) do
		draw.SimpleText(line, "DefaultFixed", wx + 4, wy + 2 + (i - 1) * _watchLineH, _watchFg, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	gState._watches = nil
end

function imgui.End3D2D()
	if gState then
		local _elapsed = SysTime() - (gState._contextStart or SysTime())
		imgui._perfFrame = (imgui._perfFrame or 0) + _elapsed

		if imgui._tracking then
			imgui._allFrameCalls[#imgui._allFrameCalls + 1] = {
				entity       = gState.entity or false,
				pos          = gState.pos,
				scale        = gState.scale,
				calls        = imgui._frameCalls,
				renderTimems = _elapsed * 1000,
			}
			imgui._frameCalls = {}
		end

		if _devMode then
			drawWatches()

			local renderTook = _elapsed
			gState._devBenchTests = (gState._devBenchTests or 0) + 1
			gState._devBenchTaken = (gState._devBenchTaken or 0) + renderTook
			if gState._devBenchTests == 100 then
				gState._devBenchAveraged = gState._devBenchTaken / 100
				gState._devBenchTests = 0
				gState._devBenchTaken = 0
			end
		end

		MsgC(Color(80,255,120), "[IMGUI] End3D2D: cam.End3D2D called — rendering CLOSED\n")
		gState.rendering = false
		cam.End3D2D()
		render.SetBlend(1)
		surface.SetAlphaMultiplier(1)

		if _devMode then
			drawDeveloperInfo()
		end

		gState.entity = nil
		gState.weapon = nil
	end
end

function imgui.CursorPos()
	local mx, my = gState.mx, gState.my
	return mx, my
end

function imgui.IsHovering(x, y, w, h)
	local mx, my = gState.mx, gState.my
	return mx and my and mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end
function imgui.IsPressing()
	return shouldAcceptInput() and gState.pressing
end
function imgui.IsPressed()
	return shouldAcceptInput() and gState.pressed
end

-- String->Bool mappings for whether font has been created
local _createdFonts = {}

-- Cached IMGUIFontNamd->GModFontName
local _imguiFontToGmodFont = {}

local EXCLAMATION_BYTE = string.byte("!")
function imgui.xFont(font, defaultSize)
	-- special font
	if string.byte(font, 1) == EXCLAMATION_BYTE then

		local existingGFont = _imguiFontToGmodFont[font]
		if existingGFont then
			return existingGFont
		end

		-- Font not cached; parse the font
		local name, size = font:match("!([^@]+)@(.+)")
		if size then size = tonumber(size) end

		if not size and defaultSize then
			name = font:match("^!([^@]+)$")
			size = defaultSize
		end

		local fontName = string.format("IMGUI_%s_%d", name, size)
		_imguiFontToGmodFont[font] = fontName
		if not _createdFonts[fontName] then
			ZDEV.FONT.Register(fontName, {
				font = name,
				size = size
			})
			_createdFonts[fontName] = true
		end

		return fontName
	end
	return font
end

function imgui.xButton(x, y, w, h, borderWidth, borderClr, hoverClr, pressColor)
	_track("xButton", {x=x, y=y, w=w, h=h})
	local bw = borderWidth or 1

	local bgColor = imgui.IsHovering(x, y, w, h) and imgui.skin.backgroundHover or imgui.skin.background
	local borderColor =
		((imgui.IsPressing() and imgui.IsHovering(x, y, w, h)) and (pressColor or imgui.skin.borderPress))
		or (imgui.IsHovering(x, y, w, h) and (hoverClr or imgui.skin.borderHover))
		or (borderClr or imgui.skin.border)

	surface.SetDrawColor(bgColor)
	surface.DrawRect(x, y, w, h)

	if bw > 0 then
		surface.SetDrawColor(borderColor)

		surface.DrawRect(x, y, w, bw)
		surface.DrawRect(x, y + bw, bw, h - bw * 2)
		surface.DrawRect(x, y + h-bw, w, bw)
		surface.DrawRect(x + w - bw + 1, y, bw, h)
	end

	return shouldAcceptInput() and imgui.IsHovering(x, y, w, h) and gState.pressed
end

function imgui.xCursor(x, y, w, h)
	_track("xCursor", {x=x, y=y, w=w, h=h})
	local fgColor = imgui.IsPressing() and imgui.skin.foregroundPress or imgui.skin.foreground
	local mx, my = gState.mx, gState.my

	if not mx or not my then return end

	if x and w and (mx < x or mx > x + w) then return end
	if y and h and (my < y or my > y + h) then return end

	local cursorSize = math.ceil(0.3 / gState.scale)
	surface.SetDrawColor(fgColor)
	surface.DrawLine(mx - cursorSize, my, mx + cursorSize, my)
	surface.DrawLine(mx, my - cursorSize, mx, my + cursorSize)
end

function imgui.xTextButton(text, font, x, y, w, h, borderWidth, color, hoverClr, pressColor)
	_track("xTextButton", {x=x, y=y, w=w, h=h, text=text})
	local fgColor =
		((imgui.IsPressing() and imgui.IsHovering(x, y, w, h)) and (pressColor or imgui.skin.foregroundPress))
		or (imgui.IsHovering(x, y, w, h) and (hoverClr or imgui.skin.foregroundHover))
		or (color or imgui.skin.foreground)

	local clicked = imgui.xButton(x, y, w, h, borderWidth, color, hoverClr, pressColor)

	font = imgui.xFont(font, math.floor(h * 0.618))
	draw.SimpleText(text, font, x + w / 2, y + h / 2, fgColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	return clicked
end

-- ── Call tracking ────────────────────────────────────────────────────────────
-- Set imgui._tracking = true to enable; all widget calls record to _lastContexts.
imgui._tracking             = false
imgui._frameCalls           = {}
imgui._allFrameCalls        = {}
imgui._lastContexts         = {}
imgui._perfHistory          = {}
imgui._perfHistoryHead      = 0
imgui._perfFrame            = 0
imgui._contextsThisFrame    = 0
imgui._callsThisFrame       = 0
imgui._lastCallsPerFrame    = 0
imgui._lastContextsPerFrame = 0

function imgui.xPanel(x, y, w, h, bgColor, borderColor, bw)
	_track("xPanel", {x=x, y=y, w=w, h=h})
	bw = bw or 0
	bgColor = bgColor or imgui.skin.background
	borderColor = borderColor or imgui.skin.border

	surface.SetDrawColor(bgColor)
	surface.DrawRect(x, y, w, h)

	if bw > 0 then
		surface.SetDrawColor(borderColor)
		surface.DrawRect(x, y, w, bw)
		surface.DrawRect(x, y + bw, bw, h - bw * 2)
		surface.DrawRect(x, y + h - bw, w, bw)
		surface.DrawRect(x + w - bw + 1, y, bw, h)
	end
end

function imgui.xProgressBar(x, y, w, h, value, min, max, fillColor, bgColor)
	_track("xProgressBar", {x=x, y=y, w=w, h=h, value=value})
	min = min or 0
	max = max or 1
	fillColor = fillColor or imgui.skin.foreground
	bgColor = bgColor or imgui.skin.background

	surface.SetDrawColor(bgColor)
	surface.DrawRect(x, y, w, h)

	local fraction = math.Clamp((value - min) / (max - min), 0, 1)
	if fraction > 0 then
		surface.SetDrawColor(fillColor)
		surface.DrawRect(x, y, math.floor(w * fraction), h)
	end
end

local _matCache = {}
function imgui.xIcon(mat, x, y, w, h, color)
	_track("xIcon", {x=x, y=y, w=w, h=h})
	color = color or color_white

	if type(mat) == "string" then
		if not _matCache[mat] then
			_matCache[mat] = Material(mat)
		end
		mat = _matCache[mat]
	end

	surface.SetMaterial(mat)
	surface.SetDrawColor(color)
	surface.DrawTexturedRect(x, y, w, h)
end

ZDEV = ZDEV or {}
ZDEV.IMGUI = imgui

--ZDEV.FILE.SetLoaded( _f )
              
return imgui