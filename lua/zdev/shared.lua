local _f = 'zdev/shared.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local function FormatFolder( folder )
	local result = string.upper( folder )
	result = string.Left( result , 3)
	return result
end
--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: FILE
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

-- ZDEV_UID: ZDEV_FUNC_CB2F5AEB | Path: ZDEV.FILE.InitDataDirectory
function ZDEV.FILE.InitDataDirectory( )
  zdev.log( "D", " Initializing data-folder hierarchy structure..." )

  local dir_root, dir_weap = ZDEV.DATA.RootDir, ZDEV.FILE.DIR.Weapons
  -- ■■ CREATE ROOT DIR and subfolders

  local b_exists = tobool( file.IsDir( dir_root, "DATA") )
  if not b_exists then
    file.CreateDir( dir_root )
    zdev.log( "D", " Created Root Data Directory: " .. dir_root )

    b_exists = tobool( file.IsDir( dir_weap, "DATA" ) )
    if not b_exists then
      file.CreateDir( dir_weap )
      zdev.log( "D", " \t Created sub-directory: " .. dir_weap )
    end
  end

end

-- ZDEV_UID: ZDEV_FUNC_EADB8134 | Path: ZDEV.FILE.InitDataFiles
function ZDEV.FILE.InitDataFiles( )
  zdev.log( "I", " Initializing core-data file(s)..." )

  local dir_root, dir_weap = ZDEV.DATA.RootDir, ZDEV.FILE.DIR.Weapons
  local file_cnfg, file_users = ZDEV.FILE.DataConfig, ZDEV.FILE.DIR.Players

  -- ■■ CREATE ROOT DIR and subfolders

  local b_exists = tobool( file.Exists( dir_root .. "/" .. file_cnfg, "DATA") )

  if not b_exists then
    file.Write( dir_root .. "/" .. file_cnfg, ZDEV.CNFG )
    zdev.log( "I", " Created Core-Data File: " .. file_cnfg )
  end

  b_exists = tobool( file.Exists( dir_root .. "/" .. file_users, "DATA") )
  if not b_exists then
    file.Write( dir_root .. "/" .. file_users, ZDEV.PLYR )
    zdev.log( "I", " \t Created Core-Data File: " .. file_users )
  end

end


--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: FILE
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_AF202117 | Path: ZDEV.CONT.LoadMaterials
function ZDEV.CONT.LoadMaterials( subdir )
	local roottbl = FormatFolder( subdir )
	ZDEV.CONT.MATS[ roottbl ] = {}
	local dir = "materials"
	local path = dir .. "/"..subdir
	local f, d = file.Find( path .. "--[[", "THIRDPARTY" )
	PrintTable( d )
	for k ,v in pairs( d ) do

		local tblid = FormatFolder( tostring(v) )
		ZDEV.CONT.MATS[ roottbl ][ tblid ] = {}

		local path2 = path .. "/" .. v
		local m, f = file.Find( path2 .. "--[[", "THIRDPARTY" )
		for l, p in pairs( m ) do
			local filepath = tostring(subdir.."/"..v.."/".. p)
			ZDEV.CONT.MATS[ roottbl ][ tblid ][l] = filepath
			print('')
			resource.AddFile( dir.."/"..filepath )

		end
	end
end

-- ZDEV_UID: ZDEV_FUNC_0DDF5DAB | Path: ZDEV.CONT.GetMaterials
function ZDEV.CONT.GetMaterials()
	return ZDEV.CONT.MATS
end

-- NOTE: The ZDEV Compressed Neural Input System (NPC AI) was extracted from
-- here when Core was slimmed to a platform. It now lives, parked, in
-- lua/.deprecated/zd_sh_nn_compressed_inputs.lua and is destined for the
-- upcoming ZDEV NPCs child addon. Core no longer defines ZDEV.CompressedInputs.

--zdev.IncludeFilesIn("zdev/shared/")




include( "shared/zd_sh_core.lua")
include( "shared/zd_sh_editor.lua")
include( "shared/zd_sh_effect.lua")
include( "shared/zd_sh_player.lua")
include( "shared/zd_sh_weapon.lua")
--include( "shared/zd_sh_simple_nn.lua")
--include( "shared/zd_sh_advanced_nn.lua")
include( "shared/meta/zd_sh_meta_ent.lua")
include( "shared/meta/zd_sh_meta_ply.lua")
include( "shared/meta/zd_sh_meta_wep.lua")
--include( "shared/sh_items.lua")
--include( "shared/sh_items_defs.lua")
--include( "shared/zd_sh_experience.lua")

ZDEV.FILE.SetLoaded( _f )
