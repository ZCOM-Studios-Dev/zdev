local _f = 'zdev/shared/meta/zd_sh_meta_ent.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )

local meta = FindMetaTable( "Entity" )
if not meta then return end

local function Name()
	local effectdata = EffectData()
	effectdata:SetStart( ent:GetPos())
	effectdata:SetOrigin( ent:GetPos() )
	effectdata:SetMagnitude( 20 )
	effectdata:SetScale( 12 )
	effectdata:SetRadius( 128 )
	effectdata:SetEntity( ent )
  util.Effect("TeslaHitBoxes", effectdata, true, true)
end

local function TeslaZap( ent )
	local vMin, vMax = ent:GetHitBoxBounds( 0, 0 )
	local vOffset = ent:LocalToWorld( vMax )
	local vNormal = (vOffset - ent:GetPos()):GetNormalized()
	local effectdata = EffectData()
		effectdata:SetOrigin( vOffset )
		effectdata:SetNormal( vNormal )
		effectdata:SetRadius( 128 )
		effectdata:SetScale( 15 )
	util.Effect( "TeslaZap ", effectdata )
end

function meta:CreateEffect( s_EffectName )
	if s_EffectName == "TeslaZap" then
		TeslaZap( self )
	elseif s_EffectName == "TeslaHitBoxes" then
		TeslaHitBox( self )
	end
end

function meta:IsDoor()
	local class = self:GetClass()
	if string.find( class, "door", 1, false ) then
		return true
	else
		return false
	end
end

function meta:IsBreakable()
	local class = self:GetClass()
	if string.find( class, "breakable", 1, false ) then
		return true
	else
		return false
	end
end

function meta:IsProp()
	local class = self:GetClass()
	if string.find( class, "prop", 1, false ) then
		return true
	else
		return false
	end
end

function meta:GetDownload( )
  return tonumber( self:GetNWInt( "Download" ) )
end

function meta:GetStatus( )
  return tostring( self:GetNWString( "Status" ) )

end

function meta:IsBeingHacked( )
  return tobool( self:GetNWBool( "Hacked" ) )
end

--[[ ========================================================
  FUNCTION: DoHack
  DESC: Dependingh on what type of entity SELF is, either
  deactivate, kill, unlock, break, or comandeer,
========================================================== ]]
function meta:DoHack( activator )

  if !IsValid( activator ) then return end
  --if !IsValid( self.Entity ) then return end
  if !activator:IsPlayer() then return end

  local nickname = activator:Nick()
  local classname = self:GetClass()
  local entType

  if self:IsNPC() then
    entType = "NPC"
    -- Depending on NPC,make friendly or disable
    if SERVER then
			self:AddEntityRelationship( activator, D_FR, 99 )
      print('')

		end
    --ST.Log( "!p! Hacked NPC " .. self.Entity:EntIndex() .. " Disposition towards " .. nickname )

  elseif self:IsPlayer() then
    entType = "Player"
    -- If enemy player then disable HUD and other functions
    --ST.Log( "!p! Hacked Player " .. self.Entity:Nick() .. " by " .. nickname )
    if self:Team() == TEAM_MERC then
      self:SetStatus( STATUS_HACKED )
    end
  elseif self:IsDoor() then
    entType = "Door"
    -- Unlock and open from adistance
    --ST.Log( "!p! Hacked Door " .. self.Entity:EntIndex() .. " Disposition: " .. nickname )
    if SERVER then
			self:Fire( "Unlock", "", 0.1 )
    	self:Fire( "Open", "", 0.8 )
		end

  elseif self:IsBreakable() then
    entType = "Breakable"
    -- Break completely.
    if SERVER then self:Fire( "Break", "", 0.2 ) end

  elseif self:IsVehicle() then
    entType = "Vehicle"
  end

 -- ST.Log( "!p! " .. self.Entity:EntIndex() .. " (" ..entType.. ") was hacked by " .. nickname )
  print('')

end

function meta:IsTerminal()
  return tobool( string.find( self:GetClass(), "obj_terminal", 1, false) )
end

function meta:IsDoor()
  local cls = self:GetClass()
  local bool = false
  if string.find( cls, "door", 1, false ) or string.find( cls, "movelinear", 1, false ) or string.find( cls, "rotating", 1, false ) then
    bool = true
  end
  return bool
end

function meta:CanHack()

end

local t_ClassTranslate = {}

function meta:NameFromClass()
  local class, name
  class = tostring( self:GetClass() )

  if not (string.find( class, "zcom", 1, false) or string.find( class, "zdev", 1, false ) ) then return end

  name = string.Replace( class, "zdev_", "" )
  name = string.Replace( name, "_", " " )

  print(name)
  return name
end


--[[ ========================================================
  FUNCTION: DoHack
  DESC: Dependingh on what type of entity SELF is, either
  deactivate, kill, unlock, break, or comandeer,
========================================================== ]]
function meta:DoHack( activator )

end

