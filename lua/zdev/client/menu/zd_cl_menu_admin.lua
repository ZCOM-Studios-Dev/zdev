local _f = 'zdev/client/vgui/zd_cl_menu_admin.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Admin Menu
    Multi-select player list with command toolbar and per-player data editor.
    Select one or more players, execute commands on all selected, or
    click a single player to edit their NW vars in detail.
    Context: Client (admin-only)
]]

local SW, SH = ScrW(), ScrH()

local CLR = {
    BG       = Color(12, 14, 22, 235),
    HEADER   = Color(30, 40, 65, 220),
    PANEL    = Color(18, 22, 32, 200),
    ROW_A    = Color(22, 26, 38, 180),
    ROW_B    = Color(28, 32, 46, 180),
    ACCENT   = Color(60, 180, 255),
    LABEL    = Color(130, 140, 160),
    VALUE    = Color(230, 235, 245),
    WARN     = Color(255, 180, 50),
    BTN      = Color(40, 50, 70, 200),
    BTN_HOV  = Color(55, 70, 100, 220),
    APPLY    = Color(40, 160, 80),
    RESET    = Color(160, 50, 50),
    CMD_SAFE = Color(40, 80, 50),
    CMD_WARN = Color(120, 100, 30),
    CMD_DANG = Color(130, 40, 40),
}

-- Editable NW fields (Core essentials only).
-- Playtime is auto-tracked server-side (base + live session), so it is shown
-- read-only in the player list rather than being editable here.
local FIELDS = {
    { cat = "Progression", key = "ZDEV_Rank", label = "Rank", type = "Int", min = -1, max = 21 },
}

