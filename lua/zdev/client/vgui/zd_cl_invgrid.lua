-- ZDEV_UID: ZDEV_FUNC_INV_GRID01 | Path: ZDEV.VGUI.InvGrid
local _f = 'zdev/client/vgui/zd_cl_invgrid.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_InvGrid - Inventory Grid Container
    Manages a 2D grid of ZD_InvSlot panels and handles item placement/collision.
    Use SetGridSize(cols, rows) to define the grid dimensions.
    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_iCols", "Cols")
AccessorFunc(PANEL, "m_iRows", "Rows")
AccessorFunc(PANEL, "m_sSlotType", "DefaultSlotType")

local SLOT_SIZE = 48
local SLOT_PAD  = 2

function PANEL:Init()
    self.m_iCols = 8
    self.m_iRows = 4
    self.m_sSlotType = "generic"
    self.m_tGrid = {}     -- 2D table of ZD_InvSlot panels [col][row]
    self.m_tItems = {}    -- List of ZD_InvItem panels in this grid
end

--- Build or rebuild the grid with the given dimensions
function PANEL:SetGridSize(cols, rows)
    self.m_iCols = cols
    self.m_iRows = rows
    self:BuildGrid()
end

--- Create all slot panels for the grid
function PANEL:BuildGrid()
    -- Clear existing slots
    for col, rowTbl in pairs(self.m_tGrid) do
        for row, slot in pairs(rowTbl) do
            if IsValid(slot) then slot:Remove() end
        end
    end
    self.m_tGrid = {}

    -- Remove existing item panels
    for _, itemPnl in ipairs(self.m_tItems) do
        if IsValid(itemPnl) then itemPnl:Remove() end
    end
    self.m_tItems = {}

    local cols = self.m_iCols
    local rows = self.m_iRows

    -- Size the container to fit the grid
    local gridW = cols * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD
    local gridH = rows * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD
    self:SetSize(gridW, gridH)

    -- Create slot panels
    for col = 1, cols do
        self.m_tGrid[col] = {}
        for row = 1, rows do
            local slot = vgui.Create("ZD_InvSlot", self)
            slot:SetSize(SLOT_SIZE, SLOT_SIZE)
            slot:SetCoords(col, row)
            slot:SetSlotType(self.m_sSlotType)

            local posX = SLOT_PAD + (col - 1) * (SLOT_SIZE + SLOT_PAD)
            local posY = SLOT_PAD + (row - 1) * (SLOT_SIZE + SLOT_PAD)
            slot:SetPos(posX, posY)

            self.m_tGrid[col][row] = slot
        end
    end
end

--- Get the slot at grid coordinates (col, row)
function PANEL:GetSlot(col, row)
    if self.m_tGrid[col] then
        return self.m_tGrid[col][row]
    end
    return nil
end

--- Check if an item of size (w, h) can fit at position (col, row)
--- Optionally ignores a specific item panel (for re-placing the same item)
function PANEL:CanFitItem(col, row, w, h, ignorePanel)
    for c = col, col + w - 1 do
        for r = row, row + h - 1 do
            local slot = self:GetSlot(c, r)
            if not slot then return false end -- Out of bounds
            local existing = slot:GetItemPanel()
            if existing and existing ~= ignorePanel then
                return false -- Slot is occupied by a different item
            end
        end
    end
    return true
end

--- Place an item panel at position (col, row) spanning (w, h) cells
function PANEL:PlaceItem(col, row, w, h, itemPanel)
    -- First, clear the item from its old position if it was already placed
    self:RemoveItemPanel(itemPanel)

    -- Mark all covered slots as occupied
    for c = col, col + w - 1 do
        for r = row, row + h - 1 do
            local slot = self:GetSlot(c, r)
            if slot then
                slot:SetItemPanel(itemPanel)
                slot.m_iVisualState = 2 -- STATE_OCCUPIED
            end
        end
    end

    -- Snap the item panel to the root slot
    local rootSlot = self:GetSlot(col, row)
    if rootSlot and IsValid(itemPanel) then
        itemPanel:SetParent(self)
        itemPanel:SnapToSlot(rootSlot)
        itemPanel:SetRootSlot(rootSlot)
        itemPanel:SetZPos(10) -- Render above slots
    end

    -- Track the item
    if not table.HasValue(self.m_tItems, itemPanel) then
        table.insert(self.m_tItems, itemPanel)
    end
end

--- Remove an item panel from the grid, clearing all slots it occupied
function PANEL:RemoveItemPanel(itemPanel)
    if not IsValid(itemPanel) then return end

    for col, rowTbl in pairs(self.m_tGrid) do
        for row, slot in pairs(rowTbl) do
            if slot:GetItemPanel() == itemPanel then
                slot:ClearItem()
            end
        end
    end

    -- Remove from tracking list
    for i, pnl in ipairs(self.m_tItems) do
        if pnl == itemPanel then
            table.remove(self.m_tItems, i)
            break
        end
    end
end

--- Auto-place: find the first available position for an item
function PANEL:FindRoomFor(item)
    local w, h = 1, 1
    if item and item.GetSize then
        w, h = item:GetSize()
    end

    for row = 1, self.m_iRows do
        for col = 1, self.m_iCols do
            if self:CanFitItem(col, row, w, h) then
                return col, row
            end
        end
    end

    return nil, nil -- No room
end

--- Create and auto-place a new item in the grid
--- Returns the ZD_InvItem panel, or nil if no room
function PANEL:AddItem(item)
    local w, h = 1, 1
    if item and item.GetSize then
        w, h = item:GetSize()
    end

    local col, row = self:FindRoomFor(item)
    if not col then return nil end

    local itemPanel = vgui.Create("ZD_InvItem", self)
    itemPanel:SetItemData(item)
    self:PlaceItem(col, row, w, h, itemPanel)

    return itemPanel
end

function PANEL:Paint(w, h)
    -- Grid background
    draw.RoundedBox(4, 0, 0, w, h, Color(30, 35, 45, 240))
    return true
end

derma.DefineControl("ZD_InvGrid", "ZDEV Inventory Grid Container", PANEL, "DPanel")
ZDEV.FILE.SetLoaded( _f )
