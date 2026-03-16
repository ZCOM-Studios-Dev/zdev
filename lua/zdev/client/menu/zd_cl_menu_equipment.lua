-- ZDEV_UID: ZDEV_FUNC_MENU_EQP01 | Path: ZDEV.VGUI.EquipmentMenu
local _f = 'zdev/client/menu/zd_cl_menu_equipment.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Equipment Menu
    Character equipment screen with a 3D player model and overlaid equipment slots.
    Equipment slots are positioned over body regions (head, chest, legs, feet, hands, backpack).
    Equipping items with storage capacity (backpack, pants) dynamically adds
    inventory container grids to the player's inventory.

    Context: Client
]]

local SW, SH = ScrW(), ScrH()

local MAT = {
    SLOT = {
        base = Material("ui/ui_slot.png"),
        hover = Material("ui/ui_slot_hover.png"),
        active = Material("ui/ui_slot_active.png"),
        selected = Material("ui/ui_slot_selected.png"),
        disabled = Material("ui/ui_slot_disabled.png")
    },
    EQUIP = {
        bg = Material("ui/ui_equipment_bg.png"),
        bg_outline = Material("ui/ui_equipment_bg_outline.png")
    }
}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    EQUIPMENT SLOT LAYOUT
    Defines each slot's region, position offset (relative to the model panel),
    and label for display.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Positions are fractions of the model panel dimensions (0-1)
