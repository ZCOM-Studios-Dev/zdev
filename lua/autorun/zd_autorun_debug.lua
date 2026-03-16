local _f = 'autorun/zd_autorun_debug.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

if SERVER then
	AddCSLuaFile()
end

Msg('■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n')
MsgC(Color(50,255,200),'\tZDEV Debug Loaded.\n',color_white)
Msg('■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n')
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	UTILITY FUNCTIONS
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
--[[
	zd_autorun_debug.lua
	Debug autorun script for Garry's Mod.
	Author: zcomstudios
	Description: Provides debugging hooks and utilities for the addon.
]]
local function RandomNumericString( num )
	local str = ""
	for i = 0, num do
		str = str .. tostring( math.random( 0, 9 ) )
	end
	return str
end

-- ZDEV_UID: ZDEV_FUNC_A3D44342 | Path: ZDEV.FILE.NewLog
function ZDEV.FILE.NewLog( dir )
	local logid, path, filename, contents, header
	logid = RandomNumericString( 6 )
	path = ZDEV.DATA.RootDir .. "/" .. ZDEV.FILE.DIR.Logs .. "/" .. dir
	filename = "zdev_log_".. tostring( os.date("%S_%M_%H__%d_%m_%Y", os.time() ) ) ..".txt"
	header = "■ ZDEV LogFile: #" .. tostring(logid) .. " - " .. os.date( "%Y %B %d %a %H:%M %p", os.time() ) .. "\n"
	contents = header .. "■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n"
	if !file.IsDir( path, "DATA" ) then 
		zdev.log( "N", "Creating directory: " .. path )
		file.CreateDir( path )
	end
	local filepath = path .. "/" .. filename
	if !file.Exists(  filepath , "DATA" ) then
		file.Write( filepath, contents )
	end
	ZDEV.DATA.ActiveLog = {}
	ZDEV.DATA.ActiveLog.__index = ZDEV.DATA.ActiveLog
	ZDEV.DATA.ActiveLog.file = filepath
	ZDEV.DATA.ActiveLog.datetime = os.time()
	zdev.log( "N", "Initiated a new Log-File "..filepath, true )
end

--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
if CLIENT then
	ZDEV.MDLS = ZDEV.MDLS or {}
	ZDEV.ENTS = ZDEV.ENTS or {}
-- ZDEV_UID: ZDEV_FUNC_432AB938 | Path: ZDEV.DBUG.RegisterClientEntity
	function ZDEV.DBUG.RegisterClientEntity( ent, time )
		local i_timestamp = CurTime()
		local id = #ZDEV.ENTS + 1
		if !ZDEV.ENTS[ id ] then
			ZDEV.ENTS[ id ] = { ent = ent, created = i_timestamp, lifetime = time }
			timer.Simple( i_timestamp + time, function()
				print( "\t Removing ClientSide Entity: " .. tostring( ent ) .. " [" .. tostring( ent:GetModel() ) .. "]" )
				SafeRemoveEntity( ent )
			end )
		end
	end
-- ZDEV_UID: ZDEV_FUNC_95AA6D4D | Path: ZDEV.DBUG.RegisterClientModel
	function ZDEV.DBUG.RegisterClientModel( mdl, time )
		local i_timestamp = CurTime()
		local id = #ZDEV.MDLS + 1
		if !ZDEV.MDLS[ id ] then
			ZDEV.MDLS[ id ] = { mdl = mdl, created = i_timestamp, lifetime = time }
		end
		timer.Simple( i_timestamp + time, function()
			print( "\t Removing ClientSide Model: " .. tostring( mdl ) .. " [" .. tostring( mdl:GetModel() ) .. "]" )
			SafeRemoveEntity( mdl )
		end )
	end
-- ZDEV_UID: ZDEV_FUNC_41230FBD | Path: ZDEV.MDLS.Get
	function ZDEV.MDLS.Get( id )
	end
end
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

-- ZDEV_UID: ZDEV_FUNC_2E64B823 | Path: ZDEV.DBUG.PrecacheModel
function ZDEV.DBUG.PrecacheModel( mdl )
	if SERVER then
		util.PrecacheModel( mdl )
	end
end
ZD.preMdl = ZDEV.DBUG.PrecacheModel
-- ZDEV_UID: ZDEV_FUNC_D166EBEB | Path: ZDEV.DBUG.CSModel
function ZDEV.DBUG.CSModel( mdl )
	ZD.preMdl( mdl )
	if SERVER then return end
	local cmdl = ClientsideModel( mdl, RENDERGROUP_BOTH )
	DebugPrintTable( cmdl:GetTable() )
	return cmdl
