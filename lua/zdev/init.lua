--[[
	init.lua
	Server initialization script for zdev addon.
	Author: zcomstudios
	Description: Handles server-side initialization logic for the zdev core.
]]
local _f = 'zdev/init.lua'
Msg("■")
MsgC(Color(200,50,255), 'ZDEV File:', color_white, _f .. '\n')
if ZDEV.FILE.Loaded(_f) then return end

AddCSLuaFile("zdev/shared.lua")
AddCSLuaFile("zdev/shared/zd_sh_advanced_nn.lua")
AddCSLuaFile("zdev/shared/zd_sh_simple_nn.lua")
AddCSLuaFile("zdev/shared/zd_sh_core.lua")
AddCSLuaFile("zdev/shared/zd_sh_effect.lua")
AddCSLuaFile("zdev/shared/zd_sh_editor.lua")
AddCSLuaFile("zdev/shared/zd_sh_player.lua")
AddCSLuaFile("zdev/shared/zd_sh_weapon.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_ent.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_ply.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_wep.lua")
AddCSLuaFile("zdev/shared/sh_items.lua")
AddCSLuaFile("zdev/shared/sh_items_defs.lua")

--zdev.SendCSFilesIn("zdev/shared/")

AddCSLuaFile("zdev/cl_init.lua")

--zdev.SendCSFilesIn("zdev/client/")



AddCSLuaFile("zdev/client/zd_cl_util.lua")
AddCSLuaFile("zdev/client/zd_cl_effect.lua")
AddCSLuaFile("zdev/client/zd_cl_draw.lua")
AddCSLuaFile("zdev/client/zd_cl_hud.lua")
AddCSLuaFile("zdev/client/zd_cl_render.lua")
AddCSLuaFile("zdev/client/zd_cl_vgui.lua")
AddCSLuaFile("zdev/client/zd_cl_imgui.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_dev_effects.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_msg.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_admin.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_editor_particle.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_editor_neuralnetwork.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_efx.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_mat.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_part.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_env.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_fonts.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_options.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_weapons.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_npcs.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_snpc.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_neuralnetwork.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_test.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_invslot.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_invitem.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_invgrid.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_equipslot.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_inventory.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_equipment.lua")
util.AddNetworkString("zdev_con_lua_tosv")
util.AddNetworkString("zdev_hud_msg_send")
util.AddNetworkString("zdev_hud_marker_ent")
util.AddNetworkString("zdev_hud_marker_ent_remove")

--include( 'includes/modules/neural_network.lua' )
include('zdev/shared.lua')

--zdev.IncludeFilesIn("zdev/server/")



include("zdev/server/zd_sv_database.lua")
include("zdev/server/zd_sv_core.lua")

include("zdev/server/meta/zd_sv_meta_ply.lua")
include("zdev/server/meta/zd_sv_meta_ent.lua")
include("zdev/server/meta/zd_sv_meta_wep.lua")
include("zdev/server/zd_sv_util.lua")
include("zdev/server/zd_sv_player.lua")
include("zdev/server/zd_sv_weapon.lua")

ZDEV.FILE.SetLoaded(_f)
