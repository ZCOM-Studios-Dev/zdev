local _f = 'zd_cl_debug_console.lua'
MsgC(Color(255,255,50), 'ZDEV File: ', color_white, _f .. '\n')

if not CLIENT then return end

-- ConCommands BEFORE the reload guard so they re-register on zdev_reload
concommand.Add("zdev_debug_console_open", function()
	if not IsValid(ZDEV.VGUI.DebugConsole) then
		ZDEV.VGUI.CreateDebugConsole()
	end
	ZDEV.VGUI.DebugConsole:SetVisible(true)
	ZDEV.VGUI.DebugConsole:MakePopup()
end)

concommand.Add("zdev_debug_console_close", function()
	if IsValid(ZDEV.VGUI.DebugConsole) then
		ZDEV.VGUI.DebugConsole:SetVisible(false)
	end
end)

concommand.Add("zdev_debug_console_toggle", function()
	if not IsValid(ZDEV.VGUI.DebugConsole) then
		ZDEV.VGUI.CreateDebugConsole()
	end
	ZDEV.VGUI.DebugConsole:SetVisible(not ZDEV.VGUI.DebugConsole:IsVisible())
	if ZDEV.VGUI.DebugConsole:IsVisible() then
		ZDEV.VGUI.DebugConsole:MakePopup()
	end
end)

if ZDEV.FILE.Loaded(_f) then return end

-- =============================================================================
-- ZDEV Debug Console - Client-side receiver and reassembly
-- =============================================================================
-- Receives chunked net messages from server
-- Reassembles complete message sequences
-- Parses binary format, tracks live stats, and fires hook for display

ZDEV.DBUG = ZDEV.DBUG or {}

-- Reassembly buffer for chunked messages
local ReassemblyBuffer = ""

-- Message history (for scrollback, UI, etc.)
ZDEV.DBUG.MessageHistory = ZDEV.DBUG.MessageHistory or {}
local MAX_HISTORY = (ZDEV.DBUG.CONFIG or {}).MAX_MESSAGES_HISTORY or 5000

-- =============================================================================
-- Live Stats (feeds the dashboard; accumulates even while the panel is closed)
-- =============================================================================

ZDEV.DBUG.Stats = ZDEV.DBUG.Stats or {
	total = 0,        -- messages received since connect
	bytes = 0,        -- payload bytes received
	byType = {},      -- [msgType] = count
	buckets = {},     -- [floor(RealTime())] = msgs that second (rolling 60s)
	server = nil      -- last ZDEV_DebugStats payload from the server
}

local function StatBump(msg)
	local S = ZDEV.DBUG.Stats
	S.total = S.total + 1
	S.byType[msg.type] = (S.byType[msg.type] or 0) + 1

	local sec = math.floor(RealTime())
	S.buckets[sec] = (S.buckets[sec] or 0) + 1
	for k in pairs(S.buckets) do
		if k < sec - 60 then S.buckets[k] = nil end
	end
end

-- Messages per second, averaged over the last n complete seconds
function ZDEV.DBUG.GetMessageRate(n)
	n = n or 5
	local S = ZDEV.DBUG.Stats
	local now = math.floor(RealTime())
	local sum = 0
	for i = 1, n do
		sum = sum + (S.buckets[now - i] or 0)
	end
	return sum / n
end

-- =============================================================================
-- Net Message Handlers
-- =============================================================================

net.Receive("ZDEV_DebugMessages", function(len)
	local chunkLen = net.ReadUInt(16)
	local chunk = net.ReadData(chunkLen)
	local isSeq = net.ReadBool()

	ZDEV.DBUG.Stats.bytes = ZDEV.DBUG.Stats.bytes + chunkLen
	ReassemblyBuffer = ReassemblyBuffer .. chunk

	-- If this is not part of a sequence, process the buffer
	if not isSeq then
		ZDEV.DBUG._ProcessMessageBuffer(ReassemblyBuffer)
		ReassemblyBuffer = ""
	end
end)

