local _f = 'zdev/client/vgui/zd_cl_menu_weapons.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local SW, SH, SS = ScrW(), ScrH(), ScreenScale

local s_dir_icons = "entities/"
local t_properties = t_properties or {}
local weap_target, weap_selected, weap_load, weap_data
local list_btncmds = {
  { txt = "Give Current Ammo", cmd = "givecurrentammo", icon = Material("")}
}
local mats = {
  BGDefault = Material("vgui/ui/box/corner_1.png"),
  BGClick = Material("vgui/ui/box/corner_2.png"),
  OVSelect = Material("vgui/ui/btn/base_fx_highlight.png")
}

local t_TypeConvert = {
  ["int"] = "Int",
  ["number"] = "Int",
  ["boolean"] = "Boolean",
  ["float"] = "Float",
  ["string"] = "Generic",
  ["IMaterial"]= "Generic",
  ["Angle"] = "VectorColor",
  ["Vector"] = "VectorColor",
  ["table"] = "Generic",
  ["choice"] = "Combo",
  ["entity"] = "Generic",
  ["sound"] = "Generic",
  ["textureID"] = "Generic",
  ["table"] = "Combo"
}

local t_ammotypes = {
  ['AR2'] = true,
  ['AR2AltFire'] = true,
  ['Pistol'] = true,
  ['SMG1'] = true,
  ['357'] = true,
  ['XBowBolt'] = true,
  ['Buckshot'] = true,
  ['RPG_Round'] = true,
  ['SMG1_Grenade'] = true,
  ['Grenade'] = true,
  ['slam'] = true,
  ['AlyxGun'] = true,
  ['SniperRound'] = true,
  ['SniperPenetratedRound'] = true,
  ['Thumper'] = true,
  ['Gravity'] = true,
  ['Battery'] = true,
  ['GaussEnergy'] = true,
  ['CombineCannon'] = true,
  ['AirboatGun'] = true,
  ['StriderMinigun'] = true,
  ['HelicopterGun'] = true,
  ['9mmRound'] = true,
  ['MP5_Grenade'] = true,
  ['Hornet'] = true,
  ['StriderMinigunDirect'] = true,
  ['CombineHeavyCannon'] = true
}

local t_holdtypes = {
  ['pistol'] = true,
  ['smg'] = true,
  ['grenade'] = true,
  ['ar2'] = true,
  ['shotgun'] = true,
  ['rpg'] = true,
  ['physgun'] = true,
  ['crossbow'] = true,
  ['melee'] = true,
  ['slam'] = true,
  ['normal'] = true,
  ['fist'] = true,
  ['melee2'] = true,
  ['passive'] = true,
  ['knife'] = true,
  ['duel'] = true,
  ['camera'] = true,
  ['magic'] = true,
  ['revolver'] = true
}

