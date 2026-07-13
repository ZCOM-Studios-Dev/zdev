local _f = 'zdev/client/vgui/zd_cl_menu_options.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if not ZDEV.VGUI then ZDEV.VGUI = {} end

local SW, SH = ScrW(), ScrH()

ZDEV.VGUI.MENU.OPTIONS = {}
ZDEV.VGUI.MENU.OPTIONS.CONVAR = {"zdev_hud_visor","zdev_hud_vitals","zdev_hud_ammo","zdev_hud_crosshair","zdev_hud_info","zdev_hud_chat","zdev_hud_messages","zdev_hud_markers","zdev_hud_exp","zdev_hud_effects","zdev_dev_hud_time","zdev_dev_hud_xhair","zdev_dev_hud_grid","zdev_dev_hud_entinfo","zdev_dev_hud_ents","zdev_debug_render","zdev_debug_render_entinfo",
"zdev_edit_particle_toggle",
"zdev_edit_env_toggle"
--[[

"zdev_hud_xhair_clr",
"zdev_dev_console_x", 
"zdev_dev_console_y", 
"zdev_dev_console_w", 
"zdev_dev_console_h", 
"zdev_dev_hud_time", 
"zdev_dev_hud_xhair", 
"zdev_dev_hud_grid", 
"zdev_dev_hud_entinfo",
"zdev_dev_hud_ents",
"zdev_debug_render",
"zdev_debug_render_entinfo",
"zdev_edit_particle_show_helpers",
"zdev_edit_particle_emitter", 
"zdev_edit_particle_id",
"zdev_edit_particle_mat",
"zdev_edit_particle_lifetime",
"zdev_edit_particle_dietime", 
"zdev_edit_particle_size_s",
"zdev_edit_particle_alpha_s",
"zdev_edit_particle_length_s",
"zdev_edit_particle_size_e",
"zdev_edit_particle_alpha_e",
"zdev_edit_particle_length_e",
"zdev_edit_particle_airres",
"zdev_edit_particle_bounce",
"zdev_edit_particle_collide", 
"zdev_edit_particle_lighting", 
"zdev_edit_particle_gravity", 
"zdev_edit_particle_velocity", 
"zdev_edit_particle_angles", 
"zdev_edit_particle_angular_velocity",
"zdev_edit_particle_color",
"zdev_edit_particle_color_r",
"zdev_edit_particle_color_g",
"zdev_edit_particle_color_b",
"zdev_edit_particle_color_a",
"zdev_edit_particle_roll",
"zdev_edit_particle_rolldelta",
"",
"zdev_edit_env_tool_mode",
"zdev_edit_env_brush_mode",
"zdev_edit_env_brush_radius",
"zdev_edit_env_brush_spacing",
"zdev_edit_env_brush_density",
"zdev_edit_env_brush_flow",
"zdev_edit_env_factor_trees",
"zdev_edit_env_factor_shrubs",
"zdev_edit_env_factor_grass",
"zdev_edit_env_factor_rocks",
"zdev_edit_env_factor_misc"]]
}

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV VGUI: Options Menu
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_09E26C99 | Path: ZDEV.VGUI.OptionsMenu
function ZDEV.VGUI.OptionsMenu( )

	local menu = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, "ZDEV: Options Menu" )

	menu.sp = vgui.Create( "DScrollPanel", menu )
	menu.sp:Dock( FILL )
	menu.sp:SetTall( menu:GetTall() )
	menu.sp:DockMargin( 2, 2, 2, 2 )
	menu.sp.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(100,100,100,150) )
	end

	menu.sp.cl = vgui.Create( "DCategoryList", menu.sp )
	menu.sp.cl:Dock( FILL )
	menu.sp.cl:SetTall( menu.sp:GetTall() )
	local cat1 = menu.sp.cl:Add( "ConVars - Boolean" )
	local pnl = vgui.Create( "DPanel" )
	pnl:SetTall( 128 )

	for k, cvar in pairs( ZDEV.VGUI.MENU.OPTIONS.CONVAR ) do

		local cbl = vgui.Create( "DCheckBoxLabel", pnl ) -- Create the checkbox
		cbl:SetText( cvar )					-- Set the text next to the box
		cbl:SetConVar( cvar )				-- Change a ConVar when the box it ticked/unticked
		cbl:SetValue( GetConVar(cvar):GetBool() )						-- Initial value
		cbl:Dock( TOP )
		cbl:SizeToContents()
		cbl:SetTextColor( Color(0,0,0,255) )

	end

	cat1:SetContents( pnl )

	local cat2 = menu.sp.cl:Add( "ConVars - Colors" )
	local pnl2 = vgui.Create( "DPanel" )

	pnl2.bt1 = vgui.Create( "DButton", pnl2 )
	pnl2.bt1:SetText( "HUD Primary Color")
	pnl2.bt1:SetPaintBackground( true )
	--pnl2.bt1:SetBackgroundColor( Color( 50,50,50 ))
	pnl2.bt1:Dock( TOP )
	pnl2.bt1.DoClick = function( self )
		local f1 = ZDEV.VGUI.CreateFrame( SW * 0.25, SH * 0.25, "HUD Primary Color")

		local cm = vgui.Create( "DColorMixer", f1 )
		cm:Dock(FILL)					-- Make Mixer fill place of Frame
		cm:SetPalette(true)  			-- Show/hide the palette 				DEF:true
		cm:SetAlphaBar(true) 			-- Show/hide the alpha bar 				DEF:true
		cm:SetWangs(true) 				-- Show/hide the R G B A indicators 	DEF:true
		cm:SetColor( string.ToColor( GetConVarString( "zdev_hud_clr_pri" ) ) ) 	-- Set the default color
		-- When the picked color is changed...
		function cm:ValueChanged( col )
			local r, g, b, a = col.r, col.g, col.b, col.a
			LocalPlayer():ConCommand( "zdev_hud_clr_pri "..r.." "..g.." "..b.." "..a )
			self:SetBackgroundColor( col )
		end

	end

	pnl2.bt2 = vgui.Create( "DButton", pnl2 )
	pnl2.bt2:SetText( "HUD Secondary Color")
	pnl2.bt2:SetPaintBackground( true )
	--pnl2.bt2:SetBackgroundColor( Color( 50,50,50 ))
	pnl2.bt2:Dock( TOP )
	pnl2.bt2.DoClick = function( self )
		local f1 = ZDEV.VGUI.CreateFrame( SW * 0.25, SH * 0.25, "HUD Primary Color")

		local cm = vgui.Create( "DColorMixer", f1 )
		cm:Dock(FILL)					-- Make Mixer fill place of Frame
		cm:SetPalette(true)  			-- Show/hide the palette 				DEF:true
		cm:SetAlphaBar(true) 			-- Show/hide the alpha bar 				DEF:true
		cm:SetWangs(true) 				-- Show/hide the R G B A indicators 	DEF:true
		cm:SetColor( string.ToColor( GetConVarString( "zdev_hud_clr_sec" ) ) ) 	-- Set the default color
		-- When the picked color is changed...
		function cm:ValueChanged( col )
			local r, g, b, a = col.r, col.g, col.b, col.a
			LocalPlayer():ConCommand( "zdev_hud_clr_sec "..r.." "..g.." "..b.." "..a )
			self:SetBackgroundColor( col )
		end
	end

	cat2:SetContents( pnl2 )

	menu.sp.cl:InvalidateLayout( true )

	menu.sp:AddItem( menu.sp.cl )

end
ZDEV.CMDS.Register( "zdev_menu_options", ZDEV.VGUI.OptionsMenu, { aliases = { "zd_menu_options" } } )
ZDEV.VGUI.AddToMainMenu( "zdev_menu_options" )

ZDEV.FILE.SetLoaded( _f )
