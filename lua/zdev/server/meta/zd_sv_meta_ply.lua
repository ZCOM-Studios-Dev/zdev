local _f = 'zdev/server/meta/zd_sv_meta_ply.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    Server Player Meta Extensions
    Extends the Player metatable with ZDEV data methods.
    Now backed by SQL via ZDEV.PDATA instead of JSON files.
    Context: Server
]]

local meta = FindMetaTable( "Player" )
if not meta then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ZID — ZDEV Unique ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function meta:ZID()
    return self.ZID or "000000000"
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ZData — Backward-compatible accessors
    These now read/write NW vars (which are synced to SQL on save).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Map ZData keys to NW var names (Core essentials only)
local ZDATA_NW_MAP = {
    rank     = { nw = "ZDEV_Rank",     type = "Int" },
    playtime = { nw = "ZDEV_Playtime", type = "Int" },
}

function meta:GetZData( key )
    -- Check NW map first
    local mapping = ZDATA_NW_MAP[key]
    if mapping then
        if mapping.type == "Int" then
            return self:GetNWInt(mapping.nw, 0)
        elseif mapping.type == "String" then
            return self:GetNWString(mapping.nw, "")
        end
    end

    -- Simple property lookups
    if key == "zid" then return self.ZID or "" end
    if key == "sid" then return self:SteamID() end
    if key == "uid" then return self:UniqueID() end
    if key == "nick" then return self:Nick() end
    if key == "ip" then return self:IPAddress() end
    if key == "ugroup" then return self:GetUserGroup() end

    -- Fallback to PData for anything else
    return self:GetPData(key)
end

function meta:SetZData( key, val )
    -- Check NW map
    local mapping = ZDATA_NW_MAP[key]
    if mapping then
        if mapping.type == "Int" then
            self:SetNWInt(mapping.nw, tonumber(val) or 0)
        elseif mapping.type == "String" then
            self:SetNWString(mapping.nw, tostring(val))
        end
        return
    end

    -- Fallback to PData
    self:SetPData(key, val)
end

function meta:ZRank()
    return self:GetNWInt("ZDEV_Rank", 0)
end

--- Total accumulated playtime in seconds (live for the current session).
function meta:GetPlaytime()
    if ZDEV.PDATA and ZDEV.PDATA.GetPlaytime then
        return ZDEV.PDATA.GetPlaytime(self)
    end
    return self:GetNWInt("ZDEV_Playtime", 0)
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    InitZData — Now delegates to PDATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function meta:InitZData()
    zdev.log("I", "InitZData called for " .. tostring(self) .. " — delegating to PDATA.Load")
    if ZDEV.PDATA then
        ZDEV.PDATA.Load(self)
    else
        zdev.log("W", "ZDEV.PDATA not available, applying defaults")
        ZDEV.PDATA.ApplyDefaults(self)
    end
end

function meta:SaveZData()
    if ZDEV.PDATA then
        ZDEV.PDATA.SaveAll(self)
    end
end

function meta:LoadZData()
    if ZDEV.PDATA then
        ZDEV.PDATA.Load(self)
    end
end

function meta:ZDataExists()
    -- Always true when using SQL — the Load function handles registration
    return true
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Database Registration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function meta:InsertIntoPlayersTbl()
    -- Now handled automatically by PDATA.Register on first join
    zdev.log("D", "InsertIntoPlayersTbl called — handled by PDATA.Register")
end

function meta:RegisterToDatabase()
    if ZDEV.PDATA then
        ZDEV.PDATA.Register(self)
    end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    HUD Messages (unchanged)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local b_extraData, t_data = false, {}
function meta:SendHUDMessage( msgtype, txt, time, args )
    if args and type(args) == "table" and table.Count(args) > 0 then
        b_extraData = true

        if msgtype == HUDMSG_MARKER then
            if not args.ent or not IsValid(args.ent) then return end
            t_data.ent = args.ent
            t_data.entindex = args.ent:EntIndex()
        elseif msgtype == HUDMSG_WORLD then
            if not args.pos or not util.IsInWorld( args.pos ) then return end
            t_data.pos = Vector(args.pos.x, args.pos.y, args.pos.z)
        end
    end

    net.Start( "zdev_hud_msg_send", false )
        net.WriteString( txt )
        net.WriteUInt( msgtype, 3 )
        net.WriteFloat( time )
        if b_extraData then
            net.WriteTable( t_data )
        end
    net.Send(self)
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    HUD Markers (unchanged)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function meta:AddEntMarker( id, ent, pos, material, clr, time )
    local puid = tostring(self:UniqueID())

    if not IsValid(ent) then zdev.log( "E", "Invalid entity passed to AddEntMarker" ) return end

    local t_marker = {id=id, mat=material, clr=clr, time=time}

    if not ent.zdev_marker then ent.zdev_marker = {} end
    if not ent.zdev_marker[ puid ] then ent.zdev_marker[ puid ] = {} end
    table.insert( ent.zdev_marker[ puid ], t_marker )

    net.Start( "zdev_hud_marker_ent",false )
        net.WriteString( id )
        net.WriteEntity( ent )
        net.WriteVector( pos )
        net.WriteString( material )
        net.WriteColor( clr )
        net.WriteFloat( time )
    net.Send( self )

    if time > 0 then
        timer.Simple( time, function()
            if IsValid(self) then
                self:RemoveEntMarker( id, ent, false )
            end
        end)
    end
end

function meta:RemoveEntMarker( id, ent, send )
    local puid = tostring(self:UniqueID())

    if not IsValid(ent) then zdev.log( "E", "Invalid entity passed to RemoveEntMarker" ) return end
    if not ent.zdev_marker or not ent.zdev_marker[ puid ] then return end

    local t_markers = ent.zdev_marker[ puid ]
    local b_marker_removed = false
    for k, v in pairs( t_markers ) do
        if v.id == id then
            ent.zdev_marker[ puid ][ k ] = nil
            b_marker_removed = true
        end
    end

    if b_marker_removed then
        zdev.log( "S", "Removed entity HUD marker from " .. tostring( ent ) )
        if send then
            net.Start( "zdev_hud_marker_ent_remove", false )
                net.WriteString( id )
                net.WriteEntity( ent )
            net.Send( self )
        end
    end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    World Marker (position-based, no entity required)
    Sends a marker at a world position to the client's
    marker system with full customization parameters.

    @param text      string   Text label for the marker
    @param pos       Vector   World position
    @param opts      table    (optional) Override defaults:
        .icon        string   Material path for the icon
        .iconClr     Color    Icon tint color
        .iconW       number   Icon width
        .iconH       number   Icon height
        .textClr     Color    Text color
        .bgClr       Color    Background color
        .font        string   Font name
        .duration    number   Total lifetime in seconds
        .calloutDur  number   Initial text-visible duration
        .lookAngle   number   Degrees tolerance for look-at
        .lookDist    number   Max distance for look-at reveal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function meta:AddWorldMarker( text, pos, opts )
    if not pos then zdev.log("E", "AddWorldMarker: no position") return end
    opts = opts or {}

    net.Start("zdev_hud_marker_world", false)
        net.WriteString( text )
        net.WriteVector( pos )
        net.WriteTable( opts )
    net.Send( self )
end

ZDEV.FILE.SetLoaded( _f )