end
ZD.cmdl = ZDEV.DBUG.CSModel
-- ZDEV_UID: ZDEV_FUNC_CB67566F | Path: ZDEV.DBUG.CSEntity
function ZDEV.DBUG.CSEntity( mdl )
	ZD.preMdl( mdl )
	if SERVER then return end
	local ent = ents.CreateClientProp( mdl )
	--DebugPrintTable( ent:GetTable() )
	ZDEV.ENTS._CSINDEX[ #ZDEV.ENTS._CSINDEX ] = ent
	return ent
end
ZD.cent = ZDEV.DBUG.CSEntity
-- ZDEV_UID: ZDEV_FUNC_AFD1B86B | Path: ZDEV.DBUG.PrintAllEnts
function ZDEV.DBUG.PrintAllEnts( )
	DebugPrintTable( ents.GetAll() )
end
ZD.prents = ZDEV.DBUG.PrintAllEnts
 
--[[
local t_valid_bones = {}
do
	for i = 1, 25 do
		if i==7 or i==12 or i==17 then
			t_valid_bones[ i ] = nil
		else
			t_valid_bones[ i ] = true
		end
	end
end



local t_filter_bone = {
	["npc_citizen"]={[7]=true,[12]=true,[17]=true},
	["npc_manhack"]={[3]=true}
}
-- ZDEV_UID: ZDEV_FUNC_51C6E54A | Path: ZDEV.DBUG.GetRandomBone
function ZDEV.DBUG.GetRandomBone(ent)
	local e,p,a,t,c = ent,Vector(0,0,0),Angle(0,0,0),{}, ent:GetClass()
	for i=1,25 do
		local b=t_filter_bones[c]
		if !b or type(b)~="table" then return end
		if b[i] then return end
			t[i]=true
		end
		--p,a=ent:GetBonePosition(i)
		--t.name=ent:GetBoneName(i)
		--t[i].pos = p
		--t[i].ang = a
	end
		--local b={id=i,name=ent:GetBoneName(i),pos=p,ang=a}
		--PrintTable(b)
	return t
end
end
end
]]

-- ZDEV_UID: ZDEV_FUNC_BBE4C00F | Path: ZDEV.DBUG.GetBoneInfo
function ZDEV.DBUG.GetBoneInfo( ent, id )
	if id then
		local name = ent:GetBoneName( id ) or "UNKNOWN"
		local pos, ang = ent:GetBonePosition( id )
		if (  ent:GetBoneMatrix( id ) ) then
			local matrix = ent:GetBoneMatrix( id ) or Matrix( {{1, 0, 0, 0, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}}})
		end
		if matrix then
			local trans = matrix:GetTranslation()
		end
		if pos == ent:GetPos() and trans then
			pos = trans or ent:GetBonePosition(1)
		end
		--MsgC( Color(200,100,255), string.Implode(", ", {id, name, tostring(pos), tostring(ang)} ) .. "\n" )
		return name, pos, ang
	end
end

-- ZDEV_UID: ZDEV_FUNC_7B78150D | Path: ZDEV.DBUG.GetHitBoxes
function ZDEV.DBUG.GetHitBoxes( ent )
	local t_hitboxes = {}
	local hb_set_num = ent:GetHitboxSetCount()
	for i = 0, hb_set_num do
		local hb_set_id, hb_set_name = ent:GetHitboxSet()
		local hb_num = ent:GetHitBoxCount( i )
		t_hitboxes[ i ] = {}
		for o = 0, hb_num do
			local hb_bone = ent:GetHitBoxBone( o, i )
			local hb_bmin, hb_bmax = ent:GetHitBoxBounds( o, i )
			local bone_name, bone_pos, bone_ang = ZDEV.DBUG.GetBoneInfo( ent, hb_bone )
			
			--local dbug_clr = Color(100,255,100)
			local t_bone =  {hb_bone, bone_name, bone_pos, bone_ang }
			--MsgC( dbug_clr, i .. " - " .. "["..o.."] " .. table.ToString( t_bone, "bone", true ) .. "\n" )
			t_hitboxes[ o ] = {
				id = hb_set_id, 
				name = hb_set_name,
				pos = bone_pos,
				ang = bone_ang,
				min = hb_bmin,
				max = hb_bmax,
				bone = t_bone
			}
			
		--	debugoverlay.Cross( v_pos, 2, 15, Color( 255, 255, 255 ), true)
		--	debugoverlay.Box( bone_pos, hb_bmin, hb_bmax, 10, Color( 100, 255, 100 ))
		--	debugoverlay.BoxAngles( bone_pos, hb_bmin, hb_bmax, bone_ang,  10, Color( 100, 255, 100 ))
		end
	end
	PrintTable( t_hitboxes )
	return t_hitboxes