-- Command definitions: {id, label, color, confirm, argPrompt}
local COMMANDS = {
    { id = "heal",    label = "Heal",    clr = CLR.CMD_SAFE },
    { id = "respawn", label = "Respawn", clr = CLR.CMD_SAFE },
    { id = "god",     label = "God",     clr = CLR.CMD_SAFE },
    { id = "noclip",  label = "Noclip",  clr = CLR.CMD_SAFE },
    { id = "goto",    label = "Goto",    clr = CLR.CMD_SAFE },
    { id = "bring",   label = "Bring",   clr = CLR.CMD_SAFE },
    { id = "freeze",  label = "Freeze",  clr = CLR.CMD_WARN },
    { id = "strip",   label = "Strip",   clr = CLR.CMD_WARN },
    { id = "kill",    label = "Slay",    clr = CLR.CMD_WARN },
    { id = "kick",    label = "Kick",    clr = CLR.CMD_DANG, confirm = true, argPrompt = "Kick reason:" },
    { id = "ban",     label = "Ban",     clr = CLR.CMD_DANG, confirm = true, argPrompt = "Ban duration (minutes, 0=permanent):" },
}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    HELPER: styled button
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function MakeBtn(parent, text, bgClr, w)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetWide(w or 64)
    btn._label = text
    btn._bg = bgClr
    btn.Paint = function(self, bw, bh)
        local c = self:IsHovered() and ColorAlpha(self._bg, 255) or self._bg
        if not self:IsEnabled() then c = CLR.BTN end
        draw.RoundedBox(3, 0, 0, bw, bh, c)
        draw.SimpleText(self._label, "DermaDefaultBold", bw * 0.5, bh * 0.5, CLR.VALUE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return btn
end


--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BUILD MENU
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- ZDEV_UID: ZDEV_FUNC_FCC5C1B0 | Path: ZDEV.VGUI.AdminMenu
function ZDEV.VGUI.AdminMenu()
    local cli = LocalPlayer()
    if not IsValid(cli) then return end
    if not cli:IsAdmin() then
        chat.AddText(Color(255,100,100), "[ZDEV] Admin access required.")
        return
    end

    local menuW = math.min(SW * 0.75, 960)
    local menuH = math.min(SH * 0.8, 740)
    local frame = ZDEV.VGUI.CreateFrame(menuW, menuH, "ZDEV Admin: Player Data Editor")

    -- State
    local editTarget = nil        -- single player being edited (nil = list mode)
    local pendingChanges = {}

    -- Get selected UserIDs from the list
    local listView

    local function GetSelectedUIDs()
        local uids = {}
        if not listView then return uids end
        for _, row in pairs(listView:GetSelected()) do
            local uid = tonumber(row:GetColumnText(1))
            if uid then table.insert(uids, uid) end
        end
        return uids
    end

    local function GetSelectedCount()
        if not listView then return 0 end
        return #listView:GetSelected()
    end

    local function SendCommand(cmdId, arg)
        local uids = GetSelectedUIDs()
        if #uids == 0 then return end
        net.Start("zdev_admin_cmd")
            net.WriteString(cmdId)
            net.WriteTable(uids)
            net.WriteString(arg or "")
        net.SendToServer()
    end

    --[[ ━━━ TOP: Player List ━━━ ]]
    local listPanel = vgui.Create("DPanel", frame)
    listPanel:Dock(TOP)
    listPanel:SetTall(math.max(menuH * 0.28, 150))
    listPanel:DockMargin(4, 4, 4, 0)
    listPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, CLR.PANEL)
        local n = GetSelectedCount()
        local txt = n > 0 and ("PLAYERS  (" .. n .. " selected)") or "PLAYERS"
        draw.SimpleText(txt, "DermaDefaultBold", 6, 4, CLR.ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    listView = vgui.Create("DListView", listPanel)
    listView:Dock(FILL)
    listView:DockMargin(4, 20, 4, 4)
    listView:SetMultiSelect(true)
    listView:AddColumn("UID"):SetFixedWidth(36)
    listView:AddColumn("Name"):SetFixedWidth(130)
    listView:AddColumn("SteamID"):SetFixedWidth(145)
    listView:AddColumn("Group"):SetFixedWidth(65)
    listView:AddColumn("Rank"):SetFixedWidth(90)
    listView:AddColumn("Playtime"):SetFixedWidth(70)
    listView:AddColumn("HP"):SetFixedWidth(40)

    local function RefreshPlayerList()
        listView:Clear()
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then
                local rank = p:GetNWInt("ZDEV_Rank", 0)
                local rankData = ZDEV.RANK[rank]
                local rankName = rankData and rankData.name or tostring(rank)
                local pt = p:GetNWInt("ZDEV_Playtime", 0)
                local ptStr = string.format("%dh %dm", math.floor(pt / 3600), math.floor(pt / 60) % 60)
                listView:AddLine(
                    p:UserID(), p:Nick(), p:SteamID(), p:GetUserGroup(),
                    rankName, ptStr, p:Health()
                )
            end
        end
    end
    RefreshPlayerList()

    --[[ ━━━ COMMAND TOOLBAR ━━━ ]]
    local toolbar = vgui.Create("DPanel", frame)
    toolbar:Dock(TOP)
    toolbar:SetTall(32)
    toolbar:DockMargin(4, 2, 4, 0)
    toolbar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, CLR.HEADER)
        draw.SimpleText("COMMANDS", "DermaDefault", 6, h * 0.5, CLR.LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Refresh button
    local btnRefresh = MakeBtn(toolbar, "Refresh", CLR.BTN, 56)
    btnRefresh:Dock(LEFT)
    btnRefresh:DockMargin(72, 3, 2, 3)
    btnRefresh.DoClick = function()
        RefreshPlayerList()
        if IsValid(editTarget) then editTarget = nil end
    end

    -- Command buttons
    for _, cmd in ipairs(COMMANDS) do
        local btn = MakeBtn(toolbar, cmd.label, cmd.clr, 56)
        btn:Dock(LEFT)
        btn:DockMargin(2, 3, 0, 3)

        btn.DoClick = function()
            if GetSelectedCount() == 0 then return end

            local names = {}
            for _, uid in ipairs(GetSelectedUIDs()) do
                local p = Player(uid)
                if IsValid(p) then table.insert(names, p:Nick()) end
            end
            local nameStr = table.concat(names, ", ")

            if cmd.confirm then
                Derma_StringRequest(
                    cmd.label .. " — " .. nameStr,
                    cmd.argPrompt or "Are you sure?",
                    "",
                    function(txt) SendCommand(cmd.id, txt) end,
                    function() end,
                    cmd.label,
                    "Cancel"
                )
            else
                SendCommand(cmd.id, "")
            end
        end
    end

    --[[ ━━━ BOTTOM: Action bar ━━━ ]]
    local actionBar = vgui.Create("DPanel", frame)
    actionBar:Dock(BOTTOM)
    actionBar:SetTall(34)
    actionBar:DockMargin(4, 0, 4, 4)
    actionBar.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, CLR.PANEL) end

    local statusLabel = vgui.Create("DLabel", actionBar)
    statusLabel:Dock(LEFT)
    statusLabel:DockMargin(8, 0, 0, 0)
    statusLabel:SetWide(350)
    statusLabel:SetText("Select player(s). Double-click to edit data.")
    statusLabel:SetTextColor(CLR.LABEL)

    local function CountPending()
        local n = 0
        for _ in pairs(pendingChanges) do n = n + 1 end
        return n
    end

    local btnApply = MakeBtn(actionBar, "APPLY", CLR.APPLY, 90)
    btnApply:Dock(RIGHT)
    btnApply:DockMargin(2, 4, 4, 4)
    btnApply:SetEnabled(false)

    local btnDiscard = MakeBtn(actionBar, "DISCARD", CLR.RESET, 70)
    btnDiscard:Dock(RIGHT)
    btnDiscard:DockMargin(2, 4, 0, 4)
    btnDiscard:SetEnabled(false)

    local btnBack = MakeBtn(actionBar, "BACK", CLR.BTN, 60)
    btnBack:Dock(RIGHT)
    btnBack:DockMargin(2, 4, 0, 4)
    btnBack:SetVisible(false)

    local function UpdateStatus()
        local n = CountPending()
        btnApply:SetEnabled(n > 0 and editTarget ~= nil)
        btnDiscard:SetEnabled(n > 0)
        if editTarget and IsValid(editTarget) then
            if n > 0 then
                statusLabel:SetText(n .. " pending change(s) for " .. editTarget:Nick())
                statusLabel:SetTextColor(CLR.WARN)
            else
                statusLabel:SetText("Editing: " .. editTarget:Nick() .. " [" .. editTarget:SteamID() .. "]")
                statusLabel:SetTextColor(CLR.ACCENT)
            end
        else
            statusLabel:SetText("Select player(s). Double-click to edit data.")
            statusLabel:SetTextColor(CLR.LABEL)
        end
    end

    --[[ ━━━ CENTER: Editor (shown on double-click) ━━━ ]]
    local editorScroll = vgui.Create("DScrollPanel", frame)
    editorScroll:Dock(FILL)
    editorScroll:DockMargin(4, 2, 4, 2)

    local function BuildEditor(ply)
        editorScroll:Clear()
        pendingChanges = {}
        editTarget = ply
        btnBack:SetVisible(true)

        if not IsValid(ply) then
            UpdateStatus()
            return
        end

        local lastCat = ""
        for i, field in ipairs(FIELDS) do
            if field.cat ~= lastCat then
                lastCat = field.cat
                local header = vgui.Create("DPanel", editorScroll)
                header:Dock(TOP)
                header:SetTall(24)
                header:DockMargin(0, i > 1 and 6 or 0, 0, 2)
                local catName = lastCat
                header.Paint = function(self, w, h)
                    draw.RoundedBox(3, 0, 0, w, h, CLR.HEADER)
                    draw.SimpleText(string.upper(catName), "DermaDefaultBold", 8, h * 0.5, CLR.ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            local row = vgui.Create("DPanel", editorScroll)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 0, 0, 1)
            local rowIdx = i
            local fKey = field.key
            row.Paint = function(self, w, h)
                local bg = pendingChanges[fKey] ~= nil and Color(50, 60, 30, 180) or (rowIdx % 2 == 0 and CLR.ROW_A or CLR.ROW_B)
                draw.RoundedBox(2, 0, 0, w, h, bg)
            end

            local lbl = vgui.Create("DLabel", row)
            lbl:Dock(LEFT)
            lbl:SetWide(140)
            lbl:DockMargin(8, 0, 0, 0)
            lbl:SetText(field.label)
            lbl:SetTextColor(CLR.LABEL)

            local keyLbl = vgui.Create("DLabel", row)
            keyLbl:Dock(LEFT)
            keyLbl:SetWide(160)
            keyLbl:DockMargin(4, 0, 0, 0)
            keyLbl:SetText(field.key)
            keyLbl:SetTextColor(Color(80, 90, 110))

            local currentVal = field.type == "Float" and ply:GetNWFloat(field.key, 0) or ply:GetNWInt(field.key, 0)

            local input = vgui.Create("DTextEntry", row)
            input:Dock(FILL)
            input:DockMargin(4, 3, 4, 3)
            input:SetText(tostring(currentVal))
            input:SetTextColor(CLR.VALUE)
            input.Paint = function(self, w, h)
                draw.RoundedBox(3, 0, 0, w, h, Color(10, 12, 20, 200))
                self:DrawTextEntryText(
                    pendingChanges[fKey] ~= nil and CLR.WARN or CLR.VALUE,
                    CLR.ACCENT, CLR.ACCENT
                )
            end

            local function CommitInput(self)
                local newVal
                if field.type == "Float" then
                    newVal = tonumber(self:GetText())
                    if newVal then newVal = math.Clamp(newVal, field.min, field.max) end
                else
                    newVal = math.floor(tonumber(self:GetText()) or 0)
                    newVal = math.Clamp(newVal, field.min, field.max)
                end
                if newVal == nil then self:SetText(tostring(currentVal)) return end
                if newVal ~= currentVal then
                    pendingChanges[fKey] = { val = newVal, type = field.type }
                    self:SetText(tostring(newVal))
                else
                    pendingChanges[fKey] = nil
                    self:SetText(tostring(currentVal))
                end
                UpdateStatus()
            end
            input.OnEnter = CommitInput
            input.OnLoseFocus = CommitInput

            local btnR = vgui.Create("DButton", row)
            btnR:Dock(RIGHT)
            btnR:SetWide(20)
            btnR:DockMargin(0, 3, 4, 3)
            btnR:SetText("R")
            btnR:SetTextColor(Color(255, 120, 120))
            btnR:SetFont("DermaDefaultBold")
            btnR.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, self:IsHovered() and CLR.RESET or CLR.BTN)
            end
            btnR.DoClick = function()
                pendingChanges[fKey] = nil
                input:SetText(tostring(currentVal))
                UpdateStatus()
            end
        end

        UpdateStatus()
    end

    local function ClearEditor()
        editorScroll:Clear()
        editTarget = nil
        pendingChanges = {}
        btnBack:SetVisible(false)
        UpdateStatus()
    end

    --[[ ━━━ WIRE EVENTS ━━━ ]]

    listView.DoDoubleClick = function(lst, index, pnl)
        local uid = tonumber(pnl:GetColumnText(1))
        if not uid then return end
        local ply = Player(uid)
        if IsValid(ply) then
            BuildEditor(ply)
        end
    end

    btnApply.DoClick = function()
        if not IsValid(editTarget) or CountPending() == 0 then return end
        local payload = {}
        for key, data in pairs(pendingChanges) do
            payload[key] = { val = data.val, type = data.type }
        end
        net.Start("zdev_admin_setdata")
            net.WriteEntity(editTarget)
            net.WriteTable(payload)
        net.SendToServer()
        timer.Simple(0.3, function()
            if IsValid(editTarget) then BuildEditor(editTarget) end
        end)
    end

    btnDiscard.DoClick = function()
        if IsValid(editTarget) then BuildEditor(editTarget) end
    end

    btnBack.DoClick = function()
        ClearEditor()
        RefreshPlayerList()
    end
end

ZDEV.CMDS.Register( "zdev_menu_admin", ZDEV.VGUI.AdminMenu, { aliases = { "zd_menu_admin" } } )
ZDEV.VGUI.AddToMainMenu("zdev_menu_admin")

ZDEV.FILE.SetLoaded( _f )
