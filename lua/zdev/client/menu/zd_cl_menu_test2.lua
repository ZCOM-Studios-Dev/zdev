local _f = 'zdev/client/vgui/menu_test.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
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

-- ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

function ZDEV.VGUI.TestMenu( )
    local dframe_292 = vgui.Create("DFrame")
    dframe_292:SetSize(600, 400)
    dframe_292:SetPos(290, 120)
    dframe_292:MakePopup()
    dframe_292:SetTitle("My Window")
    dframe_292.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(38, 38, 38, 255))
        else
            draw.RoundedBox(0, 0, 0, w, h, Color(38, 38, 38, 255))
        end
        -- Title Bar
        draw.RoundedBoxEx(0, 0, 0, w, 24, Color(35, 57, 77, 255), true, true, false, false)
    end

    local dpanel_203 = vgui.Create("DPanel", dframe_292)
    dpanel_203:SetSize(200, 200)
    dpanel_203:SetPos(5, 30)
    dpanel_203.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 41, 52, 255))
        else
            draw.RoundedBox(6, 0, 0, w, h, Color(30, 41, 52, 255))
        end
        if self:IsHovered() then
            surface.SetDrawColor(122, 122, 122)
        else
            surface.SetDrawColor(122, 122, 122)
        end
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local dpanel_203_copy = vgui.Create("DPanel", dframe_292)
    dpanel_203_copy:SetSize(590, 20)
    dpanel_203_copy:SetPos(5, 5)
    dpanel_203_copy.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(53, 104, 151, 255))
        else
            draw.RoundedBox(0, 0, 0, w, h, Color(61, 61, 61, 255))
        end
    end

    local dtextentry_193 = vgui.Create("DTextEntry", dpanel_203_copy)
    dtextentry_193:SetSize(120, 16)
    dtextentry_193:SetPos(2, 2)
    dtextentry_193:SetText("Current File")
    dtextentry_193:SetFont("BudgetLabel")
    dtextentry_193.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(144, 144, 144, 255))
        else
            draw.RoundedBox(0, 0, 0, w, h, Color(117, 117, 117, 255))
        end
    end

    local dbutton_139 = vgui.Create("DButton", dpanel_203_copy)
    dbutton_139:SetSize(60, 16)
    dbutton_139:SetPos(124, 2)
    dbutton_139:SetText("Open")

    local dtree_333 = vgui.Create("DTree", dframe_292)
    dtree_333:SetSize(205, 200)
    dtree_333:SetPos(390, 30)

    local dform_810 = vgui.Create("DForm", dframe_292)
    dform_810:SetSize(175, 195)
    dform_810:SetPos(210, 30)

    local dcolorpalette_283 = vgui.Create("DColorPalette", dframe_292)
    dcolorpalette_283:SetSize(135, 140)
    dcolorpalette_283:SetPos(5, 235)

    local dtab_865 = vgui.Create("DTab", dframe_292)
    dtab_865:SetSize(450, 140)
    dtab_865:SetPos(145, 235)

	return dframe_292
end
concommand.Add( "zd_menu_test2", ZDEV.VGUI.TestMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_test2" )