local FIELDS = {
  ['Category'] = {type='string', subtype='string', realm='CLIENT', category='Core', field='Category', default='other', control='DTextEntry', min=nil, max=nil, options={} },
  ['Author'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Author', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Contact'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Contact', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Purpose'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Purpose', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Instructions'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Instructions', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['ViewModelFlip'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['ViewModelFlip1'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip1', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['ViewModelFlip2'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip2', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['ViewModelFOV'] = {type='number', subtype='int', realm='CLIENT', category='ViewModel', field='ViewModelFOV', default='62', control='DNumberWang', min=0, max=999, options={} },
  ['BobScale'] = {type='number', subtype='float', realm='CLIENT', category='ViewModel', field='BobScale', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['SwayScale'] = {type='number', subtype='float', realm='CLIENT', category='ViewModel', field='SwayScale', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['BounceWeaponIcon'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='BounceWeaponIcon', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['DrawWeaponInfoBox'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawWeaponInfoBox', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['DrawAmmo'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawAmmo', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['DrawCrosshair'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawCrosshair', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['RenderGroup'] = {type='number', subtype='enumerator', realm='CLIENT', category='Effect', field='RenderGroup', default='rendergroup_opaque', control='DComboBox', min=nil, max=nil, options={} },
  ['SpeechBubbleLid'] = {type='number', subtype='textureID', realm='CLIENT', category='HUD', field='SpeechBubbleLid', default='surface.gettextureid( "gui/speech_lid" )', control='DTextEntry', min=nil, max=nil, options={} },
  ['WepSelectIcon'] = {type='number', subtype='textureID', realm='CLIENT', category='HUD', field='WepSelectIcon', default='surface.gettextureid( "weapons/swep" )', control='DTextEntry', min=nil, max=nil, options={} },
  ['CSMuzzleFlashes'] = {type='boolean', subtype='boolean', realm='CLIENT', category='Effect', field='CSMuzzleFlashes', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['CSMuzzleX'] = {type='boolean', subtype='boolean', realm='CLIENT', category='Effect', field='CSMuzzleX', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['UseHands'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='UseHands', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['AccurateCrosshair'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='AccurateCrosshair', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['ScriptedEntityType'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='ScriptedEntityType', default='weapon', control='DTextEntry', min=nil, max=nil, options={} },
  ['AutoSwitchFrom'] = {type='boolean', subtype='boolean', realm='SERVER', category='Extra', field='AutoSwitchFrom', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['AutoSwitchTo'] = {type='boolean', subtype='boolean', realm='SERVER', category='Extra', field='AutoSwitchTo', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['Weight'] = {type='number', subtype='int', realm='SERVER', category='Extra', field='Weight', default='5', control='DNumberWang', min=0, max=999, options={} },
  ['ClassName'] = {type='string', subtype='string', realm='SHARED', category='Core', field='ClassName', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Spawnable'] = {type='boolean', subtype='boolean', realm='SHARED', category='Core', field='Spawnable', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['AdminOnly'] = {type='boolean', subtype='boolean', realm='SHARED', category='Core', field='AdminOnly', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['PrintName'] = {type='string', subtype='string', realm='SHARED', category='Core', field='PrintName', default='scripted weapon', control='DTextEntry', min=nil, max=nil, options={} },
  ['Base'] = {type='string', subtype='string', realm='SHARED', category='Core', field='Base', default='weapon_base', control='DTextEntry', min=nil, max=nil, options={} },
  ['m_WeaponDeploySpeed'] = {type='number', subtype='float', realm='SHARED', category='Extra', field='m_WeaponDeploySpeed', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['Owner'] = {type='Entity', subtype='entity', realm='SHARED', category='Extra', field='Owner', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['ViewModel'] = {type='string', subtype='string', realm='SHARED', category='ViewModel', field='ViewModel', default='models/weapons/v_pistol.mdl', control='DTextEntry', min=nil, max=nil, options={} },
  ['WorldModel'] = {type='string', subtype='string', realm='SHARED', category='Effect', field='WorldModel', default='models/weapons/w_357.mdl', control='DTextEntry', min=nil, max=nil, options={} },
  ['Slot'] = {type='number', subtype='int', realm='SHARED', category='Core', field='Slot', default='0', control='DNumberWang', min=0, max=999, options={} },
  ['SlotPos'] = {type='number', subtype='int', realm='SHARED', category='Core', field='SlotPos', default='10', control='DNumberWang', min=0, max=999, options={} },
  ['Folder'] = {type='string', subtype='string', realm='SHARED', category='Core', field='Folder', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['HoldType'] = {type='string', subtype='choice', realm='SHARED', category='Core', field='HoldType', default='', control='DComboBox', min=nil, max=nil, options=t_holdtypes },
  ['DisableDuplicator'] = {type='boolean', subtype='boolean', realm='SHARED', category='Extra', field='DisableDuplicator', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['m_bPlayPickupSound'] = {type='boolean', subtype='boolean', realm='SHARED', category='Extra', field='m_bPlayPickupSound', default='true', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['Primary'] = {type='table', subtype='table', realm='SHARED', category='Primary', field='Primary', default='{}', control='DListView', min=nil, max=nil, options={} },
  ['Primary.ClipSize'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.ClipSize', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.DefaultClip'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.DefaultClip', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.Ammo'] = {type='string', subtype='choice', realm='SHARED', category='Primary', field='Primary.Ammo', default='"none"', control='DComboBox', min=nil, max=nil, options=t_ammotypes },
  ['Primary.Automatic'] = {type='boolean', subtype='boolean', realm='SHARED', category='Primary', field='Primary.Automatic', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['Primary.Damage'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.Damage', default='10', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.Cone'] = {type='number', subtype='float', realm='SHARED', category='Primary', field='Primary.Cone', default='0.025', control='DNumSlider', min=0, max=9.99, options={} },
  ['Primary.NumShots'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.NumShots', default='1', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.Force'] = {type='string', subtype='string', realm='SHARED', category='Primary', field='Primary.Force', default='"2"', control='DTextEntry', min=nil, max=nil, options={} },
  ['Primary.Recoil'] = {type='number', subtype='float', realm='SHARED', category='Primary', field='Primary.Recoil', default='-2.5', control='DNumSlider', min=0, max=9.99, options={} },
  ['Primary.Delay'] = {type='number', subtype='float', realm='SHARED', category='Primary', field='Primary.Delay', default='0.35', control='DNumSlider', min=0, max=9.99, options={} },
  ['Primary.Sound'] = {type='string', subtype='sound', realm='SHARED', category='Primary', field='Primary.Sound', default='sound("weapon_ak47.single")', control='DTextEntry', min=nil, max=nil, options={} },
  ['Secondary'] = {type='table', subtype='table', realm='SHARED', category='Secondary', field='Secondary', default='{}', control='DListView', min=nil, max=nil, options={} },
  ['Secondary.ClipSize'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.ClipSize', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.DefaultClip'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.DefaultClip', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.Ammo'] = {type='string', subtype='choice', realm='SHARED', category='Secondary', field='Secondary.Ammo', default='"none"', control='DComboBox', min=nil, max=nil, options=t_ammotypes },
  ['Secondary.Automatic'] = {type='boolean', subtype='boolean', realm='SHARED', category='Secondary', field='Secondary.Automatic', default='false', control='DCheckboxLabel', min=nil, max=nil, options={} },
  ['Secondary.Damage'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.Damage', default='10', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.Cone'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Cone', default='0.025', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.NumShots'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.NumShots', default='1', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.Force'] = {type='string', subtype='string', realm='SHARED', category='Secondary', field='Secondary.Force', default='"2"', control='DTextEntry', min=nil, max=nil, options={} },
  ['Secondary.Recoil'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Recoil', default='-2.5', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.Delay'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Delay', default='0.35', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.Sound'] = {type='string', subtype='sound', realm='SHARED', category='Secondary', field='Secondary.Sound', default='sound("weapon_ak47.single")', control='DTextEntry', min=nil, max=nil, options={} }
}

local function GetWeapon( s_class )
  return weapons.GetStored( s_class )
end

local function SetupProperties( menu, tbl )
  for k, v in pairs( tbl ) do

    if !FIELDS[ k ] then
      FIELDS[ k ] = {type=type(v), subtype=type(v), realm="SHARED", category="Custom", field=k, default=v, control="DProperty_Generic", min=nil, max=nil, options={} }
    end

    local s_type = FIELDS[ k ].subtype

    if s_type ~= "function" then

      if s_type == "table" then
        if string.find( k, "Primary", 1, false) or string.find( k, "Secondary", 1, false) then
          local t = {}
          for g, r in pairs( v ) do
            g = k .. "." .. g
            t[ g ] = r
          end
          SetupProperties( menu, t )
        end
      end

      local s_DataType = t_TypeConvert[ s_type ]
      local t_Setup = {}
 
      local s_Category = FIELDS[ k ].category or "Custom"

      print('')

      local row  =  menu.pl.pr:CreateRow( s_Category, k )
      if k == "HoldType" or k == "Primary.Ammo" or k == "Secondary.Ammo" then
        s_DataType = "Combo"
        t_Setup = {text = "..." }
      end
    
      if s_DataType == "Int" or s_DataType == "Float" then
        t_Setup = { min = FIELDS[ k ].min, max = FIELDS[ k ].max }
      end
      
      row:Setup( s_DataType, t_Setup )
      if s_DataType == "Combo" then 
        for q, x in pairs( FIELDS[ k ].options ) do
          row:AddChoice( q, q )
        end
      end
      row:SetValue( v )
      row.DataChanged = function( self, data )
        print('')
        if s_DataType == "Boolean" then
          data = tobool(data)
        end
        
        if k == "HoldType" then
          for ht, _ in pairs( t_holdtypes ) do
            row:AddChoice( ht, ht )
          end
        elseif k == "Primary.Ammo" or k == "Secondary.Ammo" then
          for at, _ in pairs( t_ammotypes ) do
            row:AddChoice( at, at )
          end 
        else
        
        menu.t_WeaponData[ k ] = data

      end
        
        menu.pl.pr.rows[ k ] = row

      end
    end
  end


end

local function SetupModelPreview( panel, mdl )
  print('')
  panel:SetModel( mdl )
end

local e_ActiveWeapon, s_SelectedWeapon, s_ClassName, t_WeaponData

  --[[=============================================================
    ZDEV Weapons VGUI Mwnu
  ==================================================================]]
-- ZDEV_UID: ZDEV_FUNC_C6391935 | Path: ZDEV.VGUI.WeaponsMenu
function ZDEV.VGUI.WeaponsMenu( ply, cmd, arg )

  if !cli or !IsValid(cli) or cli ~= LocalPlayer() then cli = LocalPlayer() end

  local menu = {}
  menu = ZDEV.VGUI.CreateFrame( SW * 0.8, SH * 0.8, "ZDEV Weapons Management Menu")
  menu.s_SelectedClass = ""
  menu.t_WeaponData = {}
  menu._SelectWeapon = function( s_class )
    menu.s_SelectedClass = s_class
    local t_wep = weapons.GetStored( s_class )
    menu.t_WeaponData = t_wep
  
    SetupProperties( menu, t_wep )
    SetupModelPreview( menu.pl.pn.mp, t_wep.WorldModel )
  end  

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DMENU BAR
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.mb = vgui.Create( "DMenuBar", menu )
  menu.mb:DockMargin(2,2,2,0)

  menu.mb.m1 = menu.mb:AddMenu( "File" )
    menu.mb.m1:AddOption( "New", function() ZDEV.VGUI.FileManager() end ):SetIcon( "icon16/page_white_go.png")
    menu.mb.m1:AddOption( "Open", function()
      ZDEV.VGUI.FileManager( "data", "zdev", "weapons" )
    end ):SetIcon( "icon16/folder.png")
    menu.mb.m1:AddOption( "Save", function()
      Derma_StringRequest( "Save Filename","Directory: 'zdev/weapons/'","weapon_filename.txt",

      function( s_txt )
        ZDEV.WEAP.SaveFile( s_txt, t_WeaponData )
      end,

      function( s_txt )
        zdev.log( "D", " Cancelled File-save Dialogue")
      end,"Save","Cancel")
    end ):SetIcon( "icon16/page_save.png")
    menu.mb.m1:AddOption( "Update", function()
      weapons.Register( t_WeaponData, s_ClassName )
    end ):SetIcon( "icon16/page_go.png")
    menu.mb.m1:AddOption( "Close", function() end ):SetIcon( "icon16/cross.png")

  menu.mb.m2 = menu.mb:AddMenu( "Edit" )
    menu.mb.m2:AddOption( "Copy", function() end ):SetIcon( "icon16/page_copy.png")
    menu.mb.m2:AddOption( "Paste", function() end ):SetIcon( "icon16/paste_plain.png")
    menu.mb.m2:AddOption( "Delete", function() end ):SetIcon( "icon16/delete.png")
    menu.mb.m2:AddOption( "Lock", function() end ):SetIcon( "icon16/lock.png")

  menu.mb.m3 = menu.mb:AddMenu( "Options" )
    menu.mb.m3:AddOption( "Settings", function() end ):SetIcon( "icon16/cog.png")

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PANELLIST:LEFT
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.pl = vgui.Create( "DPanelList", menu )
  menu.pl:Dock( LEFT )
  menu.pl:DockMargin(2,2,2,32)
  menu.pl:SetPos( 2, 24 )
  menu.pl:SetWide( SW * 0.2 )
 -- menu.pl:StretchToParent( 2,32,2,2 )
  menu.pl:SetPaintBackground( false )
  menu.pl:SetBackgroundColor( Color( 150,150,150 ))
  menu.pl:AddItem(  Label( "LABEL", menu.pl) )
  menu.pl.Paint = function( self, w, h )
    local clr_bg = self:GetBackgroundColor()
    draw.RoundedBox( 0, 0, 0, w, h,  clr_bg)
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color( 200,200, 200))
  end
  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PANELLIST:LEFT - MODEL PANEL
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.pl.pn = vgui.Create( "DPanel", menu.pl )
  menu.pl.pn:Dock( TOP )
  menu.pl.pn:SetSize( menu.pl:GetWide(),  menu.pl:GetWide()/2 )
  menu.pl.pn.Paint = function( self, w, h )
    draw.RoundedBox(0, 0,0, w, h, Color(100,100,100))
  end

  menu.pl.pn.mp = vgui.Create( "DAdjustableModelPanel", menu.pl.pn )
  menu.pl.pn.mp:StretchToParent(1,1,1,1)
  menu.pl.pn.mp:SetModel( "models/error.mdl" )
  menu.pl.pn.mp:SetFOV( 40 )
  menu.pl.pn.mp:SetAmbientLight(Color(255, 255, 255, 255))
  menu.pl.pn.mp:SetPaintBackgroundEnabled( false )
  menu.pl.pn.mp:SetPaintBackground( false )
  --menu.pl.pn.mp:SetBackgroundColor( Color(200,200,200) )
  menu.pl.pn.mp.DoClick = function( self )

  end

  menu.pl.bt = vgui.Create( "DButton", menu.pl )
  menu.pl.bt:SetText( "Select Model" )					-- Set the text on the button
  menu.pl.bt:Dock( TOP )					-- Set the text on the button
  menu.pl.bt:MoveBelow( menu.pl.pn, 1)			-- Set the position on the frame
  menu.pl.bt:SetSize( 128, 32 )					-- Set the size
  menu.pl.bt.Paint = function(self, w, h)				-- A custom function run when clicked ( note the . instead of : )
    ZDEV.DRAW.MaterialBox( 0, 0, w, h, Material("vgui/ui/btn/01_metal2_a.png"), color_white )
  end
  menu.pl.bt.PaintOver = function(self, w, h)				-- A custom function run when clicked ( note the . instead of : )
    --ZDEV.DRAW.MaterialBox( 0, 0, w, h, Material(""), color_white )
  end
  menu.pl.bt.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
    ZDEV.VGUI.ModelSelect()			-- Run the console command "say hi" when you click it ( command, args )
  end

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PANELLIST:LEFT - PROPERTIES
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.pl.pr = vgui.Create( "DProperties", menu.pl )
  menu.pl.pr:Dock( FILL )
  menu.pl.pr:DockMargin( 2, 2, 2, 32 )
  menu.pl.pr.rows = {}

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    WEAPON SELECTION ICONS
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.sp = vgui.Create( "DScrollPanel", menu )
  menu.sp:Dock( FILL )
  menu.sp:DockMargin( 2, 24, 2, 2 )
  menu.sp:SetSize( menu:GetWide(), menu.pl.pn:GetTall() )
  menu.sp.Paint = function( self, w, h )
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color(200,200,200) )
    ZDEV.DRAW.MaterialBox( 0, 0, w, h, Material("vgui/ui/bg/gradient_1.png"), color_white )
  end

  menu.lo = vgui.Create( "DIconLayout", menu.sp )
  menu.lo:Dock( TOP )
  menu.lo:MakeDroppable("LayoutWeaponIcons", true)
  --menu.lo:DockMargin( 2, 24, 2, 2 )
  menu.lo:SetSize( menu.sp:GetWide(), menu.sp:GetTall() )
  menu.lo:SetPaintBorderEnabled( true )
  menu.lo:SetBorder( 2 )
  menu.lo:SetPaintBackground( true )
  menu.lo:SetBackgroundColor( Color( 100, 100, 100 ) )
  menu.lo:MakeDroppable( "unique_name" ) -- Allows us to rearrange children
  menu.lo:SetSpaceX(2)
  menu.lo:SetSpaceY(2)
  menu.lo:SetStretchWidth(true)
  menu.lo:SetStretchHeight(true)

  menu.sp:AddItem(menu.lo)
  
  local WeaponCache = weapons.GetList()
  for k, w in pairs( WeaponCache ) do


    local class = w.ClassName
    local name = w.name or w.PrintName

    if not string.find( class, "base",1,false) and string.find( class, "zdev_", 1, false ) then

      print('')

      local icon = tostring( s_dir_icons .. class .. ".png" )

      local ib = vgui.Create( "DImageButton", menu.lo )
      ib:SetImage( (icon) )
      ib:SetWide( 64 )
      ib:SetTall( 64 )
      ib:SetMouseInputEnabled( true )
      ib:SetDrawBorder( true )
      ib:SetPaintBorderEnabled( true )
      ib.Selected = false
      ib.BGImage = mats.BGDefault

      ib.DoClick = function( self )
        ib.BGImage = mats.BGClick
        timer.Simple( 0.6, function()  ib.BGImage = mats.BGDefault end )
        menu._SelectWeapon( class )
        ib.Selected = !ib.Selected
      end

      ib.DoRightClick = function( self )
        local mn = DermaMenu()
        mn:AddOption("Give", function()
          RunConsoleCommand( "give", class )
        end)
        mn:AddOption("View as KeyValues", function()
          local s_table = util.TableToKeyValues( weapons.GetStored( class ) )
          local df = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, class .. " SWEP Table - KeyValues" )
          df.te = ZDEV.VGUI.CreateTextEntry( df, df:GetWide(), df:GetTall(), s_table, "command", true, FILL )
        end)
        mn:AddOption("View as JSON", function()
          local s_table = util.TableToJSON( weapons.GetStored( class ), true )
          local df = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, class .. " SWEP Table - JSON" )
          df.te = ZDEV.VGUI.CreateTextEntry( df, df:GetWide(), df:GetTall(), s_table, "command", true, FILL )
        end)
        mn:AddOption("Export to KeyValues", function()
        local t_wep = weapons.GetStored( class )
          ZDEV.DATA.ExportToJSON( t_wep, string.lower( class ) )
        end)
        mn:AddOption("Export to JSON", function()
        local t_wep = weapons.GetStored( class )
          ZDEV.DATA.ExportToJSON( t_wep, string.lower( class ) )
        end)
        mn:Open()
      end

      ib.Paint = function( self, w, h )
        ZDEV.DRAW.MaterialBox( 0,0,w,h, ib.BGImage, color_white)
        if self.Selected then
          ZDEV.DRAW.MaterialBox( 0,0,w,h, mats.OVSelect, Color(255,255,255,150))
        end
      end
      Label( tostring(name), ib )
      menu.lo:Add( ib )
    end

  end

	menu.pl0 = vgui.Create( "DPanelList", menu.sp)
	menu.pl0:Dock(TOP)
	menu.pl0:MoveBelow( menu.lo )
	menu.pl0:SetSize( menu.sp:GetWide(), SH * 0.25 )
	menu.pl0.Paint = function( self, w, h )
		ZDEV.DRAW.OutlinedBox(0,0,w,h,2,Color(100,255,100) )
	end
  
  menu.sp:AddItem(menu.pl0)

------------------------------------------------------------
-- Bottom Button-Bar

  menu.pl2 = vgui.Create( "DPanelList", menu )
  menu.pl2:Dock( BOTTOM )
  menu.pl2:SetSize( menu.sp:GetWide(), 32 )
  menu.pl2:DockMargin(1,1,1,1)
  menu.pl2:MoveBelow( menu.sp )
  menu.pl2.Paint = function( self,w,h)
    ZDEV.DRAW.MaterialBox( 0, 0, w, h, Material("vgui/ui/panel/pnl_dark_gloss_3.png"), color_white )
  end


  menu.pl2.bt0 = ZDEV.VGUI.CreateButton( menu.pl2, 64, 32, "UPDATE",  "icon_seg", Color(200,200,200), nil )
  menu.pl2.bt0:SetText( "SAVE" )
  menu.pl2.bt0:SetTextColor( Color(100,255,100,255) )
  menu.pl2.bt0:SetColor( Color(150,150,150,255) )
  menu.pl2.bt0.Paint = function( self, w, h)
    ZDEV.DRAW.MaterialBox( 0, 0, w, h, Material("vgui/ui/btn/01_metal2_a.png"), color_white )
  end
  menu.pl2.bt0.DoClick = function( self )
    zdev.log( "I", "Registering updated SWEP weapon-table:" .. menu.s_SelectedClass )
    weapons.Register( weapons.GetStored( menu.s_SelectedClass ), menu.s_SelectedClass )
  end

  MENU = menu

  return menu

end
concommand.Add( "zd_menu_weapons", ZDEV.VGUI.WeaponsMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_weapons" )

ZDEV.FILE.SetLoaded( _f )