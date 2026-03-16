-- ZDEV_UID: ZDEV_FUNC_INV_ITEM01 | Path: ZDEV.VGUI.InvItem
local _f = 'zdev/client/vgui/zd_cl_invitem.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_InvItem - Draggable Inventory Item Panel
    Represents a physical item in the inventory. Made draggable via Droppable().
    Renders the item's icon material and can span multiple grid cells.
    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_Item", "Item")
AccessorFunc(PANEL, "m_RootSlot", "RootSlot")

local SLOT_SIZE = 48

function PANEL:Init()
    self:SetSize(SLOT_SIZE, SLOT_SIZE)
    self:SetMouseInputEnabled(true)
    self:SetItem(false)
    self:SetRootSlot(false)

    -- Make this panel draggable under the "zd_invitem" identifier
    self:Droppable("zd_invitem")
end

--- Set the item and resize the panel to match item dimensions
function PANEL:SetItemData(item)
    self:SetItem(item)
    if item and item.GetSize then
        local w, h = item:GetSize()
        self:SetSize(w * SLOT_SIZE, h * SLOT_SIZE)
    end
end

--- Snap this item panel to a slot's position
function PANEL:SnapToSlot(slot)
    if not IsValid(slot) then return end
    self:SetRootSlot(slot)
    local sx, sy = slot:LocalToScreen(0, 0)
    local px, py = self:GetParent():ScreenToLocal(sx, sy)
    self:SetPos(px, py)
end

--- Called when the item is right-clicked (context menu)
function PANEL:OnMousePressed(mc)
    if mc == MOUSE_RIGHT then
        self:OpenContextMenu()
        return
    end
    -- Let base handle left-click for drag
    DPanel.OnMousePressed(self, mc)
end

function PANEL:OpenContextMenu()
    local item = self:GetItem()
    if not item then return end

    local menu = DermaMenu()

    menu:AddOption("Inspect", function()
        if item.GetName then
            chat.AddText(Color(100, 200, 255), "[Inventory] ", color_white, tostring(item:GetName()))
        end
    end):SetIcon("icon16/magnifier.png")

    menu:AddOption("Drop", function()
        self:DropFromInventory()
    end):SetIcon("icon16/arrow_down.png")

    menu:Open()
end

--- Remove this item from its current grid and clean up
function PANEL:DropFromInventory()
    local gridParent = self:GetParent()
    if gridParent and gridParent.RemoveItemPanel then
        gridParent:RemoveItemPanel(self)
    end
    self:Remove()
end

function PANEL:Paint(w, h)
    -- Item background
    surface.SetDrawColor(70, 75, 90, 200)
    surface.DrawRect(0, 0, w, h)

    -- Subtle border
    surface.SetDrawColor(100, 100, 120, 180)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    return true
end

function PANEL:PaintOver(w, h)
    local item = self:GetItem()
    if not item then return end

    -- Draw item icon if available
    if item.GetIcon then
        local mat = item:GetIcon()
        if mat then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(2, 2, w - 4, h - 4)
        end
    end

    -- Draw item name at bottom
    if item.GetName then
        local name = item:GetName()
        if name and name ~= "" then
            draw.SimpleText(name, "DermaDefault", w / 2, h - 2, Color(220, 220, 220, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
end

derma.DefineControl("ZD_InvItem", "ZDEV Draggable Inventory Item", PANEL, "DPanel")
ZDEV.FILE.SetLoaded( _f )
