local _f = 'zdev/server/zd_sv_player.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Player Hooks
    Handles player lifecycle events (auth, spawn, death, disconnect).
    Uses ZDEV.PDATA for all SQL-backed data operations.
    Context: Server
]]

ZDEV.PLYR = ZDEV.PLYR or {}
ZDEV.PLYR._INDEX = ZDEV.PLYR._INDEX or {}
ZDEV.DATA = ZDEV.DATA or {}
ZDEV.DATA.Players = ZDEV.DATA.Players or {}

-- ZDEV_UID: ZDEV_FUNC_A4F336B0 | Path: ZDEV.PLYR.SearchByIP
function ZDEV.PLYR.SearchByIP( ip )
    for k, v in pairs( ZDEV.DATA.Players ) do
        if v.ip == ip then
            return k, v
        end
    end
    return false
end

-- ZDEV_UID: ZDEV_FUNC_836CE245 | Path: ZDEV.PLYR.QueryAllPlayers
function ZDEV.PLYR.QueryAllPlayers()
    zdev.log( "Q", "Querying All Players from Database" )
    ZDEV.MSQL.Query("SELECT steam_id64, steam_id, nick, rank, usergroup, playtime, last_join FROM zdev_players ORDER BY last_join DESC",
        function(data)
            if data then
                for _, row in ipairs(data) do
                    zdev.log("Q", row.nick .. " [" .. (row.steam_id or "?") .. "] Rank:" .. (row.rank or "?") .. " Playtime:" .. (row.playtime or "0") .. "s")
                end
                zdev.log("Q", "Total players: " .. #data)
            end
        end,
        function(err)
            zdev.log("E", "QueryAllPlayers failed: " .. tostring(err))
        end
    )
end

-- NW type mapping for ZData backward compat
function ZDEV.PLYR.DataNWTranslate( key )
    local map = {
        zid = "String", sid = "String", uid = "String",
        nick = "String", ip = "String", ugroup = "String",
        rank = "Int", playtime = "Int",
    }
    return map[key] or "String"
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PLAYER LIFECYCLE HOOKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- ZDEV_UID: ZDEV_FUNC_F7940C74 | Path: ZDEV.PLYR.Authed
function ZDEV.PLYR.Authed( ply, sid, uid )
    zdev.log("I", "PlayerAuthed: " .. tostring(ply) .. " SID=" .. tostring(sid))

    -- Load from database (auto-registers if first join)
    if ZDEV.MSQL.Enabled and ZDEV.MSQL.Status.connected then
        ZDEV.PDATA.Load(ply, function(success)
            if success then
                zdev.log("S", "Player data loaded from database for " .. ply:Nick())
            else
                zdev.log("W", "Database load failed for " .. ply:Nick() .. ", using defaults")
            end
        end)
    else
        zdev.log("W", "Database not connected, applying defaults for " .. ply:Nick())
        ZDEV.PDATA.ApplyDefaults(ply)
    end
end
hook.Add( "PlayerAuthed", "ZDEV.PLYR.Authed", ZDEV.PLYR.Authed )

-- ZDEV_UID: ZDEV_FUNC_B0A60EB2 | Path: ZDEV.PLYR.Connected
function ZDEV.PLYR.Connected( name, ip )
    MsgC( Color(255,150,0), "=========================================================================\n")
    zdev.log( "S", "Player connected to server: " .. tostring( name ) .. " (" .. tostring( ip ) .. ")" )
end
hook.Add( "PlayerConnected", "ZDEV.PLYR.Connected", ZDEV.PLYR.Connected )

local s_msg_greet = "Welcome to ZCOM's Development Server"

-- ZDEV_UID: ZDEV_FUNC_66AC69A0 | Path: ZDEV.PLYR.InitialSpawn
function ZDEV.PLYR.InitialSpawn( ply )
    ply:PrintMessage( HUD_PRINTCENTER, s_msg_greet )

    -- Start periodic save timer (every 120 seconds)
    local timerName = "ZDEV_SaveTimer_" .. tostring(ply:SteamID64()) .. "_SV"
    timer.Create(timerName, 120, 0, function()
        if not IsValid(ply) then
            timer.Remove(timerName)
            return
        end
        ZDEV.PDATA.SaveAll(ply)
    end)
end
hook.Add( "PlayerInitialSpawn", "ZDEV.PLYR.InitialSpawn", ZDEV.PLYR.InitialSpawn )

local s_msg_spawn = "You have respawned."

-- ZDEV_UID: ZDEV_FUNC_B6185974 | Path: ZDEV.PLYR.Spawn
function ZDEV.PLYR.Spawn( ply )
    ply:PrintMessage( HUD_PRINTCENTER, s_msg_spawn )
    zdev.log( "D" , "Player Spawned " .. tostring( ply ) )
end
hook.Add( "PlayerSpawn", "ZDEV.PLYR.Spawn", ZDEV.PLYR.Spawn )

-- ZDEV_UID: ZDEV_FUNC_3B1B0DA2 | Path: ZDEV.PLYR.Disconnected
function ZDEV.PLYR.Disconnected( ply )
    zdev.log( "W", "Player " .. tostring( ply ) .. " disconnected.")

    -- Final save to database
    if ZDEV.MSQL.Enabled and ZDEV.MSQL.Status.connected then
        ZDEV.PDATA.SaveAll(ply)
        ZDEV.SCHEMA.AuditLog(ply:SteamID64(), "logout", ply:Nick() .. " disconnected")
    end

    -- Clean up save timer
    timer.Remove("ZDEV_SaveTimer_" .. tostring(ply:SteamID64()) .. "_SV")
end
hook.Add( "PlayerDisconnected", "ZDEV.PLYR.Disconnected", ZDEV.PLYR.Disconnected )

-- ZDEV_UID: ZDEV_FUNC_BDED8D1F | Path: ZDEV.PLYR.DoDeath
function ZDEV.PLYR.DoDeath( ply, atk, dmg )
end
hook.Add( "DoPlayerDeath", "ZDEV.PLYR.DoDeath", ZDEV.PLYR.DoDeath )

-- ZDEV_UID: ZDEV_FUNC_2419EB5F | Path: ZDEV.PLYR.Death
-- Kills/deaths/score are game-system concerns; child addons hook PlayerDeath
-- themselves. Core no longer tracks combat stats.
function ZDEV.PLYR.Death( ply, atk, dmg )
end
hook.Add( "PlayerDeath", "ZDEV.PLYR.Death", ZDEV.PLYR.Death )

-- ZDEV_UID: ZDEV_FUNC_1F4C50DF | Path: ZDEV.PLYR.TakeDamage
function ZDEV.PLYR.TakeDamage( ply, dmg )
end
hook.Add( "EntityTakeDamage", "ZDEV.PLYR.TakeDamage", ZDEV.PLYR.TakeDamage )

-- ZDEV_UID: ZDEV_FUNC_7BCF1633 | Path: ZDEV.PLYR.PlayerShouldTakeDamage
function ZDEV.PLYR.PlayerShouldTakeDamage( pl, atk )
end

-- Console command to query all players
concommand.Add("zdev_db_players", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    ZDEV.PLYR.QueryAllPlayers()
end)

ZDEV.FILE.SetLoaded( _f )
