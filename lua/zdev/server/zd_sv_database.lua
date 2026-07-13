local _f = 'zdev/server/zd_sv_database.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
-- NOTE: We intentionally do NOT skip on reload here.
-- The database system must always re-initialize to ensure
-- ZDEV.MSQL.Enabled and ZDEV.MSQL.TMysql are set, even after
-- a lua_openscript or auto-refresh. We guard against double-connect
-- inside ConnectToDatabase instead.

--[[
■■■■■■■■���■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■��■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ZDEV MODULAR ADAPTIVE MYSQL DATABASE SYSTEM
-- Uses TMysql4 (gm_tmysql4) for database connectivity.
-- Public API is unchanged from the MySQLoo version.
■■■■■■■■■■■■■■■■■■■■■■��■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
]]

ZDEV.MSQL = ZDEV.MSQL or {}
ZDEV.MSQL.Connections = ZDEV.MSQL.Connections or {}
ZDEV.MSQL.Pool = ZDEV.MSQL.Pool or {}
ZDEV.MSQL.Config = ZDEV.MSQL.Config or {}
ZDEV.MSQL.Status = ZDEV.MSQL.Status or {}

-- Default configuration
ZDEV.MSQL.DefaultConfig = {
    database = "zdev_test",
    username = "zdev",
    password = "(xi.OZYELzJNul8@",
    host = "127.0.0.1",
    port = 3306,
    reconnect_attempts = 3,
    max_reconnect_delay = 30
}

-- Load configuration from autorun or use defaults
local function LoadDatabaseConfig()
    if ZDEV.MSQL.Database then
        ZDEV.MSQL.Config = table.Copy(ZDEV.MSQL.Database)
    else
        ZDEV.MSQL.Config = table.Copy(ZDEV.MSQL.DefaultConfig)
    end
    -- Ensure port is a number (tmysql expects number, not string)
    ZDEV.MSQL.Config.port = tonumber(ZDEV.MSQL.Config.port) or 3306
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    INITIALIZATION
━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━���━]]

local function InitDatabaseSystem()
    zdev.log("I", "TMysql4 Init: Loading database config...")
    LoadDatabaseConfig()

    local config = ZDEV.MSQL.Config
    zdev.log("I", "TMysql4 Init: Config loaded - host=" .. (config.host or "?") .. " db=" .. (config.database or "?") .. " port=" .. tostring(config.port or "?") .. " user=" .. (config.username or "?"))

    -- Check if tmysql4 is available
    zdev.log("I", "TMysql4 Init: Attempting require('tmysql4')...")
    local has_tmysql, tmysql_err = pcall(require, "tmysql4")

    if not has_tmysql then
        zdev.log("E", "TMysql4 Init: require('tmysql4') FAILED: " .. tostring(tmysql_err))
        zdev.log("E", "TMysql4 Init: Ensure the correct DLL is in garrysmod/lua/bin/")
        zdev.log("E", "TMysql4 Init: Expected file: gmsv_tmysql4_" .. (jit.arch == "x64" and "win64" or "win32") .. ".dll")
        ZDEV.MSQL.Enabled = false
        return
    end

    -- TMysql4 registers itself as a global `tmysql` table rather than
    -- returning the module from require(). Read from the global.
    local tmysql_mod = tmysql
    zdev.log("I", "TMysql4 Init: require() ok. Global tmysql = " .. tostring(tmysql_mod) .. " type = " .. type(tmysql_mod))

    if not tmysql_mod then
        zdev.log("E", "TMysql4 Init: Global 'tmysql' table not found after require. DLL may be incompatible.")
        ZDEV.MSQL.Enabled = false
        return
    end

    ZDEV.MSQL.Enabled = true
    ZDEV.MSQL.TMysql = tmysql_mod

    -- Disconnect any stale connections from a previous load
    if ZDEV.MSQL.Connections and #ZDEV.MSQL.Connections > 0 then
        zdev.log("I", "TMysql4 Init: Cleaning up " .. #ZDEV.MSQL.Connections .. " stale connections from previous load")
        for i, conn in ipairs(ZDEV.MSQL.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    -- Reset state
    ZDEV.MSQL.Connections = {}
    ZDEV.MSQL.Pool = {}
    ZDEV.MSQL.Status = {
        connected = false,
        error = nil,
        last_error_time = 0,
        connection_count = 0
    }

    zdev.log("S", "TMysql4 Init: Database system initialized successfully")
    zdev.log("I", "TMysql4 Init: Module version: " .. tostring(tmysql_mod.Version or "unknown"))
    zdev.log("I", "TMysql4 Init: ZDEV.MSQL.Enabled = " .. tostring(ZDEV.MSQL.Enabled))
    zdev.log("I", "TMysql4 Init: ZDEV.MSQL.TMysql = " .. tostring(ZDEV.MSQL.TMysql))
end

--[[━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━��━━━━━���━━━━━━━━━
    CONNECTION
    tmysql.Connect() is synchronous — returns (db, err) immediately.
━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━��━━━━━━━━���━]]

local function ConnectToDatabase()
    if not ZDEV.MSQL.Enabled then
        zdev.log("W", "TMysql4 Connect: Cannot connect - system not enabled")
        return false, "Database system not enabled"
    end

    -- Guard against double-connect (e.g. on Lua refresh)
    if ZDEV.MSQL.Status.connected and #ZDEV.MSQL.Connections > 0 then
        zdev.log("I", "TMysql4 Connect: Already connected with " .. #ZDEV.MSQL.Connections .. " connections, skipping")
        return true
    end

    local config = ZDEV.MSQL.Config
    local attempts = 0
    local max_attempts = config.reconnect_attempts or 3

    local function attemptConnect()
        attempts = attempts + 1

        zdev.log("I", "TMysql4: Connection attempt " .. attempts .. "/" .. max_attempts
            .. " to " .. (config.host or "?") .. ":" .. (config.port or 3306)
            .. " db=" .. (config.database or "?") .. " user=" .. (config.username or "?"))

        -- tmysql.Connect(host, user, pass, db, port, unixSocket, clientFlags, callback)
        -- Returns: Database object, error string
        local db, err = ZDEV.MSQL.TMysql.Connect(
            config.host,
            config.username,
            config.password,
            config.database,
            config.port,
            nil, -- unix socket
            0    -- client flags
        )

        if err then
            zdev.log("E", "TMysql4: Connection failed (attempt " .. attempts .. "): " .. tostring(err))
            ZDEV.MSQL.Status.connected = false
            ZDEV.MSQL.Status.error = tostring(err)
            ZDEV.MSQL.Status.last_error_time = CurTime()

            if attempts < max_attempts then
                local delay = math.min(2 ^ attempts, config.max_reconnect_delay or 30)
                zdev.log("I", "TMysql4: Retrying in " .. delay .. " seconds...")
                timer.Simple(delay, attemptConnect)
            else
                zdev.log("E", "TMysql4: Maximum connection attempts reached. Database disabled.")
                hook.Run("ZDEV.Database.Error", err)
            end
            return false, err
        end

        if not db then
            local msg = "tmysql.Connect returned nil without error"
            zdev.log("E", "TMysql4: " .. msg)
            ZDEV.MSQL.Status.error = msg
            return false, msg
        end

        -- Connection successful
        zdev.log("S", "TMysql4: Database Connected Successfully!")
        ZDEV.MSQL.Status.connected = true
        ZDEV.MSQL.Status.error = nil

        -- Store connection
        table.insert(ZDEV.MSQL.Connections, db)
        ZDEV.MSQL.Status.connection_count = #ZDEV.MSQL.Connections

        -- Run a quick test query to get server version
        db:Query("SELECT VERSION() as version", function(results)
            if results and results[1] and results[1].status and results[1].data and results[1].data[1] then
                local version = results[1].data[1].version
                ZDEV.MSQL.Status.server_version = version
                zdev.log("I", "TMysql4: MySQL server version: " .. version)
            end
        end)

        -- Notify all modules that database is ready
        hook.Run("ZDEV.Database.Connected")
        return true
    end

    return attemptConnect()
end

--[[━━━━━━���━━━━━━━━━━━━━━━��━━━━━━━━���━━━━━��━━━━━━━━━━━━━
    CONNECTION POOL
━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function GetConnection()
    if not ZDEV.MSQL.Enabled or #ZDEV.MSQL.Connections == 0 then
        return nil
    end
    -- Return the first (primary) connection
    return ZDEV.MSQL.Connections[1]
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━
    QUERY EXECUTION
    Wraps TMysql4's callback-based API to match the existing
    ZDEV.MSQL.Query(sql, onSuccess, onError) signature.
━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function ExecuteQuery(query_string, callback_success, callback_error)
    if not ZDEV.MSQL.Enabled then
        if callback_error then callback_error("Database not enabled") end
        return
    end

    local db = GetConnection()
    if not db then
        -- Try to reconnect
        if not ZDEV.MSQL.Status.connected then
            zdev.log("W", "TMysql4: Not connected, attempting reconnect...")
            ConnectToDatabase()
            db = GetConnection()
        end

        if not db then
            if callback_error then callback_error("Database not connected") end
            return
        end
    end

    db:Query(query_string, function(results)
        local result = results[1]
        if not result then
            if callback_error then
                callback_error("No result returned", query_string)
            end
            return
        end

        if not result.status then
            -- Query failed
            if callback_error then
                callback_error(result.error or "Unknown error", query_string)
            end
            return
        end

        -- Query succeeded
        if callback_success then
            -- TMysql4 puts rows in result.data, affected rows in result.affected
            -- The existing API expects the data table directly as the first argument
            local data = result.data or {}
            -- Attach metadata that callers might check
            data.AFFECTED_ROWS = result.affected
            data.LAST_INSERT = result.lastid
            callback_success(data)
        end
    end)
end

-- Safe query wrapper with error logging
local function SafeQuery(query_string, callback_success, callback_error)
    local function safe_success(data)
        if callback_success then
            callback_success(data)
        end
    end

    local function safe_error(err, sql)
        zdev.log("E", "TMysql4 Query Error - SQL: " .. tostring(sql) .. " Error: " .. tostring(err))
        if callback_error then
            callback_error(err, sql)
        end
    end

    return ExecuteQuery(query_string, safe_success, safe_error)
end

--[[━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ESCAPE / STATUS / INFO HELPERS
━━━━━━━━━━━━���━━━━━━━━━━━━━━━━━���━━━━━��━━━━━��━━━━━━━━━���━━━]]

local function EscapeString(str)
    if not ZDEV.MSQL.Enabled or not str then return "" end
    local db = GetConnection()
    if not db then return tostring(str) end
    return db:Escape(tostring(str))
end

local function GetStatus()
    return ZDEV.MSQL.Status
end

local function GetConnectionCount()
    return #ZDEV.MSQL.Connections
end

-- TMysql4 doesn't expose ping/queueSize directly, so we use a test query
local function GetConnectionInfo()
    local info = {}
    for i, conn in ipairs(ZDEV.MSQL.Connections) do
        info[i] = {
            status = ZDEV.MSQL.Status.connected and 0 or 1,
            queue_size = 0, -- TMysql4 doesn't expose this
            ping = 0        -- We'll measure via test query in status handler
        }
    end
    return info
end

--[[━━━━━━━━━━━━━━━��━━━━━━━━━━━━━━━��━━━━━━━��━━━━━━━━━━━
    CLEANUP
━��━━━━━━━━��━━━━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function CleanupDatabase()
    for i, conn in ipairs(ZDEV.MSQL.Connections) do
        if conn then
            local ok, err = pcall(function() conn:Disconnect() end)
            if ok then
                zdev.log("I", "TMysql4: Disconnected connection #" .. i)
            else
                zdev.log("W", "TMysql4: Error disconnecting #" .. i .. ": " .. tostring(err))
            end
        end
    end
    ZDEV.MSQL.Connections = {}
    ZDEV.MSQL.Status.connected = false
    ZDEV.MSQL.Status.connection_count = 0
end

--[[━━━━━━━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━
    INITIALIZE AND CONNECT
��━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━]]

InitDatabaseSystem()

-- PUBLIC API must be assigned BEFORE ConnectToDatabase() is called.
-- On localhost, the tmysql4 connection callback fires synchronously,
-- which immediately triggers ZDEV.Database.Connected hooks (e.g. schema
-- migration) that call ZDEV.MSQL.Query before this file finishes executing.
ZDEV.MSQL.Query              = SafeQuery
ZDEV.MSQL.Execute            = ExecuteQuery
ZDEV.MSQL.Escape             = EscapeString
ZDEV.MSQL.GetStatus          = GetStatus
ZDEV.MSQL.GetConnectionCount = GetConnectionCount
ZDEV.MSQL.GetConnectionInfo  = GetConnectionInfo
ZDEV.MSQL.Initialize         = InitDatabaseSystem
ZDEV.MSQL.Connect            = ConnectToDatabase
ZDEV.MSQL.Reconnect          = function()
    CleanupDatabase()
    return ConnectToDatabase()
end

if ZDEV.MSQL.Enabled then
    ConnectToDatabase()
end

--[[━━━━━���━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━���━━━━━━━━━━━━
    PUBLIC API
    Signatures are identical to the old MySQLoo version.
    All consumers (net handlers, other addons) continue to work.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━]]

--[[���━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━��━━━━━━━━━━━━
    CONSOLE COMMANDS
━━━━━━━━━━━━━━━━━━���━━━━━━━��━━━━━━━━━━━━━━━���━━━━━━━━━━━━━]]

local function RegisterCommands()
    concommand.Add("zdev_db_status", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local status = ZDEV.MSQL.GetStatus()

        print("=== ZDEV Database Status (TMysql4) ===")
        print("Enabled:    " .. tostring(ZDEV.MSQL.Enabled))
        print("Connected:  " .. tostring(status.connected))
        print("Error:      " .. tostring(status.error or "None"))
        print("Connections:" .. ZDEV.MSQL.GetConnectionCount())
        print("Version:    " .. tostring(status.server_version or "unknown"))
        print("Config:     " .. (ZDEV.MSQL.Config.host or "?") .. ":" .. (ZDEV.MSQL.Config.port or "?") .. "/" .. (ZDEV.MSQL.Config.database or "?"))
    end)

    concommand.Add("zdev_db_test", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local startTime = SysTime()
        ZDEV.MSQL.Query("SELECT 1 as test", function(data)
            local elapsed = math.Round((SysTime() - startTime) * 1000, 2)
            print("Database Test Successful! (" .. elapsed .. "ms)")
            PrintTable(data)
        end, function(err, sql)
            print("Database Test Failed: " .. tostring(err))
        end)
    end)
end

timer.Simple(1, RegisterCommands)

-- Cleanup on shutdown
hook.Add("ShutDown", "ZDEV_MSQL_Cleanup", CleanupDatabase)

ZDEV.FILE.SetLoaded( _f )
