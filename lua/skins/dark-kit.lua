--[[
    Dark Kit Derma Skin
    A modular, config-based skin emulating modern dark UI kits.
    
    Reference Style: Dark, Flat, Clean Lines, Subtle Rounding.
]]


local surface = surface
local draw = draw
local Color = Color


-- 1. Configuration & Palette
-- Modify these values to tweak the skin without touching logic.
local CFG = {
    Name = "DarkKit",
    Author = "AI Assistant",
    
    -- Dimensions
    CornerRadius = 4, -- Rounding for frames and buttons
    BorderWidth = 1,
    
    -- Fonts (You can create custom fonts using surface.CreateFont)
    Font = {
        Main = "DermaDefault",
        Title = "DermaDefaultBold",
    },


    -- Color Palette (Dark Theme)
    Colors = {
        -- Main Backgrounds
        FrameBG     = Color(40, 40, 45, 250),
        FrameHeader = Color(30, 30, 35, 255),
        PanelBG     = Color(50, 50, 55, 255),
        
        -- Interactions
        Primary     = Color(0, 122, 204, 255), -- The "Blue" accent common in dark kits
        Hover       = Color(60, 60, 65, 255),
        Click       = Color(20, 20, 25, 255),
        Disabled    = Color(35, 35, 40, 255),
        
        -- Text
        TextNormal  = Color(220, 220, 220, 255),
        TextDim     = Color(150, 150, 150, 255),
        TextHeader  = Color(255, 255, 255, 255),
        
        -- Inputs/Lists
        InputBG     = Color(30, 30, 35, 255),
        InputBorder = Color(60, 60, 65, 255),
        
        -- Scrollbars
        ScrollTrack = Color(30, 30, 35, 255),
        ScrollGrip  = Color(70, 70, 75, 255)
    }
}


-- 2. Skin Table Definition
local SKIN = {}


SKIN.PrintName      = CFG.Name
SKIN.Author         = CFG.Author
SKIN.DermaVersion   = 1
SKIN.GwenTexture    = Material("gwenskin/GModDefault.png") -- Fallback for unskinned elements


-- Map configuration colors to Skin variables required by some native panels
SKIN.bg_color       = CFG.Colors.FrameBG
SKIN.bg_color_sleep = CFG.Colors.Disabled
SKIN.fontFrame      = CFG.Font.Title
SKIN.control_color  = CFG.Colors.PanelBG
SKIN.colPropertySheet = CFG.Colors.PanelBG 
SKIN.colTab           = CFG.Colors.PanelBG
SKIN.colTabInactive   = CFG.Colors.Disabled
SKIN.colTabShadow     = Color(0, 0, 0, 0) -- No shadow
SKIN.colTabText       = CFG.Colors.TextNormal
SKIN.colTabTextInactive = CFG.Colors.TextDim


-- Helper function for rounded boxes
local function DrawRounded(radius, x, y, w, h, col)
    draw.RoundedBox(radius, x, y, w, h, col)
end


--[[---------------------------------------------------------
    Frame / Window
-----------------------------------------------------------]]
function SKIN:PaintFrame(panel, w, h)
    -- Main Body
    DrawRounded(CFG.CornerRadius, 0, 0, w, h, CFG.Colors.FrameBG)
    
    -- Header
    surface.SetDrawColor(CFG.Colors.FrameHeader)
    -- Draw rect for header, top corners rounded only (simulated by drawing over bottom)
    draw.RoundedBoxEx(CFG.CornerRadius, 0, 0, w, 24, CFG.Colors.FrameHeader, true, true, false, false)
    
    -- Subtle Border
    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawOutlinedRect(0, 0, w, h)
end


--[[---------------------------------------------------------
    Button
-----------------------------------------------------------]]
function SKIN:PaintButton(panel, w, h)
    if (not panel.m_bBackground) then return end


    local col = CFG.Colors.PanelBG


    if (panel:GetDisabled()) then
        col = CFG.Colors.Disabled
    elseif (panel.Depressed or panel:IsSelected() or panel:GetToggle()) then
        col = CFG.Colors.Primary -- Active state uses accent color
    elseif (panel.Hovered) then
        col = CFG.Colors.Hover
    end


    DrawRounded(CFG.CornerRadius, 0, 0, w, h, col)


    -- Subtle border
    if (panel.Hovered and not panel.Depressed) then
        surface.SetDrawColor(CFG.Colors.Primary)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
