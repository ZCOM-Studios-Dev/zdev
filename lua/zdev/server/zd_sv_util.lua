local _f = 'zdev/server/zd_sv_util.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
	zd_sv_util.lua
	Server utility functions for zdev addon.
	Author: zcomstudios
	Description: Provides utility functions for server-side zdev logic.
]]

ZDEV.UTIL = ZDEV.UTIL or {}

local i_stack, prefix = 0, ""
local t_files, t_dirs = {}, {}
local t_realms = {
	[SERVER] = {tag="sv", color=Color(0,200,255), label="server"},
	[CLIENT] = {tag="cl", color=Color(255,200,50), label="client"}
}
-- ZDEV_UID: ZDEV_FUNC_6990D2BF | Path: ZDEV.UTIL.ScanDir
function ZDEV.UTIL.ScanDir( root, dir )

	--zdev.log( "W", "Scanning: " .. root .. " " .. dir .. " " .. tostring(last) .. "\n" )
	local files, folders = file.Find( dir .. "--[[", root )

	for k, d in pairs( folders ) do

		if d == "server" then
			MsgC( Color(0,150,200), prefix .. d .. "\n" )
		elseif d == "client" then
			MsgC( Color(200,150,0), prefix .. d .. "\n" )
		else
			MsgC( Color(200,150,200), prefix .. d .. "\n" )
		end

		ZDEV.UTIL.ScanDir( root, dir .. "/" .. d )

	end

	for k, f in pairs( files ) do

		MsgC( Color(255,255,255), prefix .. dir .. "/" )

		if string.find( f, "sv_", 1, false) or f == "init.lua" then

			MsgC( Color(100,200,255), prefix .. "◓ " .. f .. "\n" )

		elseif string.find( f, "sh_", 1, false) or f == "shared.lua" then

			MsgC( Color(100,200,100), prefix .. "◍ " .. f .. "\n")

		elseif string.find( f, "cl_", 1, false) then

			MsgC( Color(255,200,100), prefix .. "◒ " .. f .. "\n")

		else

			MsgC( Color(255,100,255), prefix .. "? " .. f .. "\n")

		end
	end

end

function ZDEV.CMDS.DEV.EntCreate( ply, cmd, arg, args )

	local class = arg[ 1 ]
	local name = arg[ 2 ]
	local tr = ply:GetEyeTrace()

	-- Create a simple physics prop to parent the real entity to and server as a 'handle' to move it
	local e_h = ents.Create( "prop_physics" )
	e_h:SetColor( Color(0,0,0,100) )
	e_h:SetModel( "models/editor/axis_helper.mdl" )
	e_h:SetPos( tr.HitPos )
	e_h:SetOwner( ply )
	e_h.ChildEnt = nil
	e_h:Spawn()

	--[[


	local e = ents.Create( class )
	e:SetPos( e_h:GetPos() )
	e:SetParent( e_h )
	e:SetName( name )
	e:Spawn()

	e_h.ChildEnt = e

	debugoverlay.EntityTextAtPosition( e:GetPos(), 1, tostring(e), 6, Color( 100, 200, 255 ) )

	ply:SetNWEntity( "LastDevSpawn",  e )
	ply:SetNWInt( "LastDevSpawn_Index", e:EntIndex() )
]]
	zdev.log( "W", tostring(ply) .. " spawned entity " ..tostring(e) .. " using the Z-Developer menu." )

end
concommand.Add( "zd_ent_create", ZDEV.CMDS.DEV.EntCreate, nil, "", {FCVAR_CHEAT,FCVAR_CLIENTCMD_CAN_EXECUTE} )


function ZDEV.CMDS.DEV.RunLua( ply, cmd )
	zdev.log( "W", "Running Lua Code " .. tostring(cmd) )
	--RunConsoleCommand( "lua_run_sv", cmd )
	ply:ConCommand( "lua_run_sv " .. cmd)
	--game.ConsoleCommand("lua_run_sv "..cmd.."\n")
end

net.Receive( "zdev_con_lua_tosv", function( )
	local ply = net.ReadEntity()
	if ply:GetUserGroup() ~= "superadmin" then return end
	local cmd = net.ReadString()
	print( tostring(ply), tostring(cmd) )
	ZDEV.CMDS.DEV.RunLua( ply, cmd )
end )

net.Receive( "zdev_dev_selclass_tosv", function()
	local class = net.ReadString()
	
end)

-- ZDEV_UID: ZDEV_FUNC_7F66A25A | Path: ZDEV.UTIL.EntityKeyValue
function ZDEV.UTIL.EntityKeyValue( ent, key, value )

	if key == "texture" and IsValid( decal ) and decal:GetClass() == "infodecal" then
		if unwantedDecals[value] then
			-- set a targetname to make the decal remain and not appear automatically:
			decal:SetName( "remove_unwanted_decals" )
		end
	end

end
hook.Add( "EntityKeyValue", "ZDEV.UTIL.EntityKeyValue", ZDEV.UTIL.EntityKeyValue)

ZDEV.FILE.SetLoaded( _f )
