local _f = 'zdev/client/vgui/zd_cl_invgrid.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_InvGrid - Inventory Grid Container (single-panel rewrite)
    Owns the 2D occupancy table, renders slots + items directly in Paint,
    and drives drag-and-drop via ZDEV.VGUI.DragState. No child panels.
    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_iCols", "Cols")
AccessorFunc(PANEL, "m_iRows", "Rows")
AccessorFunc(PANEL, "m_sSlotType", "DefaultSlotType")

local SLOT_SIZE   = 48
local SLOT_PAD    = 2
local HOVER_DELAY = 0.20

local MAT_SLOT = {
    base  = Material("ui/ui_slot.png"),
    hover = Material("ui/ui_slot_hover.png"),
}

local function newID(self)
    self._nextID = (self._nextID or 0) + 1
    return self._nextID
end

function PANEL:Init()
    self.m_iCols       = 8
    self.m_iRows       = 4
    self.m_sSlotType   = "generic"
    self.m_tCells      = {}
    self.m_tEntries    = {}
    self.m_iHoverEntry = nil
    self.m_iHoverCell  = nil
    self.m_iSelected   = nil
    self.m_flHoverTime = 0
    self:SetMouseInputEnabled(true)
    self:Resize()
end

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

function PANEL:Resize()
    local w = self.m_iCols * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD
    local h = self.m_iRows * (SLOT_SIZE + SLOT_PAD) + SLOT_PAD
    self:SetSize(w, h)
end

function PANEL:SetGridSize(cols, rows)
    self.m_iCols = cols
    self.m_iRows = rows
    self.m_tCells = {}
    self.m_tEntries = {}
    self.m_iHoverEntry = nil
    self.m_iHoverCell  = nil
    self.m_iSelected   = nil
    for c = 1, cols do self.m_tCells[c] = {} end
    self:Resize()
end

function PANEL:CellToPos(col, row)
    local x = SLOT_PAD + (col - 1) * (SLOT_SIZE + SLOT_PAD)
    local y = SLOT_PAD + (row - 1) * (SLOT_SIZE + SLOT_PAD)
    return x, y
end

function PANEL:PosToCell(x, y)
    local col = math.floor((x - SLOT_PAD) / (SLOT_SIZE + SLOT_PAD)) + 1
    local row = math.floor((y - SLOT_PAD) / (SLOT_SIZE + SLOT_PAD)) + 1
    if col < 1 or col > self.m_iCols then return nil, nil end
    if row < 1 or row > self.m_iRows then return nil, nil end
    return col, row
end

---------------------------------------------------------------------------
-- Occupancy
---------------------------------------------------------------------------

function PANEL:CanFitItem(col, row, w, h, ignoreID)
    for c = col, col + w - 1 do
        for r = row, row + h - 1 do
            if c < 1 or c > self.m_iCols or r < 1 or r > self.m_iRows then return false end
            local cellID = self.m_tCells[c] and self.m_tCells[c][r] or 0
            if cellID ~= 0 and cellID ~= ignoreID then return false end
        end
    end
    return true
end

function PANEL:FindRoomFor(item)
    local w, h = 1, 1
    if item and item.GetSize then w, h = item:GetSize() end
    for row = 1, self.m_iRows do
        for col = 1, self.m_iCols do
            if self:CanFitItem(col, row, w, h) then return col, row end
        end
    end
    return nil, nil
end

function PANEL:PlaceItem(col, row, w, h, item)
    local id = newID(self)
    self.m_tEntries[id] = { item = item, col = col, row = row, w = w, h = h }
    for c = col, col + w - 1 do
        for r = row, row + h - 1 do
            self.m_tCells[c] = self.m_tCells[c] or {}
            self.m_tCells[c][r] = id
        end
    end
    return id
end

function PANEL:RemoveEntry(id)
    local e = self.m_tEntries[id]
    if not e then return end
    for c = e.col, e.col + e.w - 1 do
        for r = e.row, e.row + e.h - 1 do
            if self.m_tCells[c] then self.m_tCells[c][r] = 0 end
        end
    end
    self.m_tEntries[id] = nil
    if self.m_iHoverEntry == id then self.m_iHoverEntry = nil end
    if self.m_iSelected   == id then self.m_iSelected   = nil end
end

function PANEL:AddItem(item)
    if not item then return nil end
    local w, h = 1, 1
    if item.GetSize then w, h = item:GetSize() end
    local col, row = self:FindRoomFor(item)
    if not col then return nil end
    return self:PlaceItem(col, row, w, h, item)
end

function PANEL:RemoveItem(itemOrID)
    if type(itemOrID) == "number" then
        return self:RemoveEntry(itemOrID)
    end
    for id, e in pairs(self.m_tEntries) do
        if e.item == itemOrID then return self:RemoveEntry(id) end
    end
end

function PANEL:GetItems()
    local t = {}
    for _, e in pairs(self.m_tEntries) do table.insert(t, e.item) end
    return t
end

