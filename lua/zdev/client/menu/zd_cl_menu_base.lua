--[[
    ZDEV Menu Base Panel
    Provides a consistent layout and style for all ZDEV Derma menus.
    Author: Copilot Optimization
    Context: Client
]]

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() * 0.4, ScrH() * 0.5)
    self:Center()
    self:SetTitle("ZDEV Menu")
    self:MakePopup()
    self:SetDraggable(true)
    self:ShowCloseButton(true)

    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(48)
    self.Header.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 40, 255))
    draw.SimpleText(self.MenuTitle or "ZDEV Menu", "DermaLarge", 16, h / 2, Color(200, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content:DockMargin(8, 8, 8, 8)
    self.Content.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 45, 60, 220))
    end
end

function PANEL:SetMenuTitle(title)
    self.MenuTitle = title
    if self.Header then self.Header:InvalidateLayout(true) end
end

function PANEL:AddToContent(panel)
    panel:SetParent(self.Content)
    panel:Dock(TOP)
    panel:DockMargin(0, 0, 0, 8)
end

vgui.Register("ZDEVMenuBase", PANEL, "DFrame")
