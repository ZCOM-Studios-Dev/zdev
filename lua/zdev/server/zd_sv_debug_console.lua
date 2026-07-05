local _f = 'zd_sv_debug_console.lua'
MsgC(Color(255,255,50), 'ZDEV File: ', color_white, _f .. '\n')

-- ConCommands BEFORE the reload guard so they re-register on zdev_reload
concommand.Add("zdev_debug_test", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	MsgC(Color(0, 255, 0), "[ZDEV] Test message 1\n")
	MsgC(Color(255, 0, 0), "Test error message\n")
	print("Test print message")
end)

concommand.Add("zdev_debug_spam", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local count = tonumber(args[1]) or 100
	for i = 1, count do
		Msg("[" .. i .. "] Spam test message\n")
	end
	MsgC(Color(0, 200, 200), "Sent " .. count .. " spam messages\n")
end)

if ZDEV.FILE.Loaded(_f) then return end

-- =============================================================================
-- ZDEV Debug Console - Server-side message interception and queuing
-- =============================================================================
-- Intercepts server output (Msg, MsgC, print, Error, etc.)
-- Queues messages and drains via tick hook
-- Manages flood protection, subscriber distribution and stats broadcast

ZDEV.DBUG = ZDEV.DBUG or {}

-- Message type constants: canonical ZDEV.DBUG.MSG_TYPE lives in
-- zdev/shared/zd_sh_debug_console.lua (included before this file).

-- Configuration (shared defaults, local fallbacks)
local CFG = ZDEV.DBUG.CONFIG or {}
local MAX_QUEUE = CFG.MAX_QUEUE or 3072
local MSGS_IN_TICK = CFG.MSGS_PER_TICK or 64
local CHUNK_SIZE = CFG.CHUNK_SIZE or 16384
local MAX_TEXT_LEN = CFG.MAX_TEXT_LEN or 65000
local STATS_INTERVAL = CFG.STATS_INTERVAL or 1

-- State
local Queue = { _head = 1, _tail = 1, _data = {} }
local InEPOE = false
local DrainingMessages = false
local Subscribers = {}
local CachedTransmitList = nil

-- Saved original functions. Stored on the ZDEV table so a zdev_reload
-- re-run captures the TRUE originals, not our own wrappers (double-wrap bug).
ZDEV.DBUG._Originals = ZDEV.DBUG._Originals or {}
local O = ZDEV.DBUG._Originals
O.Msg = O.Msg or _G.Msg
O.MsgC = O.MsgC or _G.MsgC
O.MsgN = O.MsgN or _G.MsgN or function(text) O.Msg(tostring(text) .. '\n') end
O.print = O.print or _G.print
O.Error = O.Error or _G.Error
O.ErrorNoHalt = O.ErrorNoHalt or _G.ErrorNoHalt

-- =============================================================================
-- Queue Operations
-- =============================================================================

function Queue:Count()
	return self._tail - self._head
end

function Queue:IsEmpty()
	return self:Count() == 0
end

function Queue:Push(msgType, text, color)
	self._data[self._tail] = {
		type = msgType or ZDEV.DBUG.MSG_TYPE.MSG,
		text = text or "",
		color = color or Color(255, 255, 255, 255)
	}
	self._tail = self._tail + 1

	-- Overflow detection
	if self:Count() > MAX_QUEUE then
		self:_HandleOverflow()
	end
end

function Queue:PullN(n)
	local result = {}
	local count = math.min(n, self:Count())

	for i = 1, count do
		table.insert(result, self._data[self._head])
		self._data[self._head] = nil
		self._head = self._head + 1
	end

	return result
end

