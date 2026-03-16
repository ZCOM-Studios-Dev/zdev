local _f = 'zdev/client/vgui/zd_cl_menu_test.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local SW, SH = ScrW(), ScrH()
local SS = ScreenScale

local t_TypeConvert = {
  ["Number"] = "Int",
  ["boolean"] = "Boolean",
  ["float"] = "Float",
  ["string"] = "String",
  ["IMaterial"]= "String",
  ["Angle"] = "String",
  ["Vector"] = "String"
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

local t_categories = {
  ['Core'] = true,
  ['Extra'] = true,
  ['ViewModel'] = true,
  ['HUD'] = true,
  ['Effect'] = true,
  ['Primary'] = true,
  ['Secondary'] = true
}

local t_controls = {
  ['DTextEntry'] = {},
  ['DCheckboxLabel'] = {},
  ['DNumberWang'] = {},
  ['DNumSlider'] = {},
  ['DComboBox'] = {},
  ['DListView'] = {},
}
local FIELDS = {
  ['Category'] = {type='string', subtype='string', realm='CLIENT', category='Core', field='Category', default='other', control='DTextEntry', min=nil, max=nil, options={} },
  ['Author'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Author', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Contact'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Contact', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Purpose'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Purpose', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Instructions'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='Instructions', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['ViewModelFlip'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['ViewModelFlip1'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip1', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['ViewModelFlip2'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='ViewModelFlip2', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['ViewModelFOV'] = {type='number', subtype='int', realm='CLIENT', category='ViewModel', field='ViewModelFOV', default='62', control='DNumberWang', min=0, max=999, options={} },
  ['BobScale'] = {type='number', subtype='float', realm='CLIENT', category='ViewModel', field='BobScale', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['SwayScale'] = {type='number', subtype='float', realm='CLIENT', category='ViewModel', field='SwayScale', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['BounceWeaponIcon'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='BounceWeaponIcon', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['DrawWeaponInfoBox'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawWeaponInfoBox', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['DrawAmmo'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawAmmo', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['DrawCrosshair'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='DrawCrosshair', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['RenderGroup'] = {type='number', subtype='enumerator', realm='CLIENT', category='Effect', field='RenderGroup', default='rendergroup_opaque', control='DComboBox', min=nil, max=nil, options={} },
  ['SpeechBubbleLid'] = {type='number', subtype='textureID', realm='CLIENT', category='HUD', field='SpeechBubbleLid', default='surface.gettextureid( "gui/speech_lid" )', control='DTextEntry', min=nil, max=nil, options={} },
  ['WepSelectIcon'] = {type='number', subtype='textureID', realm='CLIENT', category='HUD', field='WepSelectIcon', default='surface.gettextureid( "weapons/swep" )', control='DTextEntry', min=nil, max=nil, options={} },
  ['CSMuzzleFlashes'] = {type='boolean', subtype='boolean', realm='CLIENT', category='Effect', field='CSMuzzleFlashes', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['CSMuzzleX'] = {type='boolean', subtype='boolean', realm='CLIENT', category='Effect', field='CSMuzzleX', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['UseHands'] = {type='boolean', subtype='boolean', realm='CLIENT', category='ViewModel', field='UseHands', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['AccurateCrosshair'] = {type='boolean', subtype='boolean', realm='CLIENT', category='HUD', field='AccurateCrosshair', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['ScriptedEntityType'] = {type='string', subtype='string', realm='CLIENT', category='Extra', field='ScriptedEntityType', default='weapon', control='DTextEntry', min=nil, max=nil, options={} },
  ['AutoSwitchFrom'] = {type='boolean', subtype='boolean', realm='SERVER', category='Extra', field='AutoSwitchFrom', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['AutoSwitchTo'] = {type='boolean', subtype='boolean', realm='SERVER', category='Extra', field='AutoSwitchTo', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['Weight'] = {type='number', subtype='int', realm='SERVER', category='Extra', field='Weight', default='5', control='DNumberWang', min=0, max=999, options={} },
  ['ClassName'] = {type='string', subtype='string', realm='SHARED', category='Core', field='ClassName', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['Spawnable'] = {type='boolean', subtype='boolean', realm='SHARED', category='Core', field='Spawnable', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['AdminOnly'] = {type='boolean', subtype='boolean', realm='SHARED', category='Core', field='AdminOnly', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['PrintName'] = {type='string', subtype='string', realm='SHARED', category='Core', field='PrintName', default='scripted weapon', control='DTextEntry', min=nil, max=nil, options={} },
  ['Base'] = {type='string', subtype='string', realm='SHARED', category='Core', field='Base', default='weapon_base', control='DTextEntry', min=nil, max=nil, options={} },
  ['m_WeaponDeploySpeed'] = {type='number', subtype='float', realm='SHARED', category='Extra', field='m_WeaponDeploySpeed', default='1', control='DNumSlider', min=0, max=9.99, options={} },
  ['Owner'] = {type='Entity', subtype='entity', realm='SHARED', category='Extra', field='Owner', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['ViewModel'] = {type='string', subtype='string', realm='SHARED', category='ViewModel', field='ViewModel', default='models/weapons/v_pistol.mdl', control='DTextEntry', min=nil, max=nil, options={} },
  ['WorldModel'] = {type='string', subtype='string', realm='SHARED', category='Effect', field='WorldModel', default='models/weapons/w_357.mdl', control='DTextEntry', min=nil, max=nil, options={} },
  ['HoldType'] = {type='number', subtype='choice', realm='SHARED', category='Core', field='HoldType', default='normal', control='DComboBox', min=nil, max=nil, options={} },
  ['Slot'] = {type='number', subtype='int', realm='SHARED', category='Core', field='Slot', default='0', control='DNumberWang', min=0, max=999, options={} },
  ['SlotPos'] = {type='number', subtype='int', realm='SHARED', category='Core', field='SlotPos', default='10', control='DNumberWang', min=0, max=999, options={} },
  ['Folder'] = {type='string', subtype='string', realm='SHARED', category='Core', field='Folder', default='', control='DTextEntry', min=nil, max=nil, options={} },
  ['DisableDuplicator'] = {type='boolean', subtype='boolean', realm='SHARED', category='Extra', field='DisableDuplicator', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['m_bPlayPickupSound'] = {type='boolean', subtype='boolean', realm='SHARED', category='Extra', field='m_bPlayPickupSound', default='true', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['Primary'] = {type='table', subtype='table', realm='SHARED', category='Primary', field='Primary', default='{}', control='DListView', min=nil, max=nil, options={} },
  ['Primary.ClipSize'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.ClipSize', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.DefaultClip'] = {type='number', subtype='int', realm='SHARED', category='Primary', field='Primary.DefaultClip', default='15', control='DNumberWang', min=0, max=999, options={} },
  ['Primary.Ammo'] = {type='string', subtype='choice', realm='SHARED', category='Primary', field='Primary.Ammo', default='"none"', control='DComboBox', min=nil, max=nil, options={} },
  ['Primary.Automatic'] = {type='boolean', subtype='boolean', realm='SHARED', category='Primary', field='Primary.Automatic', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
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
  ['Secondary.Ammo'] = {type='string', subtype='choice', realm='SHARED', category='Secondary', field='Secondary.Ammo', default='"none"', control='DComboBox', min=nil, max=nil, options={} },
  ['Secondary.Automatic'] = {type='boolean', subtype='boolean', realm='SHARED', category='Secondary', field='Secondary.Automatic', default='false', control='DCheckBoxLabel', min=nil, max=nil, options={} },
  ['Secondary.Damage'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.Damage', default='10', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.Cone'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Cone', default='0.025', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.NumShots'] = {type='number', subtype='int', realm='SHARED', category='Secondary', field='Secondary.NumShots', default='1', control='DNumberWang', min=0, max=999, options={} },
  ['Secondary.Force'] = {type='string', subtype='string', realm='SHARED', category='Secondary', field='Secondary.Force', default='"2"', control='DTextEntry', min=nil, max=nil, options={} },
  ['Secondary.Recoil'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Recoil', default='-2.5', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.Delay'] = {type='number', subtype='float', realm='SHARED', category='Secondary', field='Secondary.Delay', default='0.35', control='DNumSlider', min=0, max=9.99, options={} },
  ['Secondary.Sound'] = {type='string', subtype='sound', realm='SHARED', category='Secondary', field='Secondary.Sound', default='sound("weapon_ak47.single")', control='DTextEntry', min=nil, max=nil, options={} }
}
  --[[=============================================================
    ZDEV Test VGUI Mwnu
  ==================================================================]]
-- ZDEV_UID: ZDEV_FUNC_0BAB4F2D | Path: ZDEV.VGUI.TestMenu
function ZDEV.VGUI.TestMenu( ply, cmd, arg )

  if !cli or !IsValid(cli) or cli ~= LocalPlayer() then
    cli = LocalPlayer()
  end

  local e_ActiveWeapon = cli:GetActiveWeapon()
  local s_ClassName = e_ActiveWeapon:GetClass()
  local t_WeaponData = weapons.GetStored( s_ClassName )

  local menu = {}
  local menu_w, menu_h = SW * 0.66, SH * 0.66
  menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Test Menu")

  menu.dPL0 = vgui.Create( "DScrollPanel", menu )
  menu.dPL0:Dock( FILL )
  menu.dPL0:DockMargin( 1,1, menu_w*0.66,24 )
  menu.dPL0:SetWide( menu_w * 0.25 )

  local i_catID = 0
  for c, cat in pairs( t_categories ) do
    i_catID = i_catID + 1
    --local dP = vgui.Create( "DPanel", menu.dPL0 )

    local dD = vgui.Create( "DDrawer", menu.dPL0 )
    dD.ID = i_catID
    dD.Category = c
    dD:Dock( TOP )
    dD:DockMargin( 2, 9, 2, 9 )
    dD:SetOpenSize( 330 )		-- Default OpenSize is 100
    dD:SetOpenTime( 0.66 )		-- Default OpenTime is 0.3
    dD:Close()	
    
    timer.Simple( 0, function() dD:Toggle() end )
    menu.dPL0:AddItem( dD )

   -- local dP = menu.dPL0:Add( "DPanel" )
 
    dD.Div = vgui.Create( "DHorizontalDivider", dD )
    dD.Panel_L = vgui.Create( "DPanel", dD )
    dD.Panel_L.Paint = function( self, w, h )
      draw.RoundedBox( 4, 0, 0, w, h, Color(150,150,150,255) )
    end
    dD.Panel_R = vgui.Create( "DPanel", dD )
    dD.Panel_R.Paint = function( self, w, h )
      draw.RoundedBox( 4, 0, 0, w, h, Color(75,75,75,255) )
    end
    dD.Div:Dock( FILL )
    dD.Div:SetLeft( dD.Panel_L )
    dD.Div:SetRight( dD.Panel_R )
    dD.Div:SetDividerWidth( 3 )
    dD.Div:SetLeftMin( menu_w * 0.15 )
    dD.Div:SetRightMin( menu_w * 0.15 )
    dD.Div:SetLeftWidth( menu_w * 0.15 )

  --[[


    dD.Panel_L.dLbl = vgui.Create( "DLabel", dD.Panel_L )
    dD.Panel_L.dLbl:SetText( c )
    dD.Panel_L.dLbl:Dock( TOP )
    dD.Panel_L.dLbl:SetTextColor( Color(0,0,0,255) )
    dD.Panel_L.dLbl:DockMargin( 6, 2, 2, 2 )
]]
    menu.dPL0.Categories = {}
    menu.dPL0.Categories[ c ] = dD

  end


  

  for field, data in pairs( FIELDS ) do

    local dermacontrol = data.control
    local field = field
    local category = data.category

    local parent, parent_L
    --for _, v in ipairs( menu.dPL0:GetCanvas():GetChildren() ) do
    for _, d in ipairs( menu.dPL0:GetCanvas():GetChildren() ) do
      --print('')
      local p = d.Panel_R
      local p2 = d.Panel_L
      if d.Category == category then
        parent = p
        parent_L = p2
      end
    end
    local control = vgui.Create( dermacontrol, parent )
    control:Dock( TOP )
    control:DockMargin( 2,0, menu.dPL0:GetWide()*0.05, 0 )
    control:DockPadding( 0,0,0,0 )
    control:SetWide( menu_w * 0.25 )
    local lbl = Label( field, parent_L )
    lbl:Dock( TOP )
    lbl:DockMargin( 2,0,2,0 )
    lbl:DockPadding( 2,0,2,0 )
    lbl:SetTextColor( Color(0,0,0,255) )
    if dermacontrol == "DCheckBoxLabel" then
      control:SetText( field )
    elseif dermacontrol == "DNumSlider" then
      control:SetMinMax( data.min, data.max )
      control:SetValue( tonumber( data.default ) )
      control:SetText( field )
      control:SetDecimals( 3 )
    elseif dermacontrol == "DNumberWang" then
      control:SetMinMax( data.min, data.max )
      control:SetValue( tonumber( data.default ) )
      control:SetText( field )
      control:SetDecimals( 0 )
    elseif dermacontrol == "DTextEntry" then
      control:SetValue( data.default )
    elseif dermacontrol == "DComboBox" then
      control:SetValue( field )
      if field == "HoldType" then
        for _, ht in ipairs( table.GetKeys(t_holdtypes) ) do
          control:AddChoice( ht )
        end
      elseif field == "Primary.Ammo" or field == "Secondary.Ammo" then
        for _, at in ipairs( table.GetKeys(t_ammotypes) ) do
          control:AddChoice( at )
        end
      end
    elseif dermacontrol == "DListView" then

    end
  end
  
--[[


    
  menu.pr = vgui.Create( "DProperties", menu )
  menu.pr:Dock( FILL )
  menu.pr.rows = {}

      for k, v in pairs( t_WeaponData ) do
    local s_type = type(v)

    if s_type ~= "function" and s_type ~= "table" then

      local s_DataType = t_TypeConvert[ s_type ]

      print('')

      menu.pr.rows[ k ] = menu.pr:CreateRow( "Core", k )
      menu.pr.rows[ k ]:Setup( s_DataType )
      menu.pr.rows[ k ]:SetValue( v )
      menu.pr.rows[ k ].DataChanged = function( self, data )
        print('')
        if s_DataType == "Boolean" then
          data = tobool(data)
        end
        --self:SetValue(data)
        t_WeaponData[ k ] = data
      end
    end
  end
]]

  menu.dPL = vgui.Create( "DPanelList", menu )
  menu.dPL:Dock( BOTTOM )

  menu.dPL.bt0 = vgui.Create( "DButton", menu.dPL )
  menu.dPL.bt0:Dock( LEFT )
  menu.dPL.bt0:SetText( "✚" )
  menu.dPL.bt0:SetTextColor( Color(100,200,255,255) )
  menu.dPL.bt0:SetColor( Color(0,200,255,255) )
  menu.dPL.bt0.DoClick = function( self )
    weapons.Register( t_WeaponData, s_ClassName )
    ZDEV.VGUI.FileManager( "lua" )
  end

  menu.dPL.bt1 = vgui.Create( "DButton", menu.dPL )
  menu.dPL.bt1:Dock( RIGHT )
  menu.dPL.bt1:SetText( "✓" )
  menu.dPL.bt1:SetFont( "Default" )
  menu.dPL.bt1:SetTextColor( Color(100,255,100,255) )
  menu.dPL.bt1:SetColor( Color(0,200,0,255) )
  menu.dPL.bt1.DoClick = function( self )
    --weapons.Register( t_WeaponData, s_ClassName )
    ZDEV.VGUI.FileManager( "lua" )
  end

  menu.dPL.bt2 = vgui.Create( "DButton", menu.dPL )
  menu.dPL.bt2:Dock( RIGHT )
  menu.dPL.bt2:SetFont( "Default" )
  menu.dPL.bt2:SetText( "✕" )
  menu.dPL.bt2:SetTextColor( Color(255,0,0,255) )
  menu.dPL.bt2:SetColor( Color(200,0,0,255) )
  menu.dPL.bt2.DoClick = function( self )
    menu:Close()
    --weapons.Register( t_WeaponData, s_ClassName )
    --ZDEV.VGUI.FileManager( "lua" )
  end

end
concommand.Add( "zd_menu_test", ZDEV.VGUI.TestMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_test" )

ZDEV.FILE.SetLoaded( _f )
