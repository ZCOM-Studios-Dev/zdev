--[[
	cl_init.lua
	Client initialization script for zdev addon.
	Author: zcomstudios
	Description: Handles client-side initialization logic for the zdev core.
]]
local _f = 'zdev/cl_init.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

do
	local LP = LP or LocalPlayer()

	local _fontfiles = ZDEV.FONT.GetFontFiles( )
	local _fonts={}

	for k, v in pairs( _fontfiles ) do
		local filename=string.lower( v )
		filename=string.Replace( filename, ".ttf", "")
	end

	_fonts["roboto-cn"]={ font="Roboto Cn", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=22,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=true}
	_fonts["sadmachine"]={ font="SadMachine", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=14,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["reactor7"]={ font="Reactor7", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=14,weight=100,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["bios"]={ font="NDS BIOS", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=14,weight=100,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["micro"]={ font="Micro", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=14,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["command"]={ font="EnterCommand", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=14,weight=100,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital_djb"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=48,weight=100,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital_djb_glow"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=48,weight=100,blursize=6,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital_djb_scan"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=48,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital_djb_scan_glow"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=48,weight=100,blursize=12,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital2_djb_scan"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital2_djb_scan_glow"]={ font="DJB Get Digital", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=12,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital7"]={	font="Digital-7 Mono",--  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital7_glow"]={	font="Digital-7 Mono",--  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=9,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital7_scan"]={	font="Digital-7 Mono",--  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["digital7_scan_glow"]={	font="Digital-7 Mono",--  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=6,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["raj"]={	font="Rajdhani", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["unica"]={	font="Unica One", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["visitor"]={	font="Visitor TT2 BRK", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=8,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["extros"]={	font="Extros Backstage", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["p1up"]={	font="Player 1 Up Bold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended=false, size=32,weight=100,blursize=0,scanlines=3,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=true, additive=true,	outline=false}
	_fonts["circuit"]={ font="Circuit",
		extended=false, size=36,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=false, additive=true,	outline=false}
	_fonts["circuit_glow"]={ font="Circuit",
		extended=false, size=36,weight=500,blursize=8,scanlines=6,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=false, additive=true,	outline=false}
	_fonts["barcode"]={ font="CODE3X",
		extended=true, size=24,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=false, additive=true,	outline=false}
	_fonts["barcode2"]={ font="Paskowy",
		extended=true, size=24,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=false, additive=true,	outline=false}
	_fonts["icon_mat"]={ font="Material Design Icons",
		extended=false, size=16,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=true,	rotary=false,	shadow=false, additive=true,	outline=false}
	_fonts["icon_seg"]={ font="Segoe MDL2 Assets",
		extended=true, size=16,weight=500,blursize=0,scanlines=0,antialias=true,underline=false,italic=false,strikeout=false,symbol=false,	rotary=false,	shadow=false, additive=true,	outline=false}

	local extrasizes={"sadmachine", "bios", "micro", "command", "ractor7"}

	for newname, fontdata in pairs( _fonts ) do
		ZDEV.FONT.Register( newname, fontdata )
	end

	ZDEV.MATS.INDEX = {
		glow3 = CreateMaterial( "zdev_glow_3", "UnlitGeneric", {
			["$basetexture"] = "effects/fas_glow_debris",
			["$additive"] = 1,
			["overbrightfactor"] = 17,
			["$translucent"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$ignorez"] = 1
		} )
	}

end

-- ZDEV_UID: ZDEV_FUNC_C14336FD | Path: ZDEV.MATS.CreateAll
function ZDEV.MATS.CreateAll( )

	local mats = ZDEV.MATS.INDEX

	for k, v in pairs( mats ) do
		print( k, v )
	end

end

--include( "zdev/client/ui3d2d.lua" )
--include( "includes/modules/neural_network.lua" )
include( "zdev/shared.lua" )
include( "zdev/shared/zd_sh_debug_console.lua" )

--zdev.IncludeFilesIn("zdev/client/")

include( "zdev/client/zd_cl_util.lua" )
include( "zdev/client/zd_cl_effect.lua" )
include( "zdev/client/zd_cl_draw.lua" )
include( "zdev/client/zd_cl_render.lua" )
include( "zdev/client/render/zd_cl_r3d.lua" )
include( "zdev/client/render/zd_cl_r3d_widget.lua" )
include( "zdev/client/render/zd_cl_r3d_demo.lua" )
include( "zdev/client/render/zd_cl_mesh.lua" )
include( "zdev/client/render/zd_cl_mesh_demo.lua" )
include( "zdev/client/zd_cl_imgui.lua" )
include( "zdev/client/zd_cl_imgui_test.lua" ) -- rewired Phase 6: devhub's imgui_test demo button needs it
include( "zdev/client/zd_cl_hud.lua" )
include( "zdev/client/hud/zd_cl_hud_widgets.lua" )   -- widget system BEFORE elements (they build trees on it)
include( "zdev/client/hud/zd_cl_hud_pickup.lua" )
include( "zdev/client/hud/zd_cl_hud_msg.lua" )
include( "zdev/client/hud/zd_cl_hud_elements.lua" )
include( "zdev/client/hud/zd_cl_hud_damage.lua" )   -- visor damage overlays (after elements: uses CHUD + DRAW.FX)
--include( "zdev/client/hud/zd_cl_hud_exp.lua" )
include( "zdev/client/hud/zd_cl_hud_dev_effects.lua" )
include( "zdev/client/zd_cl_vgui.lua" )
include( "zdev/client/vgui/zd_cl_tooltip.lua" )
include( "zdev/client/zd_cl_debug_console.lua" )
include( "zdev/client/zd_cl_debug_console_filter.lua" )
include( "zdev/client/zd_cl_debug_console_appearance.lua" ) -- theme/fonts; MUST precede the panel
include( "zdev/client/vgui/zd_cl_debug_console_panel.lua" )
include( "zdev/client/zd_cl_sidekick_relay.lua" )
--include( "zdev/client/vgui/zd_cl_dragoverlay.lua" )
if ZDEV.Settings and ZDEV.Settings.InventoryEnabled then
	--include( "zdev/client/vgui/zd_cl_invgrid.lua" )
	--include( "zdev/client/vgui/zd_cl_equipslot.lua" )
end
include( "zdev/client/menu/zd_cl_menu_fonts.lua" )
include( "zdev/client/menu/zd_cl_menu_options.lua" )
include( "zdev/client/menu/zd_cl_menu_dev.lua" )
include( "zdev/client/menu/zd_cl_imgui_devhub.lua" )
include( "zdev/client/menu/zd_cl_menu_editor_particle.lua" )
include( "zdev/client/menu/zd_cl_menu_editor_hud.lua" )
--include( "zdev/client/menu/zd_cl_menu_editor_neuralnetwork.lua" )
include( "zdev/client/menu/zd_cl_menu_dev_efx.lua" )
include( "zdev/client/menu/zd_cl_menu_dev_mat.lua" )
--include( "zdev/client/menu/zd_cl_menu_dev_part.lua" )
--include( "zdev/client/menu/zd_cl_menu_dev_env.lua" )
include( "zdev/client/menu/zd_cl_menu_admin.lua" )
--include( "zdev/client/menu/zd_cl_menu_neuralnetwork.lua" )
--include( "zdev/client/menu/zd_cl_menu_weapons.lua" )
--include( "zdev/client/menu/zd_cl_menu_npcs.lua" )
--include( "zdev/client/menu/zd_cl_menu_dev_snpc.lua" )
--include( "zdev/client/menu/zd_cl_menu_test.lua" )
--include( "zdev/client/menu/zd_cl_menu_test2.lua" )
if ZDEV.Settings and ZDEV.Settings.InventoryEnabled then
	--include( "zdev/client/menu/zd_cl_menu_inventory.lua" )
	--include( "zdev/client/menu/zd_cl_menu_equipment.lua" )
	--include( "zdev/client/menu/zd_cl_menu_inspect.lua" )
end
include( "zdev/client/menu/zd_cl_menu_database.lua" )
--include( "zdev/client/menu/zd_cl_menu_player.lua" )
include( "zdev/client/menu/zd_cl_menu_lua_repl.lua" )


ZDEV.FILE.SetLoaded( _f )
