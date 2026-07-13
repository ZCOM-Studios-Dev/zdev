local _f = 'zdev/shared/zd_sh_player.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end


--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: PLAYER DATA
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
ZDEV.DATA.NWTranslate = {
  ["rank|uid|playtime"] = "Int",
  ["zid|sid|nick|ip|ugroup"] = "String"
}

-- ZDEV_UID: ZDEV_FUNC_D46D6728 | Path: ZDEV.PLYR.DataNWTranslate
function ZDEV.PLYR.DataNWTranslate( data )
  for k, v in pairs( ZDEV.DATA.NWTranslate ) do
    if string.find( k, data, 1, false ) then
      return v
    end
  end
end

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: FILE - Users
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_87F96276 | Path: ZDEV.PLYR.LoadFile
function  ZDEV.PLYR.LoadFile()

  local data = file.Read( ZDEV.FILE.DataUsers, "DATA" )

  local t_data = util.KeyValuesToTable(data, false, false)
  zdev.log( "S", "Loaded global user-data file" )
  --PrintTable( t_data )

  for k, v in pairs( t_data ) do
    print(k, v)
  end

end


--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: RANKS
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

ZDEV.RANK = ZDEV.RANK or {}
ZDEV.RANK[ RANK_PLAYER ] = {name="Player", ico=Material("")}
ZDEV.RANK[ RANK_PRIVATE ] = {name="Private", ico=Material("vgui/ranks/1_private.png")}
ZDEV.RANK[ RANK_PRIVATE_1_CL ] = {name="Private First Class", ico=Material("vgui/ranks/2_private_first_class.png")}
ZDEV.RANK[ RANK_CORPORAL ] = {name="Corporal", ico=Material("vgui/ranks/3_corporal.png")}
ZDEV.RANK[ RANK_SERGEANT ] = {name="Sergeant", ico=Material("vgui/ranks/3_sergeant.png")}
ZDEV.RANK[ RANK_STF_SGT ] = {name="Staff Sergeant", ico=Material("vgui/ranks/4_staff_sergeant.png")}
ZDEV.RANK[ RANK_SGT_1_CL ] = {name="Sergeant First Class", ico=Material("vgui/ranks/5_sergeant_first_class.png")}
ZDEV.RANK[ RANK_MASTER_SGT ] = {name="Master Sergeant", ico=Material("vgui/ranks/6_master_sergeant.png")}
ZDEV.RANK[ RANK_1ST_SGT ] = {name="First Sergeant", ico=Material("vgui/ranks/7_first_sergeant.png")}
ZDEV.RANK[ RANK_SGT_MJR ] = {name="Sergeant Major", ico=Material("vgui/ranks/8_sergeant_major.png")}
ZDEV.RANK[ RANK_CMD_SGT_MJR ] = {name="Command Sergeant Major", ico=Material("vgui/ranks/9_command_sergeant_major.png")}
ZDEV.RANK[ RANK_SGT_MJR_OTA ] = {name="Sergeant Major of the Army", ico=Material("vgui/ranks/10_sergeant_major_of_the_army.png")}
ZDEV.RANK[ RANK_2_LIEUTENANT ] = {name="Second Lieutenant", ico=Material("vgui/ranks/11_second_lieutenant.png")}
ZDEV.RANK[ RANK_1_LIEUTENANT ] = {name="First Lieutenant", ico=Material("vgui/ranks/12_first_lieutenant.png")}
ZDEV.RANK[ RANK_CAPTAIN ] = {name="Captain", ico=Material("vgui/ranks/13_captain.png")}
ZDEV.RANK[ RANK_MAJOR ] = {name="Major", ico=Material("vgui/ranks/14_major.png")}
ZDEV.RANK[ RANK_LIEUTENANT_COL ] = {name="Lieutenant Colonel", ico=Material("vgui/ranks/15_lieutenant_colonel.png")}
ZDEV.RANK[ RANK_COLONEL ] = {name="Colonel", ico=Material("vgui/ranks/16_colonel.png")}
ZDEV.RANK[ RANK_BRIGADIER_GEN ] = {name="Brigadier General", ico=Material("vgui/ranks/17_brigadier_general.png")}
ZDEV.RANK[ RANK_MJR_GENERAL ] = {name="Major General", ico=Material("vgui/ranks/18_major_general.png")}
ZDEV.RANK[ RANK_LIEUTENANT_GEN ] = {name="Lieutenant General", ico=Material("vgui/ranks/19_lieutenant_general.png")}
ZDEV.RANK[ RANK_GENERAL ] = {name="General", ico=Material("vgui/ranks/20_general.png")}
ZDEV.RANK[ RANK_GENERAL_OTA ] = {name="General of the Army", ico=Material("vgui/ranks/21_general_of_the_army.png")}

-- ZDEV_UID: ZDEV_FUNC_A0EF4E6C | Path: ZDEV.RANK.Name
function ZDEV.RANK.Name( rank )
	return tostring( ZDEV.RANK[ rank ].name )
end

-- ZDEV_UID: ZDEV_FUNC_64328C5A | Path: ZDEV.RANK.Icon
function ZDEV.RANK.Icon( rank )
	return ZDEV.RANK[ rank ].ico
end

-- ZDEV_UID: ZDEV_FUNC_6A123FB4 | Path: ZDEV.PLYR.GetRank
function ZDEV.PLYR.GetRank( ply )

end

-- ZDEV_UID: ZDEV_FUNC_41CAA333 | Path: ZDEV.PLYR.Tick
function ZDEV.PLYR.Tick( ply, mv )

--  zdev.log( "D" , "PlayerTick " .. tostring( ply ) )

end
hook.Add("PlayerTick", "ZDEV.PLYR.Tick", ZDEV.PLYR.Tick )


-- ZDEV_UID: ZDEV_FUNC_12B380A1 | Path: ZDEV.PLYR.PostThink
function ZDEV.PLYR.PostThink( ply )

--  zdev.log( "D" , "PlayerPostThink " .. tostring( ply ) )

end
hook.Add("PlayerPostThink", "ZDEV.PLYR.PostThink", ZDEV.PLYR.PostThink )

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  FUNCTION ZDEV CORE: PLAYER HOOKS
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

-- ZDEV_UID: ZDEV_FUNC_3400F54D | Path: ZDEV.GAME.Think
function ZDEV.GAME.Think( )

end
hook.Add("Think", "ZDEV.GAME.Think", ZDEV.GAME.Think )


ZDEV.FILE.SetLoaded( _f )
