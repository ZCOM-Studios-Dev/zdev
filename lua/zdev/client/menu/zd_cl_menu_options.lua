local _f = 'zdev/client/vgui/zd_cl_menu_options.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if not ZDEV.VGUI then ZDEV.VGUI = {} end

local SW, SH = ScrW(), ScrH()

ZDEV.VGUI.MENU.OPTIONS = {}
ZDEV.VGUI.MENU.OPTIONS.CONVAR = {"zd_hud_visor","zd_hud_vitals","zd_hud_ammo","zd_hud_crosshair","zd_hud_info","zd_hud_chat","zd_hud_messages","zd_hud_effects","zd_dev_hud_time","zd_dev_hud_xhair","zd_dev_hud_grid","zd_dev_hud_entinfo","zd_dev_hud_ents","zd_debug_render","zd_debug_render_entinfo",
"zedit_particle_toggle",
"zedit_env_toggle"
--[[

"zd_xhair_clr",
"zd_dev_console_x", 
"zd_dev_console_y", 
"zd_dev_console_w", 
"zd_dev_console_h", 
"zd_dev_hud_time", 
"zd_dev_hud_xhair", 
"zd_dev_hud_grid", 
"zd_dev_hud_entinfo",
"zd_dev_hud_ents",
"zd_debug_render",
"zd_debug_render_entinfo",
"zedit_particle_show_helpers",
"zedit_particle_emitter", 
"zedit_particle_id",
"zedit_particle_mat",
"zedit_particle_lifetime",
"zedit_particle_dietime", 
"zedit_particle_size_s",
"zedit_particle_alpha_s",
"zedit_particle_length_s",
"zedit_particle_size_e",
"zedit_particle_alpha_e",
"zedit_particle_length_e",
"zedit_particle_airres",
"zedit_particle_bounce",
"zedit_particle_collide", 
"zedit_particle_lighting", 
"zedit_particle_gravity", 
"zedit_particle_velocity", 
"zedit_particle_angles", 
"zedit_particle_angular_velocity",
"zedit_particle_color",
"zedit_particle_color_r",
"zedit_particle_color_g",
"zedit_particle_color_b",
"zedit_particle_color_a",
"zedit_particle_roll",
"zedit_particle_rolldelta",
"",
"zedit_env_tool_mode",
"zedit_env_brush_mode",
"zedit_env_brush_radius",
"zedit_env_brush_spacing",
"zedit_env_brush_density",
"zedit_env_brush_flow",
"zedit_env_factor_trees",
"zedit_env_factor_shrubs",
"zedit_env_factor_grass",
"zedit_env_factor_rocks",
"zedit_env_factor_misc"]]
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
		cm:SetColor( string.ToColor( GetConVarString( "zd_hud_clr_pri" ) ) ) 	-- Set the default color
		-- When the picked color is changed...
		function cm:ValueChanged( col )
			local r, g, b, a = col.r, col.g, col.b, col.a
			LocalPlayer():ConCommand( "zd_hud_clr_pri "..r.." "..g.." "..b.." "..a )
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
		cm:SetColor( string.ToColor( GetConVarString( "zd_hud_clr_sec" ) ) ) 	-- Set the default color
		-- When the picked color is changed...
		function cm:ValueChanged( col )
			local r, g, b, a = col.r, col.g, col.b, col.a
			LocalPlayer():ConCommand( "zd_hud_clr_sec "..r.." "..g.." "..b.." "..a )
			self:SetBackgroundColor( col )
		end
	end

	cat2:SetContents( pnl2 )

	menu.sp.cl:InvalidateLayout( true )

	menu.sp:AddItem( menu.sp.cl )

end
concommand.Add( "zd_menu_options", ZDEV.VGUI.OptionsMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_options" )

ZDEV.FILE.SetLoaded( _f )