end
ZD.gethitbxs = ZDEV.DBUG.GetHitBoxes

-- ZDEV_UID: ZDEV_FUNC_904E324B | Path: ZDEV.DBUG.RandomHitBoxPos
function ZDEV.DBUG.RandomHitBoxPos( ent )

	local pos = ent:WorldSpaceCenter()

	local t_hitboxes = ZDEV.DBUG.GetHitBoxes( ent )
	local key_rand = math.random( 1, #t_hitboxes )
	local hitbox_rand = t_hitboxes[ key_rand ]

	pos = hitbox_rand.pos
	
	zdev.log( "D", tostring(pos) )

	debugoverlay.Cross( pos, 2, 6, Color(255,150,0,255), true )

	return pos

end

-- ZDEV_UID: ZDEV_FUNC_2B7AD064 | Path: ZDEV.DBUG.GetBones
function ZDEV.DBUG.GetBones( ent, index )
	if !ent or ent == nil then	ent = Entity(index)	end
	local t_bones = {}
	local i_bones = ent:GetBoneCount()
	for i = 0, i_bones do
		local b_name, b_pos, b_ang =ZDEV.DBUG.GetBoneInfo( ent, i )
		local v_pos, a_ang = ent:GetBonePosition( i )
		local s_name = ent:GetBoneName( i )
		if string.find(s_name,"INVALID",1,false) or v_pos == ent:GetPos() then

			--zdev.log("E","Bone ID: ".. i .. " " .. ent:GetBoneName(i) .. "(".. tostring(v_pos) .. " | " .. tostring(v_ang) .. ")" )
		else
			--debugoverlay.Cross( v_pos, 2, 15, Color( 255, 255, 255 ), true)

			--zdev.log("S","Bone ID: ".. i .. " " .. ent:GetBoneName(i) .. "(".. tostring(v_pos) .. " | " .. tostring(v_ang) .. ")"  )
			t_bones[ i ] = {
				id = i,
				name = s_name,
				pos = v_pos,
				ang = a_ang
			}
		end
	end
	return t_bones
end
ZD.getbones = ZDEV.DBUG.GetBones

-- ZDEV_UID: ZDEV_FUNC_86F3D99C | Path: ZDEV.DBUG.FreezeBones
function ZDEV.DBUG.FreezeBones( ent, type, amount, scale, time )
	local model_ice = "models/props_borealis/iceberg01f.mdl"
	local tr, tr_ent, t_bones, csmdl
	local t_bones = ZD.getbones( ent )
	local t_hitboxes = ZDEV.DBUG.GetHitBoxes( ent )
	for i=1,amount do
		if bone then
			Player(2):AddEntMarker( i, ent, bone.pos, nil, Color(255,150,0,255), time )
			debugoverlay.Cross( bone.pos, 2, 15, Color( 255, 255, 255 ), true)
			local bone_id = math.random( 1, #t_bones )
			local bone = t_bones[ bone_id ]

			if type <= 0 then
				local cent = ZD.cent(model_ice)
				cent:SetPos( bone.pos )
				cent:SetAngles( bone.ang )
				cent:SetModelScale( scale * math.Rand(0.01,0.05) )
				cent:SetParent( ent )
				cent:FollowBone( ent, bone_id )
				SafeRemoveEntityDelayed( cent, time)
				--ZDEV.DBUG.RegisterClientEntity( cent, 9 )
			else
				local cmdl = ZD.cmdl(model_ice)
				cmdl:SetPos( bone.pos )
				cmdl:SetAngles( bone.ang )
				cmdl:SetModelScale(  scale * math.Rand(0.01,0.05) )
				cmdl:SetParent( ent )
				cmdl:FollowBone( ent, bone_id )
				SafeRemoveEntityDelayed( cmdl, time)
				--ZDEV.DBUG.RegisterClientModel( cmdl, 9 )
			end
		end
	end
end
ZD.frbones = ZDEV.DBUG.FreezeBones

function ZDEV.DBUG.SetModelScale( ent, scale, deltatime )

	ent:SetModelScale( scale, deltatime )

end

concommand.Add( "zdev_dbug_setmodelscale", function(ply, cmd, arg) 
	local ent = ply:GetEyeTrace().Entity
	local scale = arg[1]
	local deltatime = arg[2]
	ZDEV.DBUG.SetModelScale(ent, scale, deltatime) 
end,nil,nil,0)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
ZDEV.FILE.SetLoaded( _f )