net.Receive("ZDEV_DebugStats", function()
	ZDEV.DBUG.Stats.server = {
		queue = net.ReadUInt(16),
		subs = net.ReadUInt(8),
		ents = net.ReadUInt(16),
		plys = net.ReadUInt(8),
		luaKB = net.ReadUInt(32),
		uptime = net.ReadUInt(32),
		tickrate = net.ReadUInt(16),
		received = RealTime()
	}
	hook.Run("ZDEV_DebugStats", ZDEV.DBUG.Stats.server)
end)

-- =============================================================================
-- Message Parsing
-- =============================================================================

function ZDEV.DBUG._ProcessMessageBuffer(buf)
	local pos = 1

	-- Each message needs at least: header (3) + color (4) = 7 bytes
	while pos + 6 <= #buf do
		-- Read header: type (1) + textLen (2)
		local typeNum = string.byte(buf, pos)
		local textLen = bit.bor(
			bit.lshift(string.byte(buf, pos + 1), 8),
			string.byte(buf, pos + 2)
		)
		pos = pos + 3

		-- Sanity check: full body must fit in the buffer
		if pos + textLen + 3 > #buf + 1 then
			MsgC(Color(255, 0, 0), '[ZDEV] Debug: malformed message, skipping remainder\n')
			break
		end

		-- Read text
		local text = string.sub(buf, pos, pos + textLen - 1)
		pos = pos + textLen

		-- Read color (4 bytes: R, G, B, A)
		local r = string.byte(buf, pos)
		local g = string.byte(buf, pos + 1)
		local b = string.byte(buf, pos + 2)
		local a = string.byte(buf, pos + 3) or 255
		pos = pos + 4

		-- Reconstruct message object
		local msg = {
			type = typeNum,
			text = text,
			color = Color(r, g, b, a),
			timestamp = CurTime(),
			rtime = os.time()
		}

		-- Add to history + stats
		ZDEV.DBUG._AddToHistory(msg)
		StatBump(msg)

		-- Fire hook for listeners (UI panels, filters, etc.)
		hook.Run("ZDEV_DebugMessage", msg)
	end
end

-- =============================================================================
-- Message History
-- =============================================================================

function ZDEV.DBUG._AddToHistory(msg)
	table.insert(ZDEV.DBUG.MessageHistory, msg)

	-- Trim history if it exceeds max
	while #ZDEV.DBUG.MessageHistory > MAX_HISTORY do
		table.remove(ZDEV.DBUG.MessageHistory, 1)
	end
end

function ZDEV.DBUG.GetHistory()
	return ZDEV.DBUG.MessageHistory
end

function ZDEV.DBUG.ClearHistory()
	ZDEV.DBUG.MessageHistory = {}
end

-- =============================================================================
-- Subscription
-- =============================================================================

local IsSubscribed = false

function ZDEV.DBUG.Subscribe()
	if IsSubscribed then return end
	IsSubscribed = true

	net.Start("ZDEV_DebugSubscribe")
	net.SendToServer()

	MsgC(Color(0, 200, 200), '[ZDEV] Subscribed to debug console\n')
end

-- Subscribe when the player spawns
hook.Add("InitPostEntity", "ZDEV_DebugSubscribe", function()
	ZDEV.DBUG.Subscribe()
end)

-- After a zdev_reload mid-session InitPostEntity has already fired;
-- re-subscribe immediately (server-side Subscribe is idempotent)
if IsValid(LocalPlayer()) then
	ZDEV.DBUG.Subscribe()
end

-- =============================================================================
-- Utility Functions
-- =============================================================================

-- Get a human-readable message type name (built once from the canonical
-- ZDEV.DBUG.MSG_TYPE table — Sweep Phase 5)
local _TYPE_NAMES
function ZDEV.DBUG.GetMessageTypeName(typeNum)
	if not _TYPE_NAMES then
		_TYPE_NAMES = {}
		for name, num in pairs(ZDEV.DBUG.MSG_TYPE) do
			_TYPE_NAMES[num] = name
		end
	end
	return _TYPE_NAMES[typeNum] or "UNKNOWN"
end

-- Check if message is a specific type
function ZDEV.DBUG.MessageIsType(msg, typeNum)
	if not msg then return false end
	return msg.type == typeNum
end

ZDEV.FILE.SetLoaded(_f)