local EQUIP_LAYOUT = {
    {
        region = "head",
        label  = "Head",
        fracX  = 0.72, fracY = 0.02,
    },
    {
        region = "chest",
        label  = "Chest",
        fracX  = 0.72, fracY = 0.25,
    },
    {
        region = "hands",
        label  = "Hands",
        fracX  = 0.02, fracY = 0.35,
    },
    {
        region = "legs",
        label  = "Legs",
        fracX  = 0.72, fracY = 0.50,
    },
    {
        region = "feet",
        label  = "Feet",
        fracX  = 0.72, fracY = 0.72,
    },
    {
        region = "backpack",
        label  = "Backpack",
        fracX  = 0.02, fracY = 0.10,
    },
    {
        region = "weapon",
        label  = "Weapon",
        fracX  = 0.02, fracY = 0.60,
    },
}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    STAT LINE
    Simple key-value display row for the stats panel.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function AddStatLine(parent, label, value, color)
    local line = vgui.Create("DPanel", parent)
    line:Dock(TOP)
    line:SetTall(20)
    line:DockMargin(4, 0, 4, 0)
    line.Paint = function(self, w, h)
        draw.SimpleText(label, "DermaDefault", 4, h / 2, Color(160, 160, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(value), "DermaDefault", w - 4, h / 2, color or Color(220, 220, 240), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    function line:SetValue(v)
        value = v
    end

    return line
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    MAIN EQUIPMENT MENU
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function ZDEV.VGUI.EquipmentMenu(ply, cmd, arg)
    local cli = LocalPlayer()
    if not IsValid(cli) then return end

    local menuW = math.floor(SW * 0.5)
    local menuH = math.floor(SH * 0.65)
    local menu = ZDEV.VGUI.CreateFrame(menuW, menuH, "Equipment")
    menu.m_tEquipSlots = {}

    --[[ ━━━ Left Side: Model Panel with Equipment Slots ━━━ ]]
    menu.modelContainer = vgui.Create("DPanel", menu)
    menu.modelContainer:Dock(LEFT)
    menu.modelContainer:SetWide(math.floor(menuW * 0.55))
    menu.modelContainer:DockMargin(4, 4, 0, 4)
    menu.modelContainer.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 30, 40, 220))
    end

    -- 3D player model
    menu.modelPanel = vgui.Create("DModelPanel", menu.modelContainer)
    menu.modelPanel:Dock(FILL)
    menu.modelPanel:SetModel(cli:GetModel())
    menu.modelPanel:SetFOV(50)
    menu.modelPanel:SetCamPos(Vector(80, 0, 55))
    menu.modelPanel:SetLookAt(Vector(0, 0, 40))
    menu.modelPanel:SetAmbientLight(Color(200, 200, 200))
    menu.modelPanel:SetZPos(1)

    -- Animate the model with idle sequence
    menu.modelPanel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetSequence(ent:LookupSequence("idle_all_01") or 0)
            self:RunAnimation()
        end
    end

    -- Create equipment slots overlaid on the model container
    local slotSize = 56
    menu.modelContainer.PerformLayout = function(self, w, h)
        for _, slotData in ipairs(EQUIP_LAYOUT) do
            local slot = menu.m_tEquipSlots[slotData.region]
            if IsValid(slot) then
                local posX = math.floor(slotData.fracX * (w - slotSize))
                local posY = math.floor(slotData.fracY * (h - slotSize))
                slot:SetPos(posX, posY)
            end
        end
    end

    for _, slotData in ipairs(EQUIP_LAYOUT) do
        local slot = vgui.Create("ZD_EquipSlot", menu.modelContainer)
        slot:SetSize(slotSize, slotSize)
        slot:SetRegion(slotData.region)
        slot:SetLabel(slotData.label)

        -- When equipping an item that grants storage, add a container to inventory
        slot.OnEquip = function(self, item)
            if item and item.GetStorageSize then
                local cols, rows = item:GetStorageSize()
                if cols and rows and cols > 0 and rows > 0 then
                    local invMenu = ZDEV.VGUI.ActiveInventory
                    if IsValid(invMenu) and invMenu.AddContainer then
                        local slotType = item.GetStorageSlotType and item:GetStorageSlotType() or "generic"
                        invMenu:AddContainer(slotData.label, cols, rows, slotType)
                    end
                end
            end

            menu:RefreshStats()
            zdev.log("I", "Equipped item to " .. slotData.region)
        end

        -- When unequipping, remove the associated container
        slot.OnUnequip = function(self, item)
            if item and item.GetStorageSize then
                local invMenu = ZDEV.VGUI.ActiveInventory
                if IsValid(invMenu) and invMenu.RemoveContainer then
                    invMenu:RemoveContainer(slotData.label)
                end
            end

            menu:RefreshStats()
            zdev.log("I", "Unequipped item from " .. slotData.region)
        end

        menu.m_tEquipSlots[slotData.region] = slot
    end

    --[[ ━━━ Right Side: Stats & Info ━━━ ]]
    menu.rightPanel = vgui.Create("DPanel", menu)
    menu.rightPanel:Dock(FILL)
    menu.rightPanel:DockMargin(4, 4, 4, 4)
    menu.rightPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 30, 40, 220))
    end

    -- Stats header
    menu.statsHeader = vgui.Create("DPanel", menu.rightPanel)
    menu.statsHeader:Dock(TOP)
    menu.statsHeader:SetTall(28)
    menu.statsHeader.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(35, 40, 55, 200))
        draw.SimpleText("CHARACTER STATS", "DermaDefaultBold", 8, h / 2, Color(200, 210, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Stats panel
    menu.statsPanel = vgui.Create("DScrollPanel", menu.rightPanel)
    menu.statsPanel:Dock(FILL)
    menu.statsPanel:DockMargin(0, 4, 0, 4)

    -- Stat lines
    menu.m_tStats = {}
    menu.m_tStats.health  = AddStatLine(menu.statsPanel, "Health",  cli:Health(),     Color(100, 220, 100))
    menu.m_tStats.armor   = AddStatLine(menu.statsPanel, "Armor",   cli:Armor(),      Color(100, 160, 220))
    menu.m_tStats.speed   = AddStatLine(menu.statsPanel, "Speed",   cli:GetMaxSpeed(), Color(220, 200, 100))
    menu.m_tStats.weight  = AddStatLine(menu.statsPanel, "Weight",  "0 / 100",        Color(200, 180, 140))
    menu.m_tStats.defense = AddStatLine(menu.statsPanel, "Defense", "0",              Color(180, 180, 200))

    -- Separator
    local sep = vgui.Create("DPanel", menu.statsPanel)
    sep:Dock(TOP)
    sep:SetTall(8)
    sep.Paint = function() end

    -- Equipped items summary header
    local eqHeader = vgui.Create("DPanel", menu.statsPanel)
    eqHeader:Dock(TOP)
    eqHeader:SetTall(24)
    eqHeader.Paint = function(self, w, h)
        draw.SimpleText("EQUIPPED ITEMS", "DermaDefaultBold", 4, h / 2, Color(180, 190, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Equipped items list
    menu.equipList = vgui.Create("DPanel", menu.statsPanel)
    menu.equipList:Dock(TOP)
    menu.equipList:SetTall(200)
    menu.equipList.Paint = function() end

    --[[ ━━━ Bottom Buttons ━━━ ]]
    menu.btnBar = vgui.Create("DPanel", menu.rightPanel)
    menu.btnBar:Dock(BOTTOM)
    menu.btnBar:SetTall(32)
    menu.btnBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 35, 50, 200))
    end

    -- Open Inventory button
    menu.btnBar.btnInv = vgui.Create("DButton", menu.btnBar)
    menu.btnBar.btnInv:Dock(LEFT)
    menu.btnBar.btnInv:SetWide(100)
    menu.btnBar.btnInv:SetText("Inventory")
    menu.btnBar.btnInv:SetTextColor(Color(180, 200, 255))
    menu.btnBar.btnInv.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(60, 70, 90) or Color(40, 50, 65)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
    menu.btnBar.btnInv.DoClick = function()
        RunConsoleCommand("zd_menu_inventory")
    end

    -- Unequip All button
    menu.btnBar.btnClear = vgui.Create("DButton", menu.btnBar)
    menu.btnBar.btnClear:Dock(RIGHT)
    menu.btnBar.btnClear:SetWide(90)
    menu.btnBar.btnClear:SetText("Unequip All")
    menu.btnBar.btnClear:SetTextColor(Color(255, 150, 150))
    menu.btnBar.btnClear.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(90, 50, 50) or Color(60, 40, 40)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
    menu.btnBar.btnClear.DoClick = function()
        for region, slot in pairs(menu.m_tEquipSlots) do
            if IsValid(slot) and slot:GetItemPanel() then
                local itemPnl = slot:Unequip()
                if IsValid(itemPnl) then
                    itemPnl:Remove()
                end
            end
        end
        menu:RefreshStats()
    end

    --[[ ━━━ Refresh Functions ━━━ ]]

    function menu:RefreshStats()
        if not IsValid(cli) then return end

        self.m_tStats.health:SetValue(cli:Health())
        self.m_tStats.armor:SetValue(cli:Armor())
        self.m_tStats.speed:SetValue(cli:GetMaxSpeed())

        -- Count equipped items and calculate bonuses
        local totalDefense = 0
        local equippedCount = 0

        for region, slot in pairs(self.m_tEquipSlots) do
            if IsValid(slot) and slot:GetItemPanel() then
                equippedCount = equippedCount + 1
                local item = slot:GetItemPanel():GetItem()
                if item and item.GetDefense then
                    totalDefense = totalDefense + item:GetDefense()
                end
            end
        end

        self.m_tStats.defense:SetValue(tostring(totalDefense))

        -- Update equipped items list
        self:RefreshEquipList()
    end

    function menu:RefreshEquipList()
        if IsValid(self.equipList) then
            self.equipList:Clear()
        end

        local yOff = 0
        for _, slotData in ipairs(EQUIP_LAYOUT) do
            local slot = self.m_tEquipSlots[slotData.region]
            if IsValid(slot) then
                local itemName = "Empty"
                local nameColor = Color(100, 100, 120)

                if slot:GetItemPanel() then
                    local item = slot:GetItemPanel():GetItem()
                    if item and item.GetName then
                        itemName = item:GetName()
                        nameColor = Color(200, 220, 255)
                    end
                end

                local line = vgui.Create("DPanel", self.equipList)
                line:SetPos(0, yOff)
                line:SetSize(self.equipList:GetWide(), 18)

                local capturedName = itemName
                local capturedColor = nameColor
                local capturedLabel = slotData.label

                line.Paint = function(s, w, h)
                    draw.SimpleText(
                        capturedLabel .. ":", "DermaDefault",
                        8, h / 2, Color(140, 140, 160),
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
                    )
                    draw.SimpleText(
                        capturedName, "DermaDefault",
                        w - 8, h / 2, capturedColor,
                        TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER
                    )
                end

                yOff = yOff + 18
            end
        end
    end

    --- Get a specific equipment slot by region name
    function menu:GetSlot(region)
        return self.m_tEquipSlots[region]
    end

    -- Initial refresh
    menu:RefreshStats()

    ZDEV.VGUI.ActiveEquipment = menu
    return menu
end

concommand.Add("zd_menu_equipment", ZDEV.VGUI.EquipmentMenu)
ZDEV.VGUI.AddToMainMenu("zd_menu_equipment")

ZDEV.FILE.SetLoaded( _f )
