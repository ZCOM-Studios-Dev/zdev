local _f = 'zdev/server/meta/zd_sv_meta_ply.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
	zd_sv_meta_ply.lua
	Server player meta extensions for zdev addon.
	Author: zcomstudios
	Description: Extends player metatables with server-side logic for zdev.
]]
include("zdev/server/zd_sv_database.lua" )

local meta = FindMetaTable( "Player" )
if not meta then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:GenerateZID( )
	local rand, zid = 0, ""
	for i = 1, 9 do
		rand = math.random(0,9)
		zid = zid .. tostring(rand)
	end
	if ZDEV.PLYR._INDEX[ zid ] then
		self:GenerateZID( )
	else
		zdev.log( "S", "Generated player " .. tostring(self) .. " a new ZID: " .. tostring( zid ) )
		ZDEV.PLYR._INDEX[ zid ] = {}
		return zid
	end

end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:InitZData( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:InitZData( )

	zdev.log( "I", "Initializing data for " .. tostring( self ) )

	if not self.ZData then self.ZData = {}	end
	local zid = self:GenerateZID()

	self.ZData.file 		= tostring( "zdev/plyr/" .. self:UniqueID() .. ".txt" )

	self.ZData.zid 			= zid
	self.ZData.sid 			= self:SteamID()
	self.ZData.uid 			= self:UniqueID()
	self.ZData.ip 			= self:IPAddress()
	self.ZData.nick 		= self:Nick()
	self.ZData.playtime 	= 0
	self.ZData.rank			= RANK_PLAYER
	self.ZData.gold			= 0
	self.ZData.ugroup 		= self:GetUserGroup()

	self:SaveZData()
	self:SendAllZData()
	--self:InsertIntoPlayersTbl( )

	return self.ZData

end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZID( )
	return self:GetZData( "zid" )
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZRank()
	return self:GetZData( "rank" )
end

function meta:ZGold()
	return self:GetZData( "gold" )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZDataExists( )
	local uid = self:UniqueID()
	local s_file = "zdev/plyr/" .. tostring(uid) .. ".txt"
	if !self.ZData then self.ZData = {} end
	self.ZData.file = s_file
	return tobool( file.Exists( s_file, "DATA" ) )  
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:SaveZData( )
	local s_data = util.TableToJSON( self.ZData, true )
	file.Write( self.ZData.file, s_data )
	zdev.log( "I", "Saved player-data file for " .. tostring( self ) .. " - " .. tostring( s_file ) )
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:LoadZData( )
	local t_data = util.JSONToTable( file.Read( self.ZData.file, "DATA" ) )
	for k, v in pairs( t_data ) do
		self:SetZData( k, v )
	end
	zdev.log( "N", "Loaded player-data file for: " .. tostring( self ) )
	return t_data
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:SetZData( data, val )
	--self.CacheZData( data, val )
	self:SetPData( data, val )
	local nwtyp = ZDEV.PLYR.DataNWTranslate( data )
	if nwtyp == "Int" then
		self:SetNWInt( data, val )
	elseif nwtyp == "String" then
		self:SetNWString( data, val )
	end
	zdev.log( "S", "Set "..tostring(self).."'s ZData-Var: '"..tostring(data).."' to '"..tostring(val).."'")
end
function meta:SendAllZData( data )
	for k, v in pairs( self.ZData ) do
		self:SetZData( k, v )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:InsertIntoPlayersTbl( )
	local uid, sid, ip = self:UniqueID(), self:SteamID(), self:IPAddress()
	if ip == "loopback" then ip = "0.0.0.0" end
	print( uid, sid, ip )
	local s_q = string.format( "INSERT INTO players (uniqueid, steamid, ip) VALUES(%u, '%s', '%s, '%s', '%s', '%s')", uid, sid, ip, os.date(os.time()), os.date(os.time()), self:Nick() )
	local q = MYSQL_DB:query( s_q )
	q.onSuccess = function( data )
		zdev.log( "S", "Inserted Player " .. tostring(self) .. " ("..tostring(uid) .. ", " .. sid .. ", " .. ip .. " ) into `players` table." )
		DebugPrintTable( data )
	end
	q.onError = function( q, err )
		zdev.log( "E", "Error inserting Player into `players` table: " .. type(err) .. " " .. tostring(err) )
	end
	q:start()
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:RegisterToDatabase( )

end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:UploadData( )

end



--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local b_extraData, t_data = false, {}
function meta:SendHUDMessage( msgtype, txt, time, args )

	if args and type(args) == "table" and table.Count(args) > 0 then

		b_extraData = true

		if msgtype == HUDMSG_MARKER then

			if !args.ent or !IsValid(args.ent) then return end

			t_data.ent = ent
			t_data.entindex = ent:EntIndex()
			
		elseif msgtype == HUDMSG_WORLD then

			if !args.pos or !util.IsInWorld( args.pos ) then return end

			t_data.pos = Vector(pos.x, pos.y, pos.z)
			t_data.posstr = string.Implode(",", {x=pos.x,y=pos.y,z=pos.z})

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
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:AddEntMarker( id, ent, pos, material, clr, time )

	local puid = tostring(self:UniqueID())

	if !IsValid(ent) then zdev.log( "E", "Invalid entity passed to AddEntMarker" ) return end

	local t_marker = {id=id, mat=material, clr=clr, time=time}

	if !ent.zdev_marker then ent.zdev_marker = {} end
	if !ent.zdev_marker[ puid ] then ent.zdev_marker[ puid ] = {} end
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
			self:RemoveEntMarker( id, ent, false )
		end)
	end

end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SV Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:RemoveEntMarker( id, ent, send )

	local puid = tostring(self:UniqueID())

	if !IsValid(ent) then zdev.log( "E", "Invalid entity passed to RemoveEntMarker" ) return end
	if !ent.zdev_marker[ puid ] then zdev.log( "E", "Player " .. tostring(self).. " does not have any active hud-markers." ) return end
	local t_markers = ent.zdev_marker[ puid ]
	if t_markers and type( t_markers ) == "table" and table.Count( t_markers ) > 0 then
		local b_marker_removed
		for k, v in pairs( t_markers ) do
			if v.id == id then
				ent.zdev_marker[ puid ][ k ] = nil
				b_marker_removed = true
			end
		end
		if !b_marker_removed then
			zdev.log( "E", "Player " .. tostring(self) .. " does not have an active hud-marker for Entity " ..tostring(ent) .. " with id: " .. tostring( id ) )
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

ZDEV.FILE.SetLoaded( _f )