end


--[[---------------------------------------------------------
    Text Entry (Input Fields)
-----------------------------------------------------------]]
function SKIN:PaintTextEntry(panel, w, h)
    if (panel.m_bBackground) then
        if (panel:GetDisabled()) then
            DrawRounded(CFG.CornerRadius, 0, 0, w, h, CFG.Colors.Disabled)
        else
            DrawRounded(CFG.CornerRadius, 0, 0, w, h, CFG.Colors.InputBG)
            -- Border
            surface.SetDrawColor(CFG.Colors.InputBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end
    
    -- Use the built-in text drawing to handle highlighting/cursor
    panel:DrawTextEntryText(CFG.Colors.TextNormal, CFG.Colors.Primary, CFG.Colors.TextNormal)
end


--[[---------------------------------------------------------
    Scrollbar
-----------------------------------------------------------]]
function SKIN:PaintVScrollBar(panel, w, h)
    surface.SetDrawColor(CFG.Colors.ScrollTrack)
    surface.DrawRect(0, 0, w, h)
end


function SKIN:PaintScrollBarGrip(panel, w, h)
    local col = CFG.Colors.ScrollGrip
    if (panel.Hovered) then col = CFG.Colors.Primary end
    if (panel.Depressed) then col = Color(CFG.Colors.Primary.r * 0.8, CFG.Colors.Primary.g * 0.8, CFG.Colors.Primary.b * 0.8) end


    DrawRounded(CFG.CornerRadius, 2, 0, w - 4, h, col)
end


-- Disable buttons on scrollbar (modern look usually hides them)
function SKIN:PaintButtonDown(panel, w, h) return end
function SKIN:PaintButtonUp(panel, w, h) return end


--[[---------------------------------------------------------
    Property Sheet (Tabs)
-----------------------------------------------------------]]
function SKIN:PaintPropertySheet(panel, w, h)
    -- Background of the content area
    local activeTab = panel:GetActiveTab()
    local offset = 0
    if (activeTab) then offset = activeTab:GetTall() - 8 end
    
    DrawRounded(CFG.CornerRadius, 0, offset, w, h - offset, CFG.Colors.PanelBG)
end


function SKIN:PaintTab(panel, w, h)
    if (panel:GetPropertySheet():GetActiveTab() == panel) then
        return self:PaintActiveTab(panel, w, h)
    end
    
    -- Inactive Tab
    DrawRounded(CFG.CornerRadius, 4, 0, w - 8, h - 8, CFG.Colors.Disabled)
end


function SKIN:PaintActiveTab(panel, w, h)
    -- Active Tab
    DrawRounded(CFG.CornerRadius, 0, 0, w, h, CFG.Colors.PanelBG)
    
    -- Accent line at top
    surface.SetDrawColor(CFG.Colors.Primary)
    surface.DrawRect(2, 0, w - 4, 3)
end


--[[---------------------------------------------------------
    DTree / ListViewd
-----------------------------------------------------------]]
function SKIN:PaintTree(panel, w, h)
    if (not panel.m_bBackground) then return end
    DrawRounded(CFG.CornerRadius, 0, 0, w, h, CFG.Colors.InputBG)
end


function SKIN:PaintTreeNode(panel, w, h)
    if (not panel.m_bDrawLines) then return end
    surface.SetDrawColor(CFG.Colors.InputBorder)
    -- Custom line drawing logic could go here
end


function SKIN:PaintSelection(panel, w, h)
    surface.SetDrawColor(CFG.Colors.Primary)
    surface.DrawRect(0, 0, w, h)
end


--[[---------------------------------------------------------
    Register Skin
-----------------------------------------------------------]]
derma.DefineSkin(CFG.Name, "A customized dark theme", SKIN)


-- Optional: Automatically refresh skins to see changes immediately during dev
derma.RefreshSkins()