function Queue:_HandleOverflow()
	-- Clear FIRST, and log via the saved original — logging through the
	-- intercepted MsgC would push into the still-full queue and recurse
	for i = self._head, self._tail - 1 do
		self._data[i] = nil
	end
	self._head = self._tail

	O.MsgC(Color(255, 0, 0), '[ZDEV] Debug queue overflow, clearing\n')

	-- Pause draining
	if DrainingMessages then
		hook.Remove("Tick", "ZDEV_DebugDrain")
		DrainingMessages = false
	end

	-- Resume after delay
	timer.Simple(1, function()
		ZDEV.DBUG._StartDrain()
	end)
end

-- Exposed for the stats broadcast
function ZDEV.DBUG.GetQueueDepth()
	return Queue:Count()
end

-- =============================================================================
-- Message Draining
-- =============================================================================

-- The old stuck-flag watchdog is replaced by the pcall teardown in the drain
-- tick below; remove a leftover timer from pre-rewrite loads
timer.Remove("ZDEV_DebugUnstuckEPOE")

function ZDEV.DBUG._StartDrain()
	if DrainingMessages or Queue:IsEmpty() then return end
	DrainingMessages = true

	hook.Add("Tick", "ZDEV_DebugDrain", function()
		if Queue:IsEmpty() then
			hook.Remove("Tick", "ZDEV_DebugDrain")
			DrainingMessages = false
			return
		end

		InEPOE = true
		local ok = pcall(function()
			local msgs = Queue:PullN(MSGS_IN_TICK)
			if #msgs > 0 then
				ZDEV.DBUG._SendMessages(msgs)
			end
		end)
		InEPOE = false

		if not ok then
			hook.Remove("Tick", "ZDEV_DebugDrain")
			DrainingMessages = false
		end
	end)
end

-- =============================================================================
-- Message Transport
-- =============================================================================

function ZDEV.DBUG._GetTransmitList()
	if CachedTransmitList then return CachedTransmitList end

	local list = {}
	for uid, ply in pairs(Subscribers) do
		if IsValid(ply) then
			table.insert(list, ply)
		else
			Subscribers[uid] = nil
		end
	end

	CachedTransmitList = list
	return list
end

function ZDEV.DBUG._InvalidateCache()
	CachedTransmitList = nil
end

