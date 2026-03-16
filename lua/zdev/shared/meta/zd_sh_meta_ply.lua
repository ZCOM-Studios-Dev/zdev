local _f = 'zdev/shared/meta/zd_sh_meta_ply.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end
ZDEV.FILE.SetLoaded( _f )

local meta = FindMetaTable( "Player" )
if not meta then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:TraceHitPos( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:TraceHitPos( b_ScreenPos )
  local pos = util.TraceLine( util.GetPlayerTrace( self ) ).HitPos
  if (b_ScreenPos) then
    local x, y = pos:ToScreen().x, pos:ToScreen().y
    return x, y
  else
    return pos
  end
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GetTraceEnt( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local lifetime = 1
local pos1, pos2, pos3
local text, mins, maxs = "", Vector(-2,-2,-2), Vector(2,2,2)
function meta:GetTraceEnt( )
  local tr = util.TraceLine( util.GetPlayerTrace( self ) )

  pos1, pos2 = tr.StartPos, tr.HitPos
  --debugoverlay.Line( pos1, pos2, lifetime, Color( 255, 255, 255 ), true )

  if IsValid( tr.Entity ) then

    -- Debug Info
    text = tr.Entity:GetClass()
    pos3 = tr.Entity:WorldSpaceCenter()

    debugoverlay.Box( pos3, mins, maxs, lifetime, Color(255,0,255) )
    debugoverlay.EntityTextAtPosition( pos3, 1, text, lifetime, Color( 255, 255, 255 ) )

    return tr.Entity

  end

end



--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:InitZData( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:InitZData( )

	zdev.log( "I", "Initializing data for " .. tostring( self ) )

	if not self.ZData then self.ZData = {}	end

	self.ZData.zid 			= zid
	self.ZData.sid 			= self:SteamID()
	self.ZData.uid 			= self:UniqueID()
	self.ZData.ip 			= "0.0.0.0"
	self.ZData.nick 		= self:Nick()
	self.ZData.playtime 	= 0
	self.ZData.rank			= RANK_PLAYER
	self.ZData.gold			= 0
	self.ZData.ugroup 		= self:GetUserGroup()

	return self.ZData

end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:GetZData( data, cached )
  local val = nil

  local nwtyp = ZDEV.PLYR.DataNWTranslate( data )
	if nwtyp == "Int" then
		val = self:GetNWInt( data )
	elseif nwtyp == "String" then
		val = self:GetNWString( data )
	end

  if cached and cached == true then
    local val_cached = self:GetCachedZData( data )
    val = val_cached
  end

  return val
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:GetAllZData( cached )
  local t_zdata = {}
  for k, v in pairs( self.ZData ) do
    local val, val_cached = self:GetZData(k), self.GetCachedZData(k)
    if cached and val ~= val_cached then val = val_cached end
    t_zdata[ k ] = val
  end
  return t_zdata
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:GetCachedZData( data )
  if !self.ZData[ data ] then
    zdev.log( "E", "Argument 'data' in 'GetCachedZData()' is invalid. ")
    return
  end
  return self.ZData[ data ]
end 

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:CacheZData( data, val )
  if !self.ZData then self.ZData = {} end
  local val_cached = self:GetCachedZData( data )
  if val == val_cached then return end
  self.ZData[ data ] = val
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZRank()
  return self:GetZData( "ZRank" )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZID()
  return self:GetZData( "ZID" )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-SH Player:GenerateZID( )
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function meta:ZGold()
  return self:GetZData( "ZGold")
end

function meta:ValidateCachedZData( )

end