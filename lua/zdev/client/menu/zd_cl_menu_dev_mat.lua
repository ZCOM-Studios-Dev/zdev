local _f = 'zdev/client/vgui/zd_cl_menu_dev_mat.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

local Lerp = Lerp
local type = type
local TEAM_SPY = TEAM_SPY
local TEAM_MERC = TEAM_MERC

--ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

local t_mat_files = {

}

local t_mat_shaders = {
  {name = "UnlitGeneric"},
  {name = "LightmappedGeneric"},
  {name = "LightmappedReflective"},
  {name = "Refract"},
  {name = "SpriteCard"},
  {name = "VertexLitGeneric"},
  {name = "MultiBlend"},
  {name = "Cable"},
  {name = "Water"},
  {name = "Sky"},
  {name = "WorldVertexTransition"},
  {name = "DecalModulate"},
  -- Add more as needed based on your use case
}

local t_mat_vars = {
-- {text='$phongtint', type= 'VectorColor', desc='Tints the Phong highlight, low values dim Phong highlight intensity', default='[.8 .8 1]'},
-- {text='$envmaptint', type='VectorColor', desc='Tints the Specular reflection, low values dim the Specular reflection intensity', default='[.075 .075 .125]'},
-- {text='$selfillumtint', type='VectorColor', desc='Tints the self-illumination', default='[1 1 1]'},
 {text='$phongfresnelranges', type='Generic', desc='Adds Fresnel term allowing to control Phong intensity depending on the surface angle of incidence relative to viewpoint', default='[1 4 6]'},
 {text='$phong', type='Boolean', desc='Enables Phong shading', default='1'},
 {text='$phongalbedotint', type='Boolean', desc='Tints Phong highlight with color from $basetexture, Green channel in $phongexponenttexture determines tint intensity', default='1'},
 {text='$normalmapalphaphongmask', type='Boolean', desc='Uses alpha channel from $bumpmap as Phong mask', default='1'},
 {text='$basemapalphaphongmask', type='Boolean', desc='Uses alpha channel from $basetexture as Phong mask', default='0'},
 {text='$basealphaenvmapmask', type='Boolean', desc='Uses alpha channel from $basetexture as an inverted reflection mask (darker areas on the mask will be more reflective)', default='1'},
 {text='$normalmapalphaenvmapmask', type='Boolean', desc='Uses alpha channel from $bumpmap as reflection mask', default='1'},
 {text='$rimlight', type='Boolean', desc='Enables Rim Light shading (doesnt work in L4D2)', default='1'},
 {text='$rimmask', type='Boolean', desc='Uses alpha channel from $exponenttexture as Rim Light mask', default='1'},
 {text='$model', type='Boolean', desc='Defines if the object is a world model or not and is needed to make some shaders work on models, like UnlitGeneric or Refract', default='1'},
 {text='$selfillum', type='Boolean', desc='Enables self-illumination, by default masked by alpha of $basetexture', default='0'},
 {text='$nocull', type='Boolean', desc='Enables double sided materials', default='1'},
 {text='$alphatest', type='Boolean', desc='Enables alpha test transperancy, uses the alpha of the $basetexture', default='1'},
 {text='$translucent', type='Boolean', desc='Enables transparency on the material, uses the alpha of the $basetexture', default='1'},
 {text='$halflambert', type='Boolean', desc='Softens the diffuse shading, resulting in lower contrast on the side of the model thats facing away from light', default='0'},
 {text='$phongboost', type='Float', desc='Increases Phong intensity. A value of 0 is the same as no value.', default='0.84'},
 {text='asccassacs', type='Float', desc='Controls Phong highlight tightness', default='24'},
 {text='$phongalbedoboost', type='Float', desc='Increases PhongAlbedoTint intensity', default='48'},
 {text='$envmapfresnel', type='Float', desc='Increases Specular reflection intensity, especially on areas facing away from the players point of view', default='1'},
 {text='$rimlightexponent ', type='Float', desc='Controls Rim Light tightness', default='24'},
 {text='$rimlightboost', type='Float', desc='Rim Light brightness factor', default='1.2'},
 {text='$detailscale ', type='Float', desc='Scale of the detail map allowing it to tile and give the impression of higher resolution', default='1'},
 {text='$detailblendfactor', type='Float', desc='Opacity of the detail map', default='0.5'},
 {text='animatedTextureFrameRate', type='integrer', desc='Framerate of the animation in frames per second', default='24'},
 {text='$detailblendmode ', type='integrer', desc='Type of blend mode to use when combining with albedo map', default='0'},
 {text='$basetexture', type='Generic', desc='Defines an Albedo (Diffuse) map', default='"diffuse"'},
 {text='$bumpmap', type='Generic', desc='Defines a Normal map', default='"normal"'},
 {text='$phongexponenttexture', type='Generic', desc='Defines an Exponent map', default='"exponent"'},
 {text='$phongwarptexture', type='Generic', desc='Defines a Phongwarp map', default='"phongwarp"'},
 {text='$lightwarptexture', type='Generic', desc='Defines a Lightwarp map', default='"lightwarp"'},
 {text='$surfaceprop', type='Generic', desc='Defines material type, affecting physical properties, sounds and bullet decals', default='"default"'},
 {text='$selfillummask', type='Generic', desc='Defines a custom map to mask self-illumination', default='"mask"'},
 {text='$detail ', type='Generic', desc='Detail map that blends with the albedo to increase detail when looking at a surface from a close distance', default='"detail"'},
 {text='$envmap', type='Generic', desc='Specular reflection cubemap. env_cubemap variable lets the map use the closest cubemap to the player position', default='env_cubemap'},
 {text='animatedTextureVar', type='Generic', desc='Defines the animated texture that contains the frames', default='$basetexture'},
 {text='animatedTextureFrameNumVar', type='Generic', desc='Number of animation frames', default=' $frame'}

}

-- ZDEV_UID: ZDEV_FUNC_4DA2FF67 | Path: ZDEV.VGUI.Editor_Materials
function ZDEV.VGUI.Editor_Materials( cmd, ply, arg )

  local EDITOR = {}

  EDITOR.SelectedMaterial = { file = arg[1] or "", name = "", data = {}, raw_vmt = "" }
  EDITOR.CurrentFilePath = ""
  EDITOR.IsModified = false

  local menu = ZDEV.VGUI.CreateFrame( SW * 0.66, SH * 0.66, "Material Editor")
  local menu_w, menu_h = menu:GetWide(), menu:GetTall()

  -- Helper function to update window title with modified indicator
  local function UpdateTitle()
    local title = "Material Editor"
    if EDITOR.CurrentFilePath ~= "" then
      title = title .. " - " .. EDITOR.CurrentFilePath
    end
    if EDITOR.IsModified then
      title = title .. " *"
    end
    menu:SetTitle(title)
  end

  -- Helper function to load VMT file
  local function LoadVMTFile(filepath)
    local content = file.Read(filepath, "GAME")
    if not content then
      content = file.Read(filepath, "DATA")
    end

    if content then
      EDITOR.SelectedMaterial.raw_vmt = content
      EDITOR.CurrentFilePath = filepath
      EDITOR.IsModified = false

      -- Try to parse as material
      local mat_path = string.StripExtension(filepath)
      local ok, mat = pcall(Material, mat_path)
      if ok and mat and not mat:IsError() then
        local kv_ok, kv = pcall(function() return mat:GetKeyValues() end)
        if kv_ok and kv then
          EDITOR.SelectedMaterial.data = kv
        end
      end

      -- Update UI
      if menu.sp and menu.sp.te then
        menu.sp.te:SetText(content)
      end
      UpdateTitle()
      zdev.log("S", "Loaded VMT file: " .. filepath)
      return true
    else
      zdev.log("E", "Failed to load VMT file: " .. filepath)
      return false
    end
  end

  -- Helper function to save VMT file
  local function SaveVMTFile(filepath)
    if not menu.sp or not menu.sp.te then return false end

    local content = menu.sp.te:GetText()
    file.CreateDir(string.GetPathFromFilename(filepath))

    local success = file.Write(filepath, content)
    if success then
      EDITOR.SelectedMaterial.raw_vmt = content
      EDITOR.CurrentFilePath = filepath
      EDITOR.IsModified = false
      UpdateTitle()
      zdev.log("S", "Saved VMT file: " .. filepath)
      Derma_Message("File saved successfully!", "Save VMT")
      return true
    else
      zdev.log("E", "Failed to save VMT file: " .. filepath)
      Derma_Message("Failed to save file!", "Save VMT Error")
      return false
    end
  end

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DMENU BAR
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.mb = vgui.Create( "DMenuBar", menu )
  menu.mb:DockMargin(2,2,2,0)

  menu.mb.m1 = menu.mb:AddMenu( "File" )
    menu.mb.m1:AddOption( "New VMT", function()
      EDITOR.SelectedMaterial.raw_vmt = '"VertexLitGeneric"\n{\n\t"$basetexture" ""\n}'
      EDITOR.CurrentFilePath = ""
      EDITOR.IsModified = true
      if menu.sp and menu.sp.te then
        menu.sp.te:SetText(EDITOR.SelectedMaterial.raw_vmt)
      end
      UpdateTitle()
    end ):SetIcon( "icon16/page_white_go.png")

    menu.mb.m1:AddOption( "Open VMT", function()
      Derma_StringRequest("Open VMT File", "Enter VMT file path (relative to materials/):", "",
        function(filepath)
          if not string.EndsWith(filepath, ".vmt") then
            filepath = filepath .. ".vmt"
          end
          local full_path = "materials/" .. filepath
          LoadVMTFile(full_path)
        end,
        function() end, "Open", "Cancel")
    end ):SetIcon( "icon16/folder.png")

    menu.mb.m1:AddOption( "Save VMT", function()
      if EDITOR.CurrentFilePath ~= "" then
        SaveVMTFile(EDITOR.CurrentFilePath)
      else
        -- Trigger Save As
        Derma_StringRequest("Save VMT File", "Enter filename (will be saved to data/zdev/mats/):", "material.vmt",
          function(filename)
            if not string.EndsWith(filename, ".vmt") then
              filename = filename .. ".vmt"
            end
            local filepath = "zdev/mats/" .. filename
            SaveVMTFile(filepath)
          end,
          function() end, "Save", "Cancel")
      end
    end ):SetIcon( "icon16/page_save.png")

    menu.mb.m1:AddOption( "Save VMT As...", function()
      Derma_StringRequest("Save VMT As", "Enter filename (will be saved to data/zdev/mats/):", "material.vmt",
        function(filename)
          if not string.EndsWith(filename, ".vmt") then
            filename = filename .. ".vmt"
          end
          local filepath = "zdev/mats/" .. filename
          SaveVMTFile(filepath)
        end,
        function() end, "Save", "Cancel")
    end ):SetIcon( "icon16/disk.png")

    menu.mb.m1:AddSpacer()
    menu.mb.m1:AddOption( "Reload Material", function()
      if EDITOR.SelectedMaterial.file ~= "" then
        local mat_path = EDITOR.SelectedMaterial.file
        local ok, mat = pcall(Material, mat_path)
        if ok and mat and not mat:IsError() then
          local kv_ok, kv = pcall(function() return mat:GetKeyValues() end)
          if kv_ok and kv then
            EDITOR.SelectedMaterial.data = kv
            if menu.sp and menu.sp.te then
              menu.sp.te:SetText(util.TableToKeyValues(kv))
            end
            Derma_Message("Material reloaded successfully!", "Reload Material")
          end
        end
      end
    end ):SetIcon( "icon16/arrow_refresh.png")

    menu.mb.m1:AddSpacer()
    menu.mb.m1:AddOption( "Close", function() menu:Close() end ):SetIcon( "icon16/cross.png")

  menu.mb.m2 = menu.mb:AddMenu( "Edit" )
    menu.mb.m2:AddOption( "Copy", function()
      if menu.sp and menu.sp.te then
        SetClipboardText(menu.sp.te:GetText())
        zdev.log("I", "Copied to clipboard")
      end
    end ):SetIcon( "icon16/page_copy.png")

    menu.mb.m2:AddOption( "Paste", function()
      if menu.sp and menu.sp.te then
        local clipboard = GetClipboardText()
        if clipboard and clipboard ~= "" then
          menu.sp.te:SetText(clipboard)
          EDITOR.IsModified = true
          UpdateTitle()
        end
      end
    end ):SetIcon( "icon16/paste_plain.png")

    menu.mb.m2:AddOption( "Select All", function()
      if menu.sp and menu.sp.te then
        menu.sp.te:SelectAllText()
      end
    end ):SetIcon( "icon16/text_align_justify.png")

    menu.mb.m2:AddSpacer()
    menu.mb.m2:AddOption( "Format KeyValues", function()
      if menu.sp and menu.sp.te and EDITOR.SelectedMaterial.data then
        local formatted = util.TableToKeyValues(EDITOR.SelectedMaterial.data)
        menu.sp.te:SetText(formatted)
        EDITOR.IsModified = true
        UpdateTitle()
      end
    end ):SetIcon( "icon16/text_indent.png")

  menu.mb.m3 = menu.mb:AddMenu( "View" )
    menu.mb.m3:AddOption( "Refresh Preview", function()
      if EDITOR.SelectedMaterial.file ~= "" then
        local mat_path = EDITOR.SelectedMaterial.file
        local ok, mat = pcall(Material, mat_path)
        if ok and mat and not mat:IsError() then
          menu.pnl.im:SetImage(mat_path)
        end
      end
    end ):SetIcon( "icon16/picture.png")

    menu.mb.m3:AddOption( "View as KeyValues", function()
      if EDITOR.SelectedMaterial.data then
        local formatted = util.TableToKeyValues(EDITOR.SelectedMaterial.data)
        menu.sp.te:SetText(formatted)
      end
    end ):SetIcon( "icon16/page_white_text.png")

    menu.mb.m3:AddOption( "View Raw VMT", function()
      if EDITOR.SelectedMaterial.raw_vmt ~= "" then
        menu.sp.te:SetText(EDITOR.SelectedMaterial.raw_vmt)
      end
    end ):SetIcon( "icon16/page_code.png")

    menu.mb.m3:AddSpacer()
    menu.mb.m3:AddOption( "Toggle Properties Panel", function()
      if menu.sp.pr then
        menu.sp.pr:SetVisible(not menu.sp.pr:IsVisible())
      end
    end ):SetIcon( "icon16/application_view_list.png")

  menu.mb.m4 = menu.mb:AddMenu( "Options" )
    menu.mb.m4:AddOption( "Settings", function() end ):SetIcon( "icon16/cog.png")
    menu.mb.m4:AddOption( "Config", function() end ):SetIcon( "icon16/config.png")
    menu.mb.m4:AddOption( "File Options", function()
      local opts = ZDEV.VGUI.CreateFrame( 420, 320, "File Options" )
      opts:Center()
      opts:MakePopup()

      local pad = 8
      local w = opts:GetWide() - pad * 2

      local pnl = vgui.Create("DPanel", opts)
      pnl:Dock(FILL)
      pnl:DockPadding(pad, pad, pad, pad)
      pnl.Paint = function() end

      -- Directory selector
      local lblDir = vgui.Create("DLabel", pnl)
      lblDir:Dock(TOP)
      lblDir:SetText("Directory")
      lblDir:DockMargin(0,0,0,4)
      lblDir:SetFont("BudgetLabel")

      local dirCombo = vgui.Create("DComboBox", pnl)
      dirCombo:Dock(TOP)
      dirCombo:SetWide(w)
      dirCombo:AddChoice("data/zdev/mats")
      dirCombo:AddChoice("materials")
      dirCombo:AddChoice("materials/addons")
      dirCombo:AddChoice("materials/models")
      dirCombo:ChooseOptionID(1)
      dirCombo:DockMargin(0,0,0,8)

      -- Filename / path override
      local lblFile = vgui.Create("DLabel", pnl)
      lblFile:Dock(TOP)
      lblFile:SetText("Filename (no extension to use material lookup, include .png for images)")
      lblFile:DockMargin(0,0,0,4)
      lblFile:SetFont("BudgetLabel")

      local fileEntry = vgui.Create("DTextEntry", pnl)
      fileEntry:Dock(TOP)
      fileEntry:SetWide(w)
      fileEntry:SetText( EDITOR.SelectedMaterial.file or "" )
      fileEntry:DockMargin(0,0,0,8)

      -- Permissions
      local lblPerm = vgui.Create("DLabel", pnl)
      lblPerm:Dock(TOP)
      lblPerm:SetText("Permissions")
      lblPerm:DockMargin(0,0,0,4)
      lblPerm:SetFont("BudgetLabel")

      local permRead = vgui.Create("DCheckBoxLabel", pnl)
      permRead:Dock(TOP)
      permRead:SetText("Read")
      permRead:SetValue(true)
      permRead:DockMargin(0,0,0,2)

      local permWrite = vgui.Create("DCheckBoxLabel", pnl)
      permWrite:Dock(TOP)
      permWrite:SetText("Write")
      permWrite:SetValue(false)
      permWrite:DockMargin(0,0,0,2)

      local permDelete = vgui.Create("DCheckBoxLabel", pnl)
      permDelete:Dock(TOP)
      permDelete:SetText("Delete")
      permDelete:SetValue(false)
      permDelete:DockMargin(0,0,0,8)

      -- Scope
      local lblScope = vgui.Create("DLabel", pnl)
      lblScope:Dock(TOP)
      lblScope:SetText("Access Scope")
      lblScope:DockMargin(0,0,0,4)
      lblScope:SetFont("BudgetLabel")

      local scopeCombo = vgui.Create("DComboBox", pnl)
      scopeCombo:Dock(TOP)
      scopeCombo:SetWide(w)
      scopeCombo:AddChoice("Local (player only)")
      scopeCombo:AddChoice("Addon (zdev)")
      scopeCombo:AddChoice("Game (server/game files)")
      scopeCombo:ChooseOptionID(2)
      scopeCombo:DockMargin(0,0,0,8)

      -- Extra properties (freeform)
      local lblProps = vgui.Create("DLabel", pnl)
      lblProps:Dock(TOP)
      lblProps:SetText("Extra Properties (key=value, comma separated)")
      lblProps:DockMargin(0,0,0,4)
      lblProps:SetFont("BudgetLabel")

      local propsEntry = vgui.Create("DTextEntry", pnl)
      propsEntry:Dock(TOP)
      propsEntry:SetWide(w)
      propsEntry:SetText("")
      propsEntry:DockMargin(0,0,0,12)

      -- Buttons
      local btnPanel = vgui.Create("DPanel", pnl)
      btnPanel:Dock(BOTTOM)
      btnPanel:SetTall(28)
      btnPanel.Paint = function() end

      local applyBtn = vgui.Create("DButton", btnPanel)
      applyBtn:Dock(RIGHT)
      applyBtn:SetWide(100)
      applyBtn:SetText("Apply")
      applyBtn.DoClick = function()
        local dir = dirCombo:GetValue()
        local fname = string.Trim(fileEntry:GetValue() or "")
        if fname == "" then
          Derma_Message("Please enter a filename or path.", "File Options")
          return
        end

        local use_path = fname
        -- if user didn't include a slash, prefix with selected directory
        if not string.find(fname, "/", 1, true) and not string.find(fname, "\\", 1, true) then
          use_path = dir .. "/" .. fname
        end

        -- Update editor state
        EDITOR.SelectedMaterial.file = use_path

        -- Try to refresh material data safely
        local ok, mat = pcall(Material, use_path)
        if ok and mat then
          local kv_ok, kv = pcall(function() return mat:GetKeyValues() end)
          if kv_ok and kv then
            EDITOR.SelectedMaterial.data = kv
            if menu and menu.pnl and menu.pnl.im and menu.sp and menu.sp.te then
              menu.pnl.im:SetImage( string.StripExtension( EDITOR.SelectedMaterial.file ) )
              menu.pnl.im.te:SetText( string.StripExtension( EDITOR.SelectedMaterial.file ) )
              menu.sp.te:SetText( util.TableToKeyValues( EDITOR.SelectedMaterial.data ) )
            end
            Derma_Message("File selection applied and material data refreshed.", "File Options")
          else
            Derma_Message("Applied path, but failed to parse material keyvalues.", "File Options")
          end
        else
          Derma_Message("Applied path, but Material() could not be created for that path.", "File Options")
        end

        -- Here you could persist permissions/scope/props to a settings table if desired
        opts:Close()
      end

      local closeBtn = vgui.Create("DButton", btnPanel)
      closeBtn:Dock(RIGHT)
      closeBtn:SetWide(100)
      closeBtn:SetText("Close")
      closeBtn.DoClick = function() opts:Close() end

      -- Optional: quick delete (requires Delete permission)
      local delBtn = vgui.Create("DButton", btnPanel)
      delBtn:Dock(LEFT)
      delBtn:SetWide(120)
      delBtn:SetText("Delete (danger)")
      delBtn.DoClick = function()
        if not permDelete:GetChecked() then
          Derma_Message("Delete permission not enabled.", "File Options")
          return
        end
        Derma_Query("Are you sure you want to remove references to this file from the editor?", "Confirm Delete",
          "Yes", function()
            -- clear selection
            EDITOR.SelectedMaterial = { file = "", name = "" }
            if menu and menu.pnl and menu.pnl.im and menu.sp and menu.sp.te then
              menu.pnl.im:SetImage("sprites/efx_0a_glow_21")
              menu.pnl.im.te:SetText("")
              menu.sp.te:SetText("")
            end
            Derma_Message("Material reference cleared from editor. This does not delete game files.", "File Options")
            opts:Close()
          end,
          "No", function() end
        )
      end
    end )


   --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DPANEL TOP
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.pnl = vgui.Create( "DPanel", menu )
  menu.pnl:Dock( TOP )
  menu.pnl:SetSize( menu_w, 256 )
  menu.pnl.Paint = function( self, w, h )
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color(0,200,255,255) )
  end

  menu.pnl.im2 = vgui.Create("DHTML", menu.pnl)
  menu.pnl.im2:Dock(RIGHT)
  menu.pnl.im2:SetSize(256, 256)
  menu.pnl.im2:SetVisible(false)


  menu.pnl.im = vgui.Create( "DImage", menu.pnl)
  menu.pnl.im:Dock( LEFT )
  menu.pnl.im:SetPos(0,0)
  --menu.pnl.im:DockMargin(0,0,menu_w*0.5,0)
  menu.pnl.im:SetImage( "sprites/efx_0a_glow_21")
  menu.pnl.im:SetSize( 256, 256 )

    menu.pnl.im.te = vgui.Create( "DTextEntry", menu.pnl.im )
    menu.pnl.im.te:Dock(BOTTOM)
    menu.pnl.im.te:SetText( "sprites/efx_0a_glow_21" )

      menu.pnl.im.te.btn = vgui.Create( "DButton", menu.pnl.im.te )
      menu.pnl.im.te.btn:Dock(RIGHT)
      menu.pnl.im.te.btn:SetText( "..." )
      menu.pnl.im.te.btn.DoClick = function( self )

      end

  
  local sprite = vgui.Create("DSprite", menu.pnl)
  sprite:SetMaterial(Material("sprites/sent_ball"))
  sprite:SetColor(Color(0, 255, 255))
  sprite:Center()
  sprite:SetSize(200, 200)

  menu.pnl.nt = ZDEV.VGUI.CreateNodeTree( menu.pnl, 2, 26, menu_w, menu_h, t_mat_files )
  menu.pnl.nt:Dock( FILL )
 -- menu.pnl.nt:MoveRightOf( menu.pnl.im )
  --menu.pnl.nt:SetSize( 256, 256 )

  --menu.sp.nt:SetTall( menu_h*0.5)

  menu.pnl.nt.OnNodeSelected = function(self, node)
    local material_file_cur = EDITOR.SelectedMaterial.file
    local path = node:GetPathID()
    local folder = node:GetFolder()
    local text = node:GetText()
    local file_noext = string.StripExtension(text)
    local file_ext = string.GetExtensionFromFilename(text)
    local parent = node:GetParentNode()
    local parent_text = parent:GetText()

    local material_file = parent_text .. "/" .. file_noext
    if file_ext and string.find(file_ext, "png", 1, true) then
      material_file = parent_text .. "/" .. text
    end

    print(folder, material_file)

    EDITOR.SelectedMaterial.file = material_file
    EDITOR.SelectedMaterial.data = Material(material_file):GetKeyValues()
    menu.pnl.im:SetImage(string.StripExtension(EDITOR.SelectedMaterial.file))
    menu.pnl.im.te:SetText(string.StripExtension(EDITOR.SelectedMaterial.file))
    menu.sp.te:SetText(util.TableToKeyValues(EDITOR.SelectedMaterial.data))

    if file_ext and string.lower(file_ext) == "png" then
      local url = "asset:--" .. material_file
      menu.pnl.im2:SetVisible(true)
      menu.pnl.im2:OpenURL(url)
    else
      menu.pnl.im2:SetVisible(false)
    end
  end

  local n = menu.pnl.nt:Root()
  n:AddFolder( "Garry's Mod", "materials", "GAME", true, "*", false )
  n:AddFolder( "Addons", "materials", "THIRDPARTY", true, "*", false )

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    VMT FILE BROWSER PANEL
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.fb = vgui.Create( "DPanel", menu )
  menu.fb:Dock( LEFT )
  menu.fb:SetWide( 280 )
  menu.fb:DockMargin( 4, 4, 4, 4 )
  menu.fb.Paint = function( self, w, h )
    draw.RoundedBox( 4, 0, 0, w, h, Color(30, 35, 45, 255) )
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(0, 150, 200, 150) )
  end

  -- Directory label
  menu.fb.lbl = vgui.Create( "DLabel", menu.fb )
  menu.fb.lbl:Dock( TOP )
  menu.fb.lbl:SetText( "VMT Directory:" )
  menu.fb.lbl:SetFont( "BudgetLabel" )
  menu.fb.lbl:DockMargin( 4, 4, 4, 2 )

  -- Directory path entry
  menu.fb.dirEntry = vgui.Create( "DTextEntry", menu.fb )
  menu.fb.dirEntry:Dock( TOP )
  menu.fb.dirEntry:SetTall( 24 )
  menu.fb.dirEntry:SetText( "zdev/mats" )
  menu.fb.dirEntry:DockMargin( 4, 0, 4, 4 )
  menu.fb.dirEntry:SetTooltip( "Enter directory path relative to data/ folder" )

  -- Button panel for directory controls
  menu.fb.btnPanel = vgui.Create( "DPanel", menu.fb )
  menu.fb.btnPanel:Dock( TOP )
  menu.fb.btnPanel:SetTall( 28 )
  menu.fb.btnPanel:DockMargin( 4, 0, 4, 4 )
  menu.fb.btnPanel.Paint = function() end

  -- Refresh button
  menu.fb.btnRefresh = vgui.Create( "DButton", menu.fb.btnPanel )
  menu.fb.btnRefresh:Dock( LEFT )
  menu.fb.btnRefresh:SetWide( 80 )
  menu.fb.btnRefresh:SetText( "Refresh" )
  menu.fb.btnRefresh:SetIcon( "icon16/arrow_refresh.png" )

  -- Create Dir button
  menu.fb.btnCreateDir = vgui.Create( "DButton", menu.fb.btnPanel )
  menu.fb.btnCreateDir:Dock( LEFT )
  menu.fb.btnCreateDir:SetWide( 90 )
  menu.fb.btnCreateDir:SetText( "Create Dir" )
  menu.fb.btnCreateDir:SetIcon( "icon16/folder_add.png" )
  menu.fb.btnCreateDir:DockMargin( 4, 0, 0, 0 )
  menu.fb.btnCreateDir.DoClick = function()
    local dir = menu.fb.dirEntry:GetText()
    if dir ~= "" then
      file.CreateDir( dir )
      zdev.log( "S", "Created directory: " .. dir )
      menu.fb.btnRefresh:DoClick()
    end
  end

  -- File list label
  menu.fb.lblFiles = vgui.Create( "DLabel", menu.fb )
  menu.fb.lblFiles:Dock( TOP )
  menu.fb.lblFiles:SetText( "VMT Files:" )
  menu.fb.lblFiles:SetFont( "BudgetLabel" )
  menu.fb.lblFiles:DockMargin( 4, 4, 4, 2 )

  -- File list
  menu.fb.fileList = vgui.Create( "DListView", menu.fb )
  menu.fb.fileList:Dock( FILL )
  menu.fb.fileList:DockMargin( 4, 0, 4, 4 )
  menu.fb.fileList:SetMultiSelect( false )
  menu.fb.fileList:AddColumn( "Filename" ):SetWidth( 180 )
  menu.fb.fileList:AddColumn( "Size" ):SetWidth( 60 )

  -- Function to refresh file list
  local function RefreshFileList()
    menu.fb.fileList:Clear()
    local dir = menu.fb.dirEntry:GetText()
    if dir == "" then dir = "zdev/mats" end

    local files, dirs = file.Find( dir .. "--[[.vmt", "DATA" )
    if files then
      for _, fname in ipairs( files ) do
        local fpath = dir .. "/" .. fname
        local fsize = file.Size( fpath, "DATA" )
        local sizeStr = fsize and string.format( "%.1f KB", fsize / 1024 ) or "?"
        local line = menu.fb.fileList:AddLine( fname, sizeStr )
        line.FilePath = fpath
        line.FileName = fname
      end
    end

    -- Also check GAME path for materials
    local gameFiles = file.Find( "materials/" .. dir .. "--[[.vmt", "GAME" )
    if gameFiles then
      for _, fname in ipairs( gameFiles ) do
        local fpath = "materials/" .. dir .. "/" .. fname
        local line = menu.fb.fileList:AddLine( fname .. " (GAME)", "N/A" )
        line.FilePath = fpath
        line.FileName = fname
        line.IsGameFile = true
      end
    end

    zdev.log( "I", "Refreshed file list for: " .. dir )
  end

  menu.fb.btnRefresh.DoClick = RefreshFileList

  -- File action buttons panel
  menu.fb.actionPanel = vgui.Create( "DPanel", menu.fb )
  menu.fb.actionPanel:Dock( BOTTOM )
  menu.fb.actionPanel:SetTall( 100 )
  menu.fb.actionPanel:DockMargin( 4, 4, 4, 4 )
  menu.fb.actionPanel.Paint = function( self, w, h )
    draw.RoundedBox( 4, 0, 0, w, h, Color(40, 45, 55, 200) )
  end

  -- New VMT button
  menu.fb.btnNew = vgui.Create( "DButton", menu.fb.actionPanel )
  menu.fb.btnNew:Dock( TOP )
  menu.fb.btnNew:SetTall( 26 )
  menu.fb.btnNew:SetText( "New VMT" )
  menu.fb.btnNew:SetIcon( "icon16/page_white_add.png" )
  menu.fb.btnNew:DockMargin( 4, 4, 4, 2 )
  menu.fb.btnNew.DoClick = function()
    local template = [["VertexLitGeneric"
{
	"$basetexture" "models/debug/debugwhite"
	"$model" "1"
}]]
    menu.sp.te:SetText( template )
    EDITOR.SelectedMaterial.raw_vmt = template
    EDITOR.CurrentFilePath = ""
    EDITOR.IsModified = true
    UpdateTitle()
    zdev.log( "I", "Created new VMT template" )
  end

  -- Load button
  menu.fb.btnLoad = vgui.Create( "DButton", menu.fb.actionPanel )
  menu.fb.btnLoad:Dock( TOP )
  menu.fb.btnLoad:SetTall( 28 )
  menu.fb.btnLoad:SetText( "Load Selected VMT" )
  menu.fb.btnLoad:SetIcon( "icon16/folder_page.png" )
  menu.fb.btnLoad:DockMargin( 4, 4, 4, 2 )
  menu.fb.btnLoad.DoClick = function()
    local selected = menu.fb.fileList:GetSelectedLine()
    if not selected then
      Derma_Message( "Please select a file to load.", "Load VMT" )
      return
    end

    local line = menu.fb.fileList:GetLine( selected )
    local fpath = line.FilePath
    local isGame = line.IsGameFile

    local content
    if isGame then
      content = file.Read( fpath, "GAME" )
    else
      content = file.Read( fpath, "DATA" )
    end

    if content then
      EDITOR.SelectedMaterial.raw_vmt = content
      EDITOR.CurrentFilePath = fpath
      EDITOR.IsModified = false
      menu.sp.te:SetText( content )
      UpdateTitle()
      zdev.log( "S", "Loaded VMT: " .. fpath )
    else
      Derma_Message( "Failed to read file: " .. fpath, "Load Error" )
      zdev.log( "E", "Failed to load VMT: " .. fpath )
    end
  end

  -- Save button
  menu.fb.btnSave = vgui.Create( "DButton", menu.fb.actionPanel )
  menu.fb.btnSave:Dock( TOP )
  menu.fb.btnSave:SetTall( 28 )
  menu.fb.btnSave:SetText( "Save to Selected/New" )
  menu.fb.btnSave:SetIcon( "icon16/disk.png" )
  menu.fb.btnSave:DockMargin( 4, 2, 4, 4 )
  menu.fb.btnSave.DoClick = function()
    local content = menu.sp.te:GetText()
    if content == "" then
      Derma_Message( "Nothing to save - text editor is empty.", "Save VMT" )
      return
    end

    local selected = menu.fb.fileList:GetSelectedLine()
    local savePath

    if selected then
      local line = menu.fb.fileList:GetLine( selected )
      if line.IsGameFile then
        Derma_Message( "Cannot overwrite GAME files. Save to DATA directory.", "Save VMT" )
        return
      end
      savePath = line.FilePath
    else
      -- No selection, prompt for filename
      local dir = menu.fb.dirEntry:GetText()
      if dir == "" then dir = "zdev/mats" end

      Derma_StringRequest( "Save VMT", "Enter filename:", "new_material.vmt",
        function( fname )
          if not string.EndsWith( fname, ".vmt" ) then
            fname = fname .. ".vmt"
          end
          local fpath = dir .. "/" .. fname
          file.CreateDir( dir )
          file.Write( fpath, content )
          EDITOR.CurrentFilePath = fpath
          EDITOR.IsModified = false
          UpdateTitle()
          RefreshFileList()
          zdev.log( "S", "Saved VMT: " .. fpath )
          Derma_Message( "File saved: " .. fpath, "Save VMT" )
        end,
        function() end, "Save", "Cancel" )
      return
    end

    -- Save to selected file
    file.Write( savePath, content )
    EDITOR.CurrentFilePath = savePath
    EDITOR.IsModified = false
    UpdateTitle()
    zdev.log( "S", "Saved VMT: " .. savePath )
    Derma_Message( "File saved: " .. savePath, "Save VMT" )
  end

  -- Delete button
  menu.fb.btnDelete = vgui.Create( "DButton", menu.fb.actionPanel )
  menu.fb.btnDelete:Dock( TOP )
  menu.fb.btnDelete:SetTall( 26 )
  menu.fb.btnDelete:SetText( "Delete Selected" )
  menu.fb.btnDelete:SetIcon( "icon16/page_white_delete.png" )
  menu.fb.btnDelete:DockMargin( 4, 2, 4, 4 )
  menu.fb.btnDelete.DoClick = function()
    local selected = menu.fb.fileList:GetSelectedLine()
    if not selected then
      Derma_Message( "Please select a file to delete.", "Delete VMT" )
      return
    end

    local line = menu.fb.fileList:GetLine( selected )
    if line.IsGameFile then
      Derma_Message( "Cannot delete GAME files.", "Delete VMT" )
      return
    end

    local fpath = line.FilePath
    Derma_Query( "Are you sure you want to delete:\n" .. fpath .. "?", "Confirm Delete",
      "Yes", function()
        file.Delete( fpath )
        RefreshFileList()
        zdev.log( "W", "Deleted VMT: " .. fpath )

        -- Clear editor if we deleted the currently loaded file
        if EDITOR.CurrentFilePath == fpath then
          menu.sp.te:SetText( "" )
          EDITOR.SelectedMaterial.raw_vmt = ""
          EDITOR.CurrentFilePath = ""
          EDITOR.IsModified = false
          UpdateTitle()
        end
      end,
      "No", function() end )
  end

  -- Double-click to load file
  menu.fb.fileList.DoDoubleClick = function( self, lineID, line )
    menu.fb.btnLoad:DoClick()
  end

  -- Initial refresh
  timer.Simple( 0.1, RefreshFileList )

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    SCROLL PANEL BOTTOM
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.sp = vgui.Create( "DScrollPanel", menu )
  menu.sp:Dock( FILL )

  menu.sp.co = vgui.Create( "DComboBox", menu.sp )
  menu.sp.co:Dock( TOP )
  menu.sp.co:SetSize( 100,  20 )

  for j, shad in pairs( t_mat_shaders ) do
    menu.sp.co:AddChoice( shad.name )
  end

  menu.sp:AddItem( menu.sp.co)
  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PANELLIST:LEFT - PROPERTIES
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
  menu.sp.pr = vgui.Create( "DProperties", menu.sp )
  menu.sp.pr:Dock( TOP )
  menu.sp.pr:SetTall(menu_h/2)
  menu.sp.pr:DockMargin( 2, 2, 2, 32 )
  menu.sp.pr.rows = {}
  local tbl = t_mat_vars
  for k, v in pairs( tbl ) do
    local s_DataType = v.type
    local t_Setup = {}
    local s_Category = "Custom"
    local row  =  menu.sp.pr:CreateRow( s_Category, v.text )
    row:Setup( s_DataType, t_Setup )
    row:SetValue( v.default )
    row.DataChanged = function( self, data )
      if s_DataType == "Boolean" then
        data = tobool(data)
      elseif s_DataType == "Float" then
        data = tonumber(data) or 0
      elseif s_DataType == "Integer" then
        data = tonumber(data) or 0
      elseif s_DataType == "VectorColor" then
        -- Expecting data as string "[r g b]" or "r g b"
        local r, g, b = string.match(data, "%[?%s*(%d*%.?%d+)%s+(%d*%.?%d+)%s+(%d*%.?%d+)%s*%]?")
        r = tonumber(r) or 1
        g = tonumber(g) or 1
        b = tonumber(b) or 1
        data = Vector(r, g, b)
      end
    end
    menu.sp.pr.rows[ v.text ] = row
  end
  menu.sp:AddItem( menu.sp.pr)

  -- VMT Content Editor label
  menu.sp.teLabel = vgui.Create( "DLabel", menu.sp )
  menu.sp.teLabel:Dock( TOP )
  menu.sp.teLabel:SetText( "VMT Content Editor - Edit .vmt file content below:" )
  menu.sp.teLabel:SetFont( "DermaDefaultBold" )
  menu.sp.teLabel:SetTextColor( Color(200, 220, 255) )
  menu.sp.teLabel:DockMargin( 4, 8, 4, 4 )
  menu.sp:AddItem( menu.sp.teLabel )

  -- Create multiline text editor for VMT content
  menu.sp.te = ZDEV.VGUI.CreateTextEntry( menu.sp, menu_w, menu_h/2, "", "BudgetLabel", true, TOP, 0, 0, 0, 32 )
  menu.sp.te:SetTextColor( Color(255,255,255,255) )
  menu.sp.te:SetUpdateOnType( false )
  menu.sp.te:SetMultiline( true )
  menu.sp.te:SetVerticalScrollbarEnabled( true )

  -- Track changes in the text editor
  menu.sp.te.OnTextChanged = function(self)
    EDITOR.IsModified = true
    UpdateTitle()
  end

  menu.sp.te.OnEnter = function( self, text )
    -- Parse the VMT text and update material data
    local mat_text = self:GetText()
    EDITOR.SelectedMaterial.raw_vmt = mat_text

    -- Try to parse and update material preview
    if EDITOR.SelectedMaterial.file ~= "" then
      local mat_path = EDITOR.SelectedMaterial.file
      local ok, mat = pcall(Material, mat_path)
      if ok and mat and not mat:IsError() then
        local kv_ok, kv = pcall(function() return mat:GetKeyValues() end)
        if kv_ok and kv then
          EDITOR.SelectedMaterial.data = kv
        end
      end
    end
  end

  menu.sp:AddItem( menu.sp.te)
  
--[[
  for k, var in pairs( t_mat_vars ) do
    local cb = vgui.Create( "DCheckBoxLabel", menu.sp )
    cb:SetFont( "BudgetLabel" )
    cb:SetValue( false )
    cb:SetTextColor( Color(200,200,200,255) )
    cb:SetIndent( 1 )
    cb:SetText( var.text )
    cb:Dock( TOP )
    menu.sp:AddItem(cb)
  end
]]
-- Fix the typo: mmenu should be menu
menu.pnl.nt.OnNodeSelected = function(self, node)
  local path = node:GetPathID()
  local folder = node:GetFolder()
  local text = node:GetText()
  local file_noext = string.StripExtension(text)
  local file_ext = string.GetExtensionFromFilename(text) or ""
  local parent = node:GetParentNode()
  local parent_text = parent and parent:GetText() or ""

  local material_file = parent_text .. "/" .. file_noext
  if file_ext and string.find(file_ext, "png", 1, true) then
    material_file = parent_text .. "/" .. text  -- Keep extension for .png
  end

  zdev.log("I", "Selected file: " .. material_file .. " (ext: " .. file_ext .. ")")

  EDITOR.SelectedMaterial.file = material_file

  if string.lower(file_ext) == "png" then
    -- Handle .png with DHTML for direct image viewing
    local url = "asset:--" .. material_file
    menu.pnl.im2:SetVisible(true)
    menu.pnl.im2:OpenURL(url)
    menu.pnl.im:SetImage("")  -- Clear DImage
    menu.pnl.im.te:SetText(material_file)
    menu.sp.te:SetText("-- PNG file: Direct image view via DHTML --")
    EDITOR.SelectedMaterial.data = {}  -- No keyvalues for .png
    EDITOR.SelectedMaterial.raw_vmt = ""
    EDITOR.CurrentFilePath = ""
    EDITOR.IsModified = false
    UpdateTitle()
  elseif string.lower(file_ext) == "vmt" then
    -- Handle .vmt files - load raw VMT content
    menu.pnl.im2:SetVisible(false)

    -- Try to load the raw VMT file
    local vmt_path = "materials/" .. parent_text .. "/" .. text
    local vmt_content = file.Read(vmt_path, "GAME")
    if not vmt_content then
      vmt_content = file.Read(vmt_path, "DATA")
    end

    if vmt_content then
      -- Successfully loaded VMT file
      EDITOR.SelectedMaterial.raw_vmt = vmt_content
      EDITOR.CurrentFilePath = vmt_path
      EDITOR.IsModified = false

      -- Load material for preview
      local mat = Material(material_file)
      if mat and not mat:IsError() then
        menu.pnl.im:SetImage(material_file)
        menu.pnl.im.te:SetText(material_file)
        local kv = mat:GetKeyValues()
        EDITOR.SelectedMaterial.data = kv or {}
      else
        menu.pnl.im:SetImage("icon16/error.png")
        menu.pnl.im.te:SetText(material_file)
        EDITOR.SelectedMaterial.data = {}
      end

      -- Display raw VMT content in text editor
      menu.sp.te:SetText(vmt_content)
      UpdateTitle()
      zdev.log("S", "Loaded VMT file: " .. vmt_path)
    else
      -- Failed to load VMT file, try to get keyvalues from Material
      local mat = Material(material_file)
      if mat and not mat:IsError() then
        menu.pnl.im:SetImage(material_file)
        menu.pnl.im.te:SetText(material_file)
        local kv = mat:GetKeyValues()
        EDITOR.SelectedMaterial.data = kv or {}
        menu.sp.te:SetText(util.TableToKeyValues(EDITOR.SelectedMaterial.data))
        EDITOR.SelectedMaterial.raw_vmt = util.TableToKeyValues(EDITOR.SelectedMaterial.data)
      else
        menu.pnl.im:SetImage("icon16/error.png")
        menu.pnl.im.te:SetText(material_file)
        menu.sp.te:SetText("-- Failed to load VMT file: " .. vmt_path .. " --")
        EDITOR.SelectedMaterial.data = {}
        EDITOR.SelectedMaterial.raw_vmt = ""
      end
      EDITOR.CurrentFilePath = ""
      EDITOR.IsModified = false
      UpdateTitle()
      zdev.log("W", "Could not load VMT file from disk: " .. vmt_path)
    end
  elseif string.lower(file_ext) == "vtf" then
    -- Handle .vtf files - texture files
    menu.pnl.im2:SetVisible(false)
    local mat = Material(material_file)
    if mat and not mat:IsError() then
      menu.pnl.im:SetImage(material_file)
      menu.pnl.im.te:SetText(material_file)
      menu.sp.te:SetText("-- VTF texture file: " .. material_file .. " --\n-- This is a texture file, not a material definition --")
      EDITOR.SelectedMaterial.data = {}
      EDITOR.SelectedMaterial.raw_vmt = ""
    else
      menu.pnl.im:SetImage("icon16/error.png")
      menu.pnl.im.te:SetText(material_file)
      menu.sp.te:SetText("-- Failed to load VTF: " .. material_file .. " --")
      EDITOR.SelectedMaterial.data = {}
      EDITOR.SelectedMaterial.raw_vmt = ""
    end
    EDITOR.CurrentFilePath = ""
    EDITOR.IsModified = false
    UpdateTitle()
  else
    -- Handle other material types (no extension or unknown)
    menu.pnl.im2:SetVisible(false)
    local mat = Material(material_file)
    if mat and not mat:IsError() then
      menu.pnl.im:SetImage(material_file)
      menu.pnl.im.te:SetText(material_file)
      local kv = mat:GetKeyValues()
      EDITOR.SelectedMaterial.data = kv or {}
      menu.sp.te:SetText(util.TableToKeyValues(EDITOR.SelectedMaterial.data))
      EDITOR.SelectedMaterial.raw_vmt = util.TableToKeyValues(EDITOR.SelectedMaterial.data)
    else
      menu.pnl.im:SetImage("icon16/error.png")
      menu.pnl.im.te:SetText(material_file)
      menu.sp.te:SetText("-- Failed to load material: " .. material_file .. " --")
      EDITOR.SelectedMaterial.data = {}
      EDITOR.SelectedMaterial.raw_vmt = ""
      zdev.log("E", "Could not load material for " .. material_file)
    end
    EDITOR.CurrentFilePath = ""
    EDITOR.IsModified = false
    UpdateTitle()
  end
end

end -- Close the function

concommand.Add( "zd_menu_dev_mat", ZDEV.VGUI.Editor_Materials )

ZDEV.VGUI.AddToMainMenu( "zd_menu_dev_mat" )

ZDEV.FILE.SetLoaded( _f )