function PANEL:EntryAt(col, row)
    if col and row and self.m_tCells[col] then
        local id = self.m_tCells[col][row]
        if id and id ~= 0 then return id end
    end
    return nil
end

---------------------------------------------------------------------------
-- Mouse handling
---------------------------------------------------------------------------

function PANEL:OnCursorEntered()
    self.m_flHoverTime = SysTime()
end

function PANEL:OnCursorExited()
    self.m_iHoverCell  = nil
    self.m_iHoverEntry = nil
    if ZDEV.VGUI and ZDEV.VGUI.Tooltip then ZDEV.VGUI.Tooltip:Hide() end
end

function PANEL:Think()
    if not self:IsHovered() then return end
    local mx, my = self:LocalCursorPos()
    local c, r = self:PosToCell(mx, my)
    self.m_iHoverCell = (c and r) and { c, r } or nil
    local id = self:EntryAt(c, r)

    if id ~= self.m_iHoverEntry then
        self.m_iHoverEntry = id
        self.m_flHoverTime = SysTime()
        if ZDEV.VGUI and ZDEV.VGUI.Tooltip then ZDEV.VGUI.Tooltip:Hide() end
    end

    if id and (SysTime() - self.m_flHoverTime > HOVER_DELAY) then
        local e = self.m_tEntries[id]
        if e and e.item and ZDEV.VGUI and ZDEV.VGUI.Tooltip then
            local sx, sy = gui.MousePos()
            ZDEV.VGUI.Tooltip:Show(e.item, sx, sy)
        end
    end
end

function PANEL:OnMousePressed(mc)
    local mx, my = self:LocalCursorPos()
    local c, r = self:PosToCell(mx, my)
    local id = self:EntryAt(c, r)

    if mc == MOUSE_LEFT and id then
        local e = self.m_tEntries[id]
        self.m_iSelected = id
        if ZDEV.VGUI and ZDEV.VGUI.Tooltip then ZDEV.VGUI.Tooltip:Hide() end

        -- Double-click detection: same entry, second click within 0.3s → equip directly
        local now = SysTime()
        if self.m_iLastClickID == id
                and self.m_flLastClickTime
                and (now - self.m_flLastClickTime) < 0.3 then
            self.m_iLastClickID   = nil
            self.m_flLastClickTime = nil
            if e.item and e.item.IsEquippable and e.item:IsEquippable()
                    and ZDEV.VGUI.RequestEquipItem then
                ZDEV.VGUI.RequestEquipItem(e.item)
                return
            end
        end
        self.m_iLastClickID    = id
        self.m_flLastClickTime = now

        local cellW = e.w * SLOT_SIZE + (e.w - 1) * SLOT_PAD
        local cellH = e.h * SLOT_SIZE + (e.h - 1) * SLOT_PAD
        ZDEV.VGUI.DragState:Begin(self, id, e.item, cellW, cellH)
    elseif mc == MOUSE_RIGHT and id then
        self:OpenContextMenu(id)
    end
end

function PANEL:OnMouseReleased(mc)
    if mc ~= MOUSE_LEFT then return end
    local DS = ZDEV.VGUI.DragState
    if not DS.active then return end

    local mx, my = self:LocalCursorPos()
    local c, r = self:PosToCell(mx, my)
    local item = DS.item
    local iw, ih = 1, 1
    if item and item.GetSize then iw, ih = item:GetSize() end

    if not c or not r then
        DS:End()
        return
    end

    if DS.sourceGrid == self then
        if self:CanFitItem(c, r, iw, ih, DS.entryID) then
            if ZDEV.ClientInventory and ZDEV.ClientInventory.RequestMove then
                ZDEV.ClientInventory:RequestMove(DS.entryID, c, r)
            end
        end
        DS:End()
        return
    end

    if self:CanFitItem(c, r, iw, ih, nil) then
        if ZDEV.ClientInventory and ZDEV.ClientInventory.RequestSwap and DS.entryID then
            local targetID = self:EntryAt(c, r)
            if targetID then
                ZDEV.ClientInventory:RequestSwap(DS.entryID, targetID)
            else
                ZDEV.ClientInventory:RequestMove(DS.entryID, c, r)
            end
        end
    end
    DS:End()
end

