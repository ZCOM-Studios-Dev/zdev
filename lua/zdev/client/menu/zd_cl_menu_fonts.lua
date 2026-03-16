local _f = 'zdev/client/vgui/zd_cl_menu_fonts.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if not ZDEV.VGUI then ZDEV.VGUI = {} end

local SW, SH = ScrW(), ScrH()

ZDEV.VGUI.MENU.FONT = {}


local samplestring = [[abcdefghijklmnopqrstuvwxyz

ABCDEFGHIJKLMNOPQRSTUVWXYZ

`1234567890-=[]\\;\',./

~!@#$%^&*()_+{}|:\"<>?]]

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV VGUI: Font Menu
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_BD728EC3 | Path: ZDEV.VGUI.FontMenu
function ZDEV.VGUI.FontMenu( )

	local _fonts = {}
	for k, font in pairs( ZDEV.FONT._INDEX ) do
		print('')
		local t_font = table.Copy( font )
		t_font.id = k
		table.insert( _fonts, 1, t_font )
	end
	local menu = ZDEV.VGUI.CreateFrame( SW * 0.85, SH * 0.85, "ZDEV: Font Menu" )

	menu.sp = vgui.Create( "DScrollPanel", menu )
	menu.sp:Dock( FILL )
	menu.sp:DockMargin( 2, 2, 2, 2 )
	menu.sp.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(100,100,100,255) )
	end

	for j, f in ipairs( _fonts ) do

		print('')
		local fontname = f.id
		local pnl = vgui.Create( "DPanel", menu.sp )
		pnl:Dock( TOP )
		pnl:DockMargin(1,1,1,1)
		pnl:SetTall( 64 )
		pnl.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color(70,70,70,255) )
		end
		local s_fontdata = ""
		local i_count = 0
		pnl.PaintOver = function( self, w, h )
		-- draw.SimpleText( s_fontdata, tostring(k), w * 0.15 , h * 0.5, Color(0,0,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			draw.DrawText( "Font ID: " .. tostring(f.id) .. " Font Name: " .. tostring(f.font).."\n Size: "..tostring(f.size), "BudgetLabel", w * 0.015 , h * 0.05,Color(255,255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

			--draw.DrawText( samplestring, tostring(f.id), w * 0.015, h * 0.09, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			draw.SimpleTextOutlined( samplestring, fontname, w * 0.015, h * 0.5, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,1, Color(0,0,0,255) )
		end
		menu.sp:AddItem( pnl )

	end

end
concommand.Add( "zd_menu_font", ZDEV.VGUI.FontMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_font" )


ZDEV.FILE.SetLoaded( _f )
