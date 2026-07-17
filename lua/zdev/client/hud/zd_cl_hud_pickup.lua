local _f = 'zdev/client/hud/zd_cl_hud_pickup.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Pickup HUD
    Replaces the Facepunch base gamemode pickup notifications with a
    ZDEV-styled stack of weapon / item / ammo pickup cards on the right
    side of the screen. Same hooks (HUDWeaponPickedUp / HUDItemPickedUp /
    HUDAmmoPickedUp), but rendered with the project's flat-panel + accent
    bar look using _HUD.CLR.PRI / SEC and the "sadmachine" font.
    Context: Client
]]

ZDEV.CHUD       = ZDEV.CHUD or {}
ZDEV.CHUD.PKUP  = ZDEV.CHUD.PKUP or {}

local LP
local SW, SH = ScrW(), ScrH()

-- _HUD.CLR.PRI / SEC and the CONV_* helpers in zd_cl_hud.lua are file-local,
-- so we reproduce the convar lookup here. Same convars, same result.
local function HudClrPri() return string.ToColor(GetConVarString("zdev_hud_clr_pri")) end
local function HudClrSec() return string.ToColor(GetConVarString("zdev_hud_clr_sec")) end

-- Convars: same naming convention as the rest of the HUD toggles.
-- Canonicalized (Sweep Phase 4a); old zd_hud_pickup mirrors via legacy alias.
ZDEV.CONV.ClientVar("zdev_hud_pickup", "1", "Toggle ZDEV pickup notifications (weapons/items/ammo)", { legacy = "zd_hud_pickup" })

-- Visual constants
local PKUP = {
    CARD_W      = 280,
    CARD_H      = 32,
    CARD_GAP    = 4,
    ICON_W      = 28,
    ACCENT_W    = 3,            -- left accent bar width
    HOLD_TIME   = 5,            -- seconds visible
    FADE_IN     = 0.15,
    FADE_OUT    = 0.40,
    SLIDE_PX    = 60,           -- horizontal slide distance during fade
    LERP_SPEED  = 8,            -- exponential smoothing for y position
    MARGIN_R    = 24,           -- distance from right edge
    TOP_FRAC    = 0.32,         -- starting Y as fraction of SH
    FONT_NAME   = "sadmachine_pkup",
    FONT_SMALL  = "sadmachine_pkup_s",
}

-- Pickup type → accent color and label
local TYPE_CLR = {
    weapon  = Color(255, 200,  50, 255),
    item    = Color(120, 255, 140, 255),
    ammo    = Color(120, 200, 255, 255),
}

-- Lazy-create our two custom font sizes (mirrors how zd_cl_imgui handles fonts)
local _fontsBuilt = false
local function BuildFonts()
    if _fontsBuilt then return end
    ZDEV.FONT.Register(PKUP.FONT_NAME, {
        font = "sadmachine", size = 18, weight = 600, antialias = true, extended = true
    })
    ZDEV.FONT.Register(PKUP.FONT_SMALL, {
        font = "sadmachine", size = 14, weight = 500, antialias = true, extended = true
    })
    _fontsBuilt = true
end

-- The pickup history (FIFO; oldest entries drift down + fade out)
ZDEV.CHUD.PKUP.History = ZDEV.CHUD.PKUP.History or {}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    INTERNAL: Add a pickup card
    Mirrors AddGenericPickup() in the Facepunch original but
    annotates the pickup with a `kind` so we can colorize.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function AddPickup(name, kind, amount)
    BuildFonts()

    local pickup = {
        time      = CurTime(),
        name      = name or "?",
        kind      = kind or "item",
        amount    = amount,                    -- nil for non-ammo
        holdtime  = PKUP.HOLD_TIME,
        fadein    = PKUP.FADE_IN,
        fadeout   = PKUP.FADE_OUT,
        color     = TYPE_CLR[kind] or TYPE_CLR.item,
    }

    surface.SetFont(PKUP.FONT_NAME)
    local tw, th = surface.GetTextSize(pickup.name)
    pickup.textW = tw
    pickup.textH = th

    table.insert(ZDEV.CHUD.PKUP.History, pickup)
    return pickup
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    HOOKS: Weapon / Item / Ammo pickup
    Returning true from these hooks would suppress the engine's
    default HUD draw, but since we're a hook listener (not a
    gamemode override) the engine still calls its own drawer
    if it is the active gamemode method. Sandbox / DarkRP-style
    gamemodes don't paint anything when we return true here, so
    we DO return true to fully replace the default look.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function ZDEV.CHUD.OnPickupWeapon(wep)
    if not GetConVar("zdev_hud_pickup"):GetBool() then return end
    if not (LocalPlayer() and IsValid(LocalPlayer()) and LocalPlayer():IsPlayer() and LocalPlayer():Alive()) then return end
    if not IsValid(wep) or not isfunction(wep.GetPrintName) then return end

    AddPickup(wep:GetPrintName(), "weapon")
    return true