function ZDEV.DBUG._SendMessages(msgs)
	local list = ZDEV.DBUG._GetTransmitList()
	if #list == 0 then return end

	local serialized = ZDEV.DBUG._SerializeMessages(msgs)

	-- Chunk the serialized blob; each net message carries an explicit
	-- byte-length prefix so the client never has to guess from bit counts.
	local pos = 1
	while pos <= #serialized do
		local chunk = string.sub(serialized, pos, pos + CHUNK_SIZE - 1)
		local isSeq = (pos + CHUNK_SIZE - 1) < #serialized

		net.Start("ZDEV_DebugMessages")
		net.WriteUInt(#chunk, 16)
		net.WriteData(chunk, #chunk)
		net.WriteBool(isSeq)
		net.Send(list)

		pos = pos + CHUNK_SIZE
	end
end

function ZDEV.DBUG._SerializeMessages(msgs)
	local parts = {}

	for _, msg in ipairs(msgs) do
		table.insert(parts, ZDEV.DBUG._SerializeMessage(msg))
	end

	return table.concat(parts)
end

function ZDEV.DBUG._SerializeMessage(msg)
	local typeNum = msg.type or ZDEV.DBUG.MSG_TYPE.MSG
	local text = msg.text or ""
	local color = msg.color or Color(255, 255, 255, 255)

	-- Length field is 2 bytes; truncate anything absurd
	if #text > MAX_TEXT_LEN then
		text = string.sub(text, 1, MAX_TEXT_LEN) .. "...[truncated]"
	end

	local textLen = string.len(text)

	-- Pack: type (1) + textLen (2) + text + color (4)
	local packed = string.char(typeNum)
	packed = packed .. string.char(bit.band(bit.rshift(textLen, 8), 255), bit.band(textLen, 255))
	packed = packed .. text
	packed = packed .. string.char(
		bit.band(color.r or 255, 255),
		bit.band(color.g or 255, 255),
		bit.band(color.b or 255, 255),
		bit.band(color.a or 255, 255)
	)

	return packed
end

-- =============================================================================
-- Subscriber Management
-- =============================================================================

function ZDEV.DBUG.Subscribe(ply)
	if not IsValid(ply) then return end
	Subscribers[ply:UserID()] = ply
	ZDEV.DBUG._InvalidateCache()
end

function ZDEV.DBUG.Unsubscribe(ply)
	if not IsValid(ply) then return end
	Subscribers[ply:UserID()] = nil
	ZDEV.DBUG._InvalidateCache()
end

function ZDEV.DBUG.IsSubscribed(ply)
	if not IsValid(ply) then return false end
	return Subscribers[ply:UserID()] ~= nil
end

-- =============================================================================
-- Global Function Interception
-- =============================================================================

local function EnqueueMsg(msgType, text, color)
	-- Never queue output generated while we're draining (feedback loop guard)
	if InEPOE then return end
	-- Sidekick tap (zd_sv_sidekick.lua): queue-only, never prints, so no recursion.
	if ZDEV.DBUG.OnMessageTap then ZDEV.DBUG.OnMessageTap(msgType, text, color) end
	Queue:Push(msgType, text, color)
	ZDEV.DBUG._StartDrain()
end

local function JoinArgs(sep, ...)
	local parts = {}
	for _, v in ipairs({...}) do
		table.insert(parts, tostring(v))
	end
	return table.concat(parts, sep)
end

-- Consumers (panel/Sidekick) treat "\n" as the line terminator, so calls that
-- semantically end a console line must carry one even though their args don't.
local function EndLine(s)
	if string.sub(s, -1) ~= "\n" then return s .. "\n" end
	return s
end

function ZDEV.DBUG._InterceptFunctions()
	_G.Msg = function(...)
		EnqueueMsg(ZDEV.DBUG.MSG_TYPE.MSG, JoinArgs("", ...), Color(255, 255, 255))
		O.Msg(...)
	end

	-- MsgC accepts interleaved Colors and values; each Color switches the
	-- active color for what follows. Enqueue one segment per color run so the
	-- coloring survives and Colors are never tostring()'d into the text.
	_G.MsgC = function(...)
		local col = Color(255, 255, 255)
		local parts = {}
		for _, v in ipairs({...}) do
			if IsColor(v) then
				if #parts > 0 then
					EnqueueMsg(ZDEV.DBUG.MSG_TYPE.MSGC, table.concat(parts), col)
					parts = {}
				end
				col = v
			else
				table.insert(parts, tostring(v))
			end
		end
		if #parts > 0 then
			EnqueueMsg(ZDEV.DBUG.MSG_TYPE.MSGC, table.concat(parts), col)
		end
		O.MsgC(...)
	end

	_G.MsgN = function(...)
		EnqueueMsg(ZDEV.DBUG.MSG_TYPE.MSGN, EndLine(JoinArgs("", ...)), Color(255, 255, 255))
		O.MsgN(...)
	end

	_G.print = function(...)
		EnqueueMsg(ZDEV.DBUG.MSG_TYPE.PRINT, EndLine(JoinArgs("\t", ...)), Color(200, 200, 200))
		O.print(...)
	end

	_G.ErrorNoHalt = function(...)
		EnqueueMsg(ZDEV.DBUG.MSG_TYPE.ERROR, EndLine(JoinArgs("", ...)), Color(255, 90, 90))
		O.ErrorNoHalt(...)
	end

	_G.Error = function(...)
		EnqueueMsg(ZDEV.DBUG.MSG_TYPE.ERROR, EndLine(JoinArgs("", ...)), Color(255, 90, 90))
		O.Error(...)
	end
end

-- Capture runtime server Lua errors (thrown inside hooks/timers/entities).
-- These are printed by the engine directly, NOT via _G functions, so the
-- intercepts above never see them — this hook is what catches them.
-- Defer to ensure MSG_TYPE is fully initialized
timer.Simple(0.1, function()
	if not ZDEV.DBUG.MSG_TYPE then return end
	hook.Add("OnLuaError", "ZDEV_DebugLuaError", function(err, realm, stack, name, id)
		-- Re-check at call time: an error handler must never itself error
		local MT = ZDEV.DBUG.MSG_TYPE
		if not MT then return end
		EnqueueMsg(MT.ERROR, "[LUA ERROR] " .. tostring(err) .. "\n", Color(255, 60, 60))
	end)

	-- Capture client-side Lua errors reported to the server (replaces EPOE's
	-- gm_enginespew binary dependency for CERROR messages)
	hook.Add("OnClientLuaError", "ZDEV_DebugClientLuaError", function(err, ply, stack, name)
		local MT = ZDEV.DBUG.MSG_TYPE
		if not MT then return end
		local who = IsValid(ply) and ply:Nick() or "?"
		EnqueueMsg(MT.CERROR, "[CL ERROR @" .. who .. "] " .. tostring(err) .. "\n", Color(255, 140, 60))
	end)
end)

-- =============================================================================
-- Stats Broadcast (dashboard support)
-- =============================================================================

timer.Create("ZDEV_DebugStatsBroadcast", STATS_INTERVAL, 0, function()
	local list = ZDEV.DBUG._GetTransmitList()
	if #list == 0 then return end

	net.Start("ZDEV_DebugStats")
	net.WriteUInt(math.min(Queue:Count(), 65535), 16)          -- queue depth
	net.WriteUInt(math.min(#list, 255), 8)                     -- subscribers
	net.WriteUInt(math.min(ents.GetCount(), 65535), 16)        -- entity count
	net.WriteUInt(math.min(player.GetCount(), 255), 8)         -- player count
	net.WriteUInt(math.floor(collectgarbage("count")), 32)     -- server Lua KB
	net.WriteUInt(math.max(0, math.floor(CurTime())), 32)      -- uptime seconds
	net.WriteUInt(math.floor(1 / engine.TickInterval() + 0.5), 16) -- tickrate
	net.Send(list)
end)

-- =============================================================================
-- Initialization
-- =============================================================================

function ZDEV.DBUG.Initialize()
	if not SERVER then return end

	MsgC(Color(0, 255, 0), '[ZDEV] Debug Console initializing\n')

	-- Register net messages
	util.AddNetworkString("ZDEV_DebugSubscribe")
	util.AddNetworkString("ZDEV_DebugMessages")
	util.AddNetworkString("ZDEV_DebugStats")

	-- Intercept functions
	ZDEV.DBUG._InterceptFunctions()

	-- Subscribe/Unsubscribe handlers (admin only, like EPOE)
	if ZDEV.DBUG.Subscribe then
		net.Receive("ZDEV_DebugSubscribe", function(len, ply)
			if not IsValid(ply) then return end
			if not (ply:IsAdmin() or game.SinglePlayer()) then
				MsgC(Color(255, 165, 0), '[ZDEV] ' .. ply:Nick() .. ' denied debug console (not admin)\n')
				return
			end

			if ZDEV.DBUG.Subscribe then
				ZDEV.DBUG.Subscribe(ply)
				MsgC(Color(0, 200, 200), '[ZDEV] ' .. ply:Nick() .. ' subscribed to debug console\n')
			end
		end)
	end

	hook.Add("PlayerDisconnected", "ZDEV_DebugUnsubscribe", function(ply)
		ZDEV.DBUG.Unsubscribe(ply)
	end)

	MsgC(Color(0, 255, 0), '[ZDEV] Debug Console ready\n')
end

-- Initialize on load
if SERVER then
	ZDEV.DBUG.Initialize()
end

ZDEV.FILE.SetLoaded(_f)