function PANEL:OpenContextMenu(id)
    local e = self.m_tEntries[id]
    if not e or not e.item then return end
    local item = e.item
    local menu = DermaMenu()

    -- Use (consumables, anything with a use action)
    local hasUse = (type(item.m_fnOnUse) == "function")
    if hasUse then
        menu:AddOption("Use", function()
            if ZDEV.ClientInventory and ZDEV.ClientInventory.RequestUse then
                ZDEV.ClientInventory:RequestUse(id)
            end
        end):SetIcon("icon16/accept.png")
    end

    -- Equip (any equippable item — armor via equipRegion, weapons via eligibleSlots)
    if item.IsEquippable and item:IsEquippable() then
        menu:AddOption("Equip", function()
            if ZDEV.VGUI.RequestEquipItem then ZDEV.VGUI.RequestEquipItem(item) end
        end):SetIcon("icon16/shield_add.png")
    end

    -- Drop
    menu:AddOption("Drop", function()
        if ZDEV.ClientInventory and ZDEV.ClientInventory.RequestDrop then
            ZDEV.ClientInventory:RequestDrop(id)
        end
    end):SetIcon("icon16/arrow_down.png")

    -- Transfer (placeholder)
    menu:AddOption("Transfer", function()
        chat.AddText(Color(200, 200, 120), "[Inv] ", color_white, "Transfer is not yet implemented.")
    end):SetIcon("icon16/arrow_switch.png")

    -- Select / Deselect — multi-select for batch actions
    local isSelected = self:IsEntrySelected(id)
    menu:AddOption(isSelected and "Deselect" or "Select", function()
        self:ToggleSelection(id)
    end):SetIcon(isSelected and "icon16/cross.png" or "icon16/tick.png")

    menu:AddSpacer()

    -- Inspect — opens detailed item frame
    menu:AddOption("Inspect", function()
        if ZDEV.VGUI.OpenInspectFrame then
            ZDEV.VGUI.OpenInspectFrame(item)
        end
    end):SetIcon("icon16/magnifier.png")

    menu:Open()
end

---------------------------------------------------------------------------
-- Multi-selection
---------------------------------------------------------------------------

function PANEL:IsEntrySelected(id)
    self.m_tMultiSelected = self.m_tMultiSelected or {}
    return self.m_tMultiSelected[id] == true
end

function PANEL:ToggleSelection(id)
    self.m_tMultiSelected = self.m_tMultiSelected or {}
    if self.m_tMultiSelected[id] then
        self.m_tMultiSelected[id] = nil
    else
        self.m_tMultiSelected[id] = true
    end
end

function PANEL:GetSelectedItems()
    local t = {}
    self.m_tMultiSelected = self.m_tMultiSelected or {}
    for id in pairs(self.m_tMultiSelected) do
        local e = self.m_tEntries[id]
        if e and e.item then table.insert(t, e.item) end
    end
    return t
end

function PANEL:ClearSelection()
    self.m_tMultiSelected = {}
end

---------------------------------------------------------------------------
-- Paint
---------------------------------------------------------------------------

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(30, 35, 45, 240))

    -- Slot base grid
    for col = 1, self.m_iCols do
        for row = 1, self.m_iRows do
            local x, y = self:CellToPos(col, row)
            surface.SetDrawColor(255, 255, 255, 50)
            surface.SetMaterial(MAT_SLOT.base)
            surface.DrawTexturedRect(x, y, SLOT_SIZE, SLOT_SIZE)
        end
    end

    -- Entries
    self.m_tMultiSelected = self.m_tMultiSelected or {}
    for id, e in pairs(self.m_tEntries) do
        local x, y = self:CellToPos(e.col, e.row)
        local ew = e.w * SLOT_SIZE + (e.w - 1) * SLOT_PAD
        local eh = e.h * SLOT_SIZE + (e.h - 1) * SLOT_PAD
        ZDEV.Items.DrawIcon(e.item, x, y, ew, eh, { selected = (id == self.m_iSelected) })
        if self.m_tMultiSelected[id] then
            surface.SetDrawColor(120, 220, 255, 220)
            surface.DrawOutlinedRect(x - 1, y - 1, ew + 2, eh + 2, 2)
        end
    end

    -- Hover cell highlight
    if self.m_iHoverCell then
        local c, r = self.m_iHoverCell[1], self.m_iHoverCell[2]
        local x, y = self:CellToPos(c, r)
        surface.SetDrawColor(255, 255, 255, 80)
        surface.SetMaterial(MAT_SLOT.hover)
        surface.DrawTexturedRect(x, y, SLOT_SIZE, SLOT_SIZE)
    end

    -- Drag-preview invalid tint
    local DS = ZDEV.VGUI.DragState
    if DS.active and self:IsHovered() and self.m_iHoverCell then
        local c, r = self.m_iHoverCell[1], self.m_iHoverCell[2]
        local item = DS.item
        local iw, ih = 1, 1
        if item and item.GetSize then iw, ih = item:GetSize() end
        local ignoreID = (DS.sourceGrid == self) and DS.entryID or nil
        local fits = self:CanFitItem(c, r, iw, ih, ignoreID)
        if not fits then
            local x, y = self:CellToPos(c, r)
            local rw = iw * SLOT_SIZE + (iw - 1) * SLOT_PAD
            local rh = ih * SLOT_SIZE + (ih - 1) * SLOT_PAD
            surface.SetDrawColor(255, 60, 60, 120)
            surface.DrawRect(x, y, rw, rh)
        end
    end

    return true
end

derma.DefineControl("ZD_InvGrid", "ZDEV Inventory Grid (single-panel)", PANEL, "DPanel")

ZDEV.FILE.SetLoaded( _f )
