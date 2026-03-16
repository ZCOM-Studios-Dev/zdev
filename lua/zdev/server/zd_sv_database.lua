# lua/zdev/server/zd_sv_database.lua
local _f = 'zdev/server/zd_sv_database.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ZDEV MODULAR ADAPTIVE MYSQL DATABASE SYSTEM
-- A robust, scalable database solution for ZDEV addon
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
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
    port = "3306",
    pool_size = 5,
    timeout = 30,
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
end

-- Initialize the database system
local function InitDatabaseSystem()
    LoadDatabaseConfig()
    
    -- Check if mysqloo is available
    local has_mysqloo, mysqloo = pcall(require, "mysqloo")
    if not has_mysqloo or not mysqloo then
        zdev.log("E", "MySQLoo module not found! Database functionality disabled.")
        ZDEV.MSQL.Enabled = false
        return
    end
    
    ZDEV.MSQL.Enabled = true
    ZDEV.MSQL.Mysqloo = mysqloo
    
    -- Create connection pool
    ZDEV.MSQL.Pool = {}
    ZDEV.MSQL.Connections = {}
    ZDEV.MSQL.Status = {
        connected = false,
        error = nil,
        last_error_time = 0,
        connection_count = 0
    }
    
    zdev.log("I", "ZDEV MySQL Database System initialized successfully")
end

-- Connect to database with retry mechanism
local function ConnectToDatabase()
    if not ZDEV.MSQL.Enabled then return end
    
    local config = ZDEV.MSQL.Config
    local attempts = 0
    local max_attempts = config.reconnect_attempts or 3
    
    local function attemptConnect()
        attempts = attempts + 1
        
        local db = ZDEV.MSQL.Mysqloo.connect(
            config.host,
            config.database,
            config.password,
            config.username,
            config.port
        )
        
        if not db then
            zdev.log("E", "Failed to create database connection (attempt " .. attempts .. ")")
            if attempts < max_attempts then
                local delay = math.min(2^attempts, config.max_reconnect_delay or 30)
                timer.Simple(delay, attemptConnect)
            else
                zdev.log("E", "Maximum connection attempts reached. Database disabled.")
                ZDEV.MSQL.Status.connected = false
                ZDEV.MSQL.Status.error = "Failed to connect after " .. max_attempts .. " attempts"
            end
            return
        end
        
        -- Set up connection callbacks
        db:onConnected(function()
            zdev.log("S", "MySQL Database Connected Successfully")
            ZDEV.MSQL.Status.connected = true
            ZDEV.MSQL.Status.error = nil
            
            -- Log connection info
            local info = {
                host = config.host,
                database = config.database,
                version = db:serverInfo(),
                ping = db:ping(),
                queue_size = db:queueSize()
            }
            
            zdev.log("I", "Database Info - Host: " .. info.host .. ", DB: " .. info.database)
            zdev.log("I", "Version: " .. info.version .. ", Ping: " .. info.ping .. "ms")
            
            -- Notify all modules that database is ready
            hook.Run("ZDEV.Database.Connected")
        end)
        
        db:onConnectionFailed(function(err)
            zdev.log("E", "Database connection failed: " .. tostring(err))
            ZDEV.MSQL.Status.connected = false
            ZDEV.MSQL.Status.error = err
            ZDEV.MSQL.Status.last_error_time = CurTime()
            
            if attempts < max_attempts then
                local delay = math.min(2^attempts, config.max_reconnect_delay or 30)
                timer.Simple(delay, attemptConnect)
            else
                zdev.log("E", "Maximum connection attempts reached. Database disabled.")
                hook.Run("ZDEV.Database.Error", err)
            end
        end)
        
        -- Store connection reference
        table.insert(ZDEV.MSQL.Connections, db)
        ZDEV.MSQL.Status.connection_count = #ZDEV.MSQL.Connections
        
        -- Start connection
        db:connect()
    end
    
    attemptConnect()
end