end
hook.Add("HUDWeaponPickedUp", "ZDEV.CHUD.OnPickupWeapon", ZDEV.CHUD.OnPickupWeapon)

function ZDEV.CHUD.OnPickupItem(itemName)
    if not GetConVar("zdev_hud_pickup"):GetBool() then return end
    if not (LocalPlayer() and IsValid(LocalPlayer()) and LocalPlayer():IsPlayer() and LocalPlayer():Alive()) then return end

    -- HL2 prefixes localized item names with #; strip for display but keep
    -- the language-table lookup chance via language.GetPhrase if available.
    local display = itemName or "?"
    if string.sub(display, 1, 1) == "#" and language and language.GetPhrase then
        display = language.GetPhrase(string.sub(display, 2))
    end

    AddPickup(display, "item")
    return true
end
hook.Add("HUDItemPickedUp", "ZDEV.CHUD.OnPickupItem", ZDEV.CHUD.OnPickupItem)

function ZDEV.CHUD.OnPickupAmmo(itemName, amount)
    if not GetConVar("zdev_hud_pickup"):GetBool() then return end
    if not (LocalPlayer() and IsValid(LocalPlayer()) and LocalPlayer():IsPlayer() and LocalPlayer():Alive()) then return end

    local display = itemName or "ammo"
    if language and language.GetPhrase then
        display = language.GetPhrase(itemName .. "_ammo")
    end

    -- Coalesce repeated ammo pickups of the same type (matches Facepunch behavior)
    for _, v in ipairs(ZDEV.CHUD.PKUP.History) do
        if v.kind == "ammo" and v.name == display then
            v.amount = tostring((tonumber(v.amount) or 0) + (amount or 0))
            v.time   = CurTime() - v.fadein
            return true
        end
    end

    AddPickup(display, "ammo", tostring(amount or 0))
    return true
end
hook.Add("HUDAmmoPickedUp", "ZDEV.CHUD.OnPickupAmmo", ZDEV.CHUD.OnPickupAmmo)

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PAINT
    Each card slides in from the right (alpha-driven X offset),
    holds, then fades + slides out. Y position is exponentially
    smoothed toward its target slot so the stack reflows when
    older cards expire.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function ZDEV.CHUD.PaintPickup()
    LP = LocalPlayer()
    if not (LP and IsValid(LP) and LP:IsPlayer() and LP:Alive()) then return end
    if not GetConVar("zdev_hud_pickup"):GetBool() then return end

    local history = ZDEV.CHUD.PKUP.History
    if #history == 0 then return end

    BuildFonts()

    -- Parallax: subtle drift in sync with the visor. Self-balancing pop at
    -- function exit via a wrapper hook below.
    if ZDEV.CHUD.PushParallax then ZDEV.CHUD.PushParallax("pickup") end

    local clrPri = HudClrPri()
    local clrSec = HudClrSec()

    local now    = CurTime()
    local rightX = SW - PKUP.MARGIN_R                -- right edge of cards
    local baseY  = math.floor(SH * PKUP.TOP_FRAC)
    local lerpA  = math.Clamp(FrameTime() * PKUP.LERP_SPEED, 0, 1)

    -- Walk newest → oldest so y increases downward; remove expired entries.
    for i = #history, 1, -1 do
        local v = history[i]

        -- Time math (same as Facepunch)
        local delta = (v.time + v.holdtime) - now
        local frac  = delta / v.holdtime
        local alpha = 255

        if delta <= 0 then
            -- Fully expired
            table.remove(history, i)
        else
            if frac > 1 - v.fadein then
                -- Fading in
                alpha = math.Clamp((1.0 - frac) * (255 / v.fadein), 0, 255)
            elseif frac < v.fadeout then
                -- Fading out
                alpha = math.Clamp(frac * (255 / v.fadeout), 0, 255)
            end
            v.alpha = alpha
        end
    end

    -- Second pass: lay out + draw. Newest card sits at the top.
    local y = baseY
    for i = 1, #history do
        local v = history[i]
        local alpha = v.alpha or 0

        -- Slide-in offset: when alpha is low, the card is pushed off to the right.
        local slideOff = PKUP.SLIDE_PX * (1 - (alpha / 255))
        local cardX = rightX - PKUP.CARD_W + slideOff
        local cardW = PKUP.CARD_W
        local cardH = PKUP.CARD_H

        -- Smooth Y toward target
        v.y = v.y and (v.y + (y - v.y) * lerpA) or y

        local drawY = math.Round(v.y)
        local drawX = math.Round(cardX)

        local accent = v.color or TYPE_CLR.item

        -- Backdrop (matches the dark, flat panels used in the database menu / dashboard)
        surface.SetDrawColor(15, 18, 25, math.floor(220 * (alpha / 255)))
        surface.DrawRect(drawX, drawY, cardW, cardH)

        -- Subtle bottom edge with secondary HUD color (cyan/green by convar)
        local secA = ColorAlpha(clrSec, math.floor(60 * (alpha / 255)))
        surface.SetDrawColor(secA)
        surface.DrawRect(drawX, drawY + cardH - 1, cardW, 1)

        -- Left accent bar (kind-colored)
        surface.SetDrawColor(accent.r, accent.g, accent.b, alpha)
        surface.DrawRect(drawX, drawY, PKUP.ACCENT_W, cardH)

        -- Outline using the primary HUD color (very faint)
        local priA = ColorAlpha(clrPri, math.floor(70 * (alpha / 255)))
        surface.SetDrawColor(priA)
        surface.DrawOutlinedRect(drawX, drawY, cardW, cardH, 1)

        -- Kind glyph (small filled square in the icon column, color-coded)
        local iconCx = drawX + PKUP.ACCENT_W + (PKUP.ICON_W * 0.5)
        local iconCy = drawY + cardH * 0.5
        surface.SetDrawColor(accent.r, accent.g, accent.b, alpha)
        if v.kind == "weapon" then
            -- Diamond
            surface.DrawRect(iconCx - 6, iconCy - 6, 12, 12)
        elseif v.kind == "ammo" then
            -- Two stacked bars (clip-magazine vibe)
            surface.DrawRect(iconCx - 7, iconCy - 5, 14, 4)
            surface.DrawRect(iconCx - 7, iconCy + 1, 14, 4)
        else
            -- Item: outlined dot
            surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(alpha * 0.4))
            surface.DrawRect(iconCx - 7, iconCy - 7, 14, 14)
            surface.SetDrawColor(accent.r, accent.g, accent.b, alpha)
            surface.DrawOutlinedRect(iconCx - 7, iconCy - 7, 14, 14, 1)
        end

        -- Pickup name (left-aligned after the icon column)
        local textX = drawX + PKUP.ACCENT_W + PKUP.ICON_W + 6
        local textY = drawY + cardH * 0.5
        -- Drop shadow
        draw.SimpleText(v.name, PKUP.FONT_NAME, textX + 1, textY + 1,
            Color(0, 0, 0, math.floor(alpha * 0.6)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(v.name, PKUP.FONT_NAME, textX, textY,
            Color(240, 245, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Amount (right-aligned, ammo only)
        if v.amount then
            local amtX = drawX + cardW - 8
            draw.SimpleText("+" .. v.amount, PKUP.FONT_NAME, amtX + 1, textY + 1,
                Color(0, 0, 0, math.floor(alpha * 0.6)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText("+" .. v.amount, PKUP.FONT_NAME, amtX, textY,
                ColorAlpha(accent, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        -- Tiny "kind" label in the lower-right of the card
        draw.SimpleText(string.upper(v.kind), PKUP.FONT_SMALL, drawX + cardW - 8, drawY + cardH - 4,
            ColorAlpha(clrSec, math.floor(alpha * 0.5)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

        y = y + cardH + PKUP.CARD_GAP
    end

    if ZDEV.CHUD.PopParallax then ZDEV.CHUD.PopParallax() end
end
hook.Add("HUDPaint", "ZDEV.CHUD.PaintPickup", ZDEV.CHUD.PaintPickup)

-- Recompute screen-space caches if resolution changes
hook.Add("OnScreenSizeChanged", "ZDEV.CHUD.PickupResize", function()
    SW, SH = ScrW(), ScrH()
end)

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DEBUG: spawn fake pickups for visual tuning
    zdev_hud_pickup_test  →  one of each kind
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

concommand.Add("zdev_hud_pickup_test", function()
    AddPickup("Pulse Rifle",  "weapon")
    AddPickup("Health Vial",  "item")
    AddPickup("Pistol Ammo",  "ammo", "30")
end)

ZDEV.FILE.SetLoaded( _f )
