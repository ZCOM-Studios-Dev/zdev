local _f = 'zdev/shared/zd_sh_player.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end


--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: PLAYER DATA
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
ZDEV.DATA.NWTranslate = {
  ["rank|uid|gold|playtime"] = "Int",
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
ZDEV.RANK[ RANK_PLAYER ] 		  = {sym="\\", name="Player", 	clr=color_white,    ico=Material("vgui/ranks/1.png")}
ZDEV.RANK[ RANK_TRAINEE ] 		= {sym="\\", name="Tarinee", 	clr=color_white,    ico=Material("vgui/ranks/1.png")}
ZDEV.RANK[ RANK_PRIVATE ] 		= {sym="R", name="Private", 		clr=color_white,  ico=Material("vgui/ranks/2.png")}
ZDEV.RANK[ RANK_CORPORAL ] 		= {sym="u", name="Corporal", 	clr=color_white,    ico=Material("vgui/ranks/3.png")}
ZDEV.RANK[ RANK_SERGEANT ] 		= {sym="A", name="Sergeant", 	clr=color_white,    ico=Material("vgui/ranks/8.png")}
ZDEV.RANK[ RANK_LIEUTENANT ] 	= {sym="a", name="Lieutenant", clr=color_white,   ico=Material("vgui/ranks/9.png")}
ZDEV.RANK[ RANK_CAPTAIN ] 		= {sym=";", name="Captain", 		clr=color_white,  ico=Material("vgui/ranks/11.png")}
ZDEV.RANK[ RANK_MAJOR ] 		  = {sym="K", name="Major", 			clr=color_white,    ico=Material("vgui/ranks/12.png")}
ZDEV.RANK[ RANK_COLONEL ] 		= {sym="O", name="Colonel", 		clr=color_white,  ico=Material("vgui/ranks/14.png")}

-- ZDEV_UID: ZDEV_FUNC_A0EF4E6C | Path: ZDEV.RANK.Name
function ZDEV.RANK.Name( rank )
	return tostring( ZDEV.RANK[ rank ].name )
end

-- ZDEV_UID: ZDEV_FUNC_D9EABF3D | Path: ZDEV.RANK.Color
function ZDEV.RANK.Color( rank )
	return ZDEV.RANK[ rank ].clr
end

-- ZDEV_UID: ZDEV_FUNC_C256F0DC | Path: ZDEV.RANK.Symbol
function ZDEV.RANK.Symbol( rank )
	return tostring( ZDEV.RANK[ rank ].sym )
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