-- Get a connection from the pool (round-robin or least busy)
local function GetConnection()
    if not ZDEV.MSQL.Enabled or #ZDEV.MSQL.Connections == 0 then
        return nil
    end
    
    -- Simple round-robin approach for now
    local index = (#ZDEV.MSQL.Connections % #ZDEV.MSQL.Connections) + 1
    return ZDEV.MSQL.Connections[index]
end

-- Execute a query with automatic connection handling
local function ExecuteQuery(query_string, callback_success, callback_error, params)
    if not ZDEV.MSQL.Enabled then
        if callback_error then
            callback_error("Database not enabled")
        end
        return nil
    end
    
    local db = GetConnection()
    if not db or not db:status() == ZDEV.MSQL.Mysqloo.STATUS_CONNECTED then
        -- Try to reconnect if needed
        if not ZDEV.MSQL.Status.connected then
            zdev.log("W", "Database disconnected, attempting to reconnect...")
            ConnectToDatabase()
        end
        
        if callback_error then
            callback_error("Database not connected")
        end
        return nil
    end
    
    local query = db:query(query_string)
    
    if params then
        for i, param in ipairs(params) do
            query:setParameter(i, param)
        end
    end
    
    if callback_success then
        query:onSuccess(callback_success)
    end
    
    if callback_error then
        query:onError(callback_error)
    end
    
    return query:start()
end

-- Safe query execution with error handling
local function SafeQuery(query_string, callback_success, callback_error, params)
    local function safe_success(data)
        if callback_success then
            callback_success(data)
        end
    end
    
    local function safe_error(err, sql)
        zdev.log("E", "Database Query Error - SQL: " .. tostring(sql) .. " Error: " .. tostring(err))
        if callback_error then
            callback_error(err, sql)
        end
    end
    
    return ExecuteQuery(query_string, safe_success, safe_error, params)
end

-- Transaction support
local function BeginTransaction(callback_success, callback_error)
    if not ZDEV.MSQL.Enabled then
        if callback_error then
            callback_error("Database not enabled")
        end
        return nil
    end
    
    local db = GetConnection()
    if not db then
        if callback_error then
            callback_error("No database connection available")
        end
        return nil
    end
    
    local transaction = db:createTransaction()
    
    if callback_success then
        transaction:onSuccess(callback_success)
    end
    
    if callback_error then
        transaction:onError(callback_error)
    end
    
    return transaction
end

-- Helper function to escape strings for safety
local function EscapeString(str)
    if not ZDEV.MSQL.Enabled or not str then return "" end
    
    local db = GetConnection()
    if not db then return tostring(str) end
    
    return db:escape(tostring(str))
end

-- Helper function to check database status
local function GetStatus()
    return ZDEV.MSQL.Status
end

-- Helper function to get connection count
local function GetConnectionCount()
    return #ZDEV.MSQL.Connections
end

-- Helper function to get connection info
local function GetConnectionInfo()
    local info = {}
    for i, conn in ipairs(ZDEV.MSQL.Connections) do
        info[i] = {
            status = conn:status(),
            queue_size = conn:queueSize(),
            ping = conn:ping()
        }
    end
    return info
end

-- Initialize the database system
InitDatabaseSystem()

-- Connect to database
if ZDEV.MSQL.Enabled then
    ConnectToDatabase()
end

-- Public API for database operations
ZDEV.MSQL.Query = SafeQuery
ZDEV.MSQL.Execute = ExecuteQuery
ZDEV.MSQL.Transaction = BeginTransaction
ZDEV.MSQL.Escape = EscapeString
ZDEV.MSQL.GetStatus = GetStatus
ZDEV.MSQL.GetConnectionCount = GetConnectionCount
ZDEV.MSQL.GetConnectionInfo = GetConnectionInfo

-- Register database commands
local function RegisterCommands()
    if not ZDEV.MSQL.Enabled then return end
    
    concommand.Add("zdev_db_status", function(ply, cmd, args)
        if not IsValid(ply) or ply:IsAdmin() then
            local status = ZDEV.MSQL.GetStatus()
            local conn_info = ZDEV.MSQL.GetConnectionInfo()
            
            print("=== ZDEV Database Status ===")
            print("Enabled: " .. tostring(status.connected))
            print("Error: " .. tostring(status.error or "None"))
            print("Connections: " .. ZDEV.MSQL.GetConnectionCount())
            
            for i, info in ipairs(conn_info) do
                print("Connection " .. i .. ": Status=" .. info.status .. ", Queue=" .. info.queue_size .. ", Ping=" .. info.ping .. "ms")
            end
        end
    end)
    
    concommand.Add("zdev_db_test", function(ply, cmd, args)
        if not IsValid(ply) or ply:IsAdmin() then
            ZDEV.MSQL.Query("SELECT 1 as test", function(data)
                print("Database Test Successful!")
                PrintTable(data)
            end, function(err, sql)
                print("Database Test Failed: " .. err)
            end)
        end
    end)
end

-- Register commands when system is ready
timer.Simple(1, RegisterCommands)

-- Cleanup function
local function CleanupDatabase()
    for i, conn in ipairs(ZDEV.MSQL.Connections) do
        if conn and conn:status() == ZDEV.MSQL.Mysqloo.STATUS_CONNECTED then
            conn:abortAllQueries()
        end
    end
end

-- Register cleanup hook
hook.Add("ShutDown", "ZDEV_MSQL_Cleanup", CleanupDatabase)

-- Export public functions
ZDEV.MSQL.Initialize = InitDatabaseSystem
ZDEV.MSQL.Connect = ConnectToDatabase
ZDEV.MSQL.Reconnect = function()
    CleanupDatabase()
    ConnectToDatabase()
end

ZDEV.FILE.SetLoaded( _f )