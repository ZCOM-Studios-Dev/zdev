--[[
    MetaHUD Realistic Pistol Base - Client

    Handles:
    - Ironsight view positioning
    - Weapon sway and breathing
    - HUD elements (crosshair, ammo)
    - Muzzle flash and shell ejection
    - View model effects
]]

include("shared.lua")

--------------------------------------------------------------------------------
-- VIEW MODEL POSITIONING
--------------------------------------------------------------------------------

-- Sway configuration
SWEP.SwayScale       = 1.0
SWEP.BobScale        = 1.0
SWEP.SwayMultiplier  = 0.02
SWEP.BobMultiplier   = 0.5

-- Cached sway values
local swayX, swayY = 0, 0
local breathePhase = 0
local lastEyeAngles = Angle(0, 0, 0)

-- HUD bob/sway state (mirrors viewmodel motion)
local hudSwayX, hudSwayY = 0, 0
local hudBobX, hudBobY = 0, 0
local hudBobPhase = 0
local lastVelocity = Vector(0, 0, 0)

--[[
    Calculate view model position with ironsights and sway
    @param pos - Base position
    @param ang - Base angle
    @param fov - Field of view
    @return Vector, Angle, number
]]
function SWEP:GetViewModelPosition(pos, ang)
    if not IsValid(self:GetOwner()) then return pos, ang end

    local owner = self:GetOwner()
    local ft = FrameTime()
    local ct = CurTime()

    -- Ironsight interpolation
    local adsLerp = self.IronsightLerp or 0

    -- Calculate sway based on eye angle delta (works in render context)
    local eyeAng = owner:EyeAngles()
    local deltaYaw = math.AngleDifference(eyeAng.y, lastEyeAngles.y)
    local deltaPitch = math.AngleDifference(eyeAng.p, lastEyeAngles.p)
    lastEyeAngles = eyeAng

    local mx = deltaYaw * 0.15 * self.SwayMultiplier
    local my = deltaPitch * 0.15 * self.SwayMultiplier
    swayX = Lerp(ft * 8, swayX, mx)
    swayY = Lerp(ft * 8, swayY, my)

    -- Breathing sway (reduced when ADS)
    breathePhase = breathePhase + ft * 1.2
    local breatheAmt = (1 - adsLerp * 0.7) * 0.15
    local breatheX = math.sin(breathePhase) * breatheAmt
    local breatheY = math.cos(breathePhase * 0.7) * breatheAmt * 0.5

    -- Movement sway
    local vel = owner:GetVelocity():Length2D()
    local moveSwayAmt = math.Clamp(vel / 300, 0, 1) * (1 - adsLerp * 0.5)
    local moveSway = math.sin(ct * 8) * moveSwayAmt * 0.5

    -- Apply sway to angles
    ang:RotateAroundAxis(ang:Right(), swayY + breatheY + moveSway * 0.5)
    ang:RotateAroundAxis(ang:Up(), swayX + breatheX + moveSway)

    -- Apply ironsight offset
    if adsLerp > 0.01 then
        local adsPos = self.IronsightPos or Vector(0, 0, 0)
        local adsAng = self.IronsightAng or Angle(0, 0, 0)

        pos = pos + adsPos.x * ang:Right() * adsLerp
        pos = pos + adsPos.y * ang:Forward() * adsLerp
        pos = pos + adsPos.z * ang:Up() * adsLerp

        ang = ang + adsAng * adsLerp
    end

    return pos, ang
end

--[[
    Modify view FOV when aiming
    @param fov - Current FOV
    @return number
]]
function SWEP:TranslateFOV(fov)
    local adsLerp = self.IronsightLerp or 0
    local adsFOV = self.IronsightFOV or 75

    return Lerp(adsLerp, fov, adsFOV)
end

--------------------------------------------------------------------------------
-- SCI-FI HUD CONFIGURATION
--------------------------------------------------------------------------------

-- Color palette - Cyberpunk/Sci-Fi theme
local THEME = {
    PRIMARY      = Color(0, 200, 255, 255),      -- Cyan accent
    SECONDARY    = Color(0, 255, 180, 255),      -- Teal highlight
    WARNING      = Color(255, 180, 0, 255),      -- Amber warning
    CRITICAL     = Color(255, 60, 60, 255),      -- Red critical
    BACKGROUND   = Color(10, 20, 30, 180),       -- Dark panel BG
    TEXT         = Color(200, 230, 255, 255),    -- Light text
    TEXT_DIM     = Color(100, 140, 160, 180),    -- Dim text
    GLOW         = Color(0, 200, 255, 60),       -- Glow effect
}

-- Animation state
local HUD_STATE = {
    rotation        = 0,           -- Outer ring rotation
    innerRotation   = 0,           -- Inner ring rotation (opposite)
    pulsePhase      = 0,           -- Pulse animation phase
    firePulse       = 0,           -- Fire feedback pulse
    reloadProgress  = 0,           -- Reload bar progress
    lockOnPulse     = 0,           -- Target lock pulse
    glitchTimer     = 0,           -- Glitch effect timer
    lastClip        = 0,           -- Track ammo changes
    scanlineOffset  = 0,           -- Scanline effect
}

-- Fonts (created once)
local fontsCreated = false
local function EnsureFonts()
    if fontsCreated then return end

    surface.CreateFont("MH_SciFi_Large", {
        font = "Roboto",
        size = 32,
        weight = 700,
        antialias = true,
    })
    surface.CreateFont("MH_SciFi_Medium", {
        font = "Roboto",
        size = 18,
        weight = 500,
        antialias = true,
    })
    surface.CreateFont("MH_SciFi_Small", {
        font = "Roboto Condensed",
        size = 12,
        weight = 400,
        antialias = true,
    })
    surface.CreateFont("MH_SciFi_Mono", {
        font = "Consolas",
        size = 14,
        weight = 400,
        antialias = true,
    })

    fontsCreated = true
end

--------------------------------------------------------------------------------
-- HUD BOB & SWAY CALCULATION
--------------------------------------------------------------------------------

-- HUD sway/bob configuration
local HUD_BOB = {
    SwayScale       = 25,       -- Horizontal sway from mouse movement (pixels)
    SwaySmoothing   = 6,        -- Sway interpolation speed
    BobAmplitudeX   = 4,        -- Horizontal bob amplitude (pixels)
    BobAmplitudeY   = 3,        -- Vertical bob amplitude (pixels)
    BobSpeed        = 10,       -- Bob cycle speed multiplier
    BreathScale     = 2,        -- Breathing movement amplitude
    VelocityScale   = 0.015,    -- Movement influence multiplier
}

--[[
    Calculate HUD bob and sway offsets mirroring viewmodel motion
    @return number, number - X and Y offset in pixels
]]
local function CalcHUDBobSway(owner, adsLerp)
    if not IsValid(owner) then return 0, 0 end

    local ft = FrameTime()
    local ct = CurTime()

    -- Mouse movement sway (from eye angle deltas)
    local eyeAng = owner:EyeAngles()
    local deltaYaw = math.AngleDifference(eyeAng.y, lastEyeAngles.y)
    local deltaPitch = math.AngleDifference(eyeAng.p, lastEyeAngles.p)

    -- Target sway based on mouse movement
    local targetSwayX = -deltaYaw * HUD_BOB.SwayScale * 0.1
    local targetSwayY = deltaPitch * HUD_BOB.SwayScale * 0.1

    -- Smooth interpolation
    hudSwayX = Lerp(ft * HUD_BOB.SwaySmoothing, hudSwayX, targetSwayX)
    hudSwayY = Lerp(ft * HUD_BOB.SwaySmoothing, hudSwayY, targetSwayY)

    -- Movement bob (sinusoidal based on velocity)
    local vel = owner:GetVelocity()
    local speed = vel:Length2D()
    local moving = speed > 10

    if moving then
        hudBobPhase = hudBobPhase + ft * HUD_BOB.BobSpeed * (speed / 200)
    else
        -- Gentle breathing when stationary
        hudBobPhase = hudBobPhase + ft * 1.2
    end

    -- Calculate bob offset
    local bobMultiplier = math.Clamp(speed / 250, 0, 1)
    local breathMultiplier = 1 - bobMultiplier

    -- Walking/running bob
    local walkBobX = math.sin(hudBobPhase) * HUD_BOB.BobAmplitudeX * bobMultiplier
    local walkBobY = math.abs(math.sin(hudBobPhase * 2)) * HUD_BOB.BobAmplitudeY * bobMultiplier

    -- Breathing motion (subtle, when still)
    local breathX = math.sin(hudBobPhase * 0.8) * HUD_BOB.BreathScale * breathMultiplier
    local breathY = math.cos(hudBobPhase * 0.5) * HUD_BOB.BreathScale * 0.6 * breathMultiplier

    -- Combine bob sources
    hudBobX = Lerp(ft * 8, hudBobX, walkBobX + breathX)
    hudBobY = Lerp(ft * 8, hudBobY, walkBobY + breathY)

    -- Reduce effect when ADS for stability
    local adsReduction = 1 - adsLerp * 0.7

    -- Final combined offset
    local offsetX = (hudSwayX + hudBobX) * adsReduction
    local offsetY = (hudSwayY + hudBobY) * adsReduction

    return offsetX, offsetY
end

--------------------------------------------------------------------------------
-- DRAWING UTILITIES
--------------------------------------------------------------------------------

--[[
    Draw a circle from line segments
    @param x, y - Center position
    @param radius - Circle radius
    @param segments - Number of segments
    @param startAngle - Starting angle in radians
    @param endAngle - Ending angle in radians (nil = full circle)
]]
local function DrawCircleArc(x, y, radius, segments, startAngle, endAngle)
    startAngle = startAngle or 0
    endAngle = endAngle or (math.pi * 2)
    segments = segments or 32

    local step = (endAngle - startAngle) / segments
    for i = 0, segments - 1 do
        local a1 = startAngle + step * i
        local a2 = startAngle + step * (i + 1)
        surface.DrawLine(
            x + math.cos(a1) * radius,
            y + math.sin(a1) * radius,
            x + math.cos(a2) * radius,
            y + math.sin(a2) * radius
        )
    end
end

--[[
    Draw corner bracket at specified position
    @param x, y - Corner position
    @param size - Bracket arm length
    @param thick - Line thickness
    @param corner - 1=TL, 2=TR, 3=BR, 4=BL
]]
local function DrawCornerBracket(x, y, size, thick, corner)
    local dx, dy = 1, 1
    if corner == 1 then dx, dy = 1, 1
    elseif corner == 2 then dx, dy = -1, 1
    elseif corner == 3 then dx, dy = -1, -1
    elseif corner == 4 then dx, dy = 1, -1
    end

    -- Horizontal arm
    surface.DrawRect(x, y, size * dx, thick)
    -- Vertical arm
    surface.DrawRect(x, y, thick, size * dy)
end

--[[
    Draw a progress arc (filled arc segment)
    @param x, y - Center position
    @param innerR, outerR - Inner and outer radius
    @param startAngle, endAngle - Arc bounds in radians
    @param segments - Number of segments
]]
local function DrawProgressArc(x, y, innerR, outerR, startAngle, endAngle, segments)
    segments = segments or 24
    local step = (endAngle - startAngle) / segments

    for i = 0, segments - 1 do
        local a1 = startAngle + step * i
        local a2 = startAngle + step * (i + 1)

        local poly = {
            { x = x + math.cos(a1) * innerR, y = y + math.sin(a1) * innerR },
            { x = x + math.cos(a1) * outerR, y = y + math.sin(a1) * outerR },
            { x = x + math.cos(a2) * outerR, y = y + math.sin(a2) * outerR },
            { x = x + math.cos(a2) * innerR, y = y + math.sin(a2) * innerR },
        }

        surface.DrawPoly(poly)
    end
end

--[[
    Draw tick marks around a circle
    @param x, y - Center position
    @param radius - Circle radius
    @param count - Number of ticks
    @param tickLen - Length of each tick
    @param rotation - Rotation offset in radians
]]
local function DrawCircleTicks(x, y, radius, count, tickLen, rotation)
    rotation = rotation or 0
    for i = 0, count - 1 do
        local angle = rotation + (i / count) * math.pi * 2
        local x1 = x + math.cos(angle) * radius
        local y1 = y + math.sin(angle) * radius
        local x2 = x + math.cos(angle) * (radius + tickLen)
        local y2 = y + math.sin(angle) * (radius + tickLen)
        surface.DrawLine(x1, y1, x2, y2)
    end
end

--------------------------------------------------------------------------------
-- RETICLE RENDERING
--------------------------------------------------------------------------------

--[[
    Draw the main sci-fi reticle/crosshair
]]
function SWEP:DrawSciFiReticle(cx, cy, adsLerp, spread)
    local ft = FrameTime()
    local alpha = 255 * (1 - adsLerp * 0.8)

    -- Update animations
    HUD_STATE.rotation = HUD_STATE.rotation + ft * 30 * (1 + HUD_STATE.firePulse * 2)
    HUD_STATE.innerRotation = HUD_STATE.innerRotation - ft * 20
    HUD_STATE.pulsePhase = HUD_STATE.pulsePhase + ft * 3
    HUD_STATE.firePulse = math.max(0, HUD_STATE.firePulse - ft * 8)

    local pulse = math.sin(HUD_STATE.pulsePhase) * 0.5 + 0.5
    local spreadPx = math.Clamp(spread * 1000, 8, 80)
    local fireExpand = HUD_STATE.firePulse * 15

    -- Base sizes
    local outerRadius = 45 + spreadPx * 0.3 + fireExpand
    local innerRadius = 25 + spreadPx * 0.2 + fireExpand * 0.5
    local coreRadius = 8

    -- Glow layer (behind everything)
    surface.SetDrawColor(THEME.GLOW.r, THEME.GLOW.g, THEME.GLOW.b, 30 + pulse * 20)
    DrawCircleArc(cx, cy, outerRadius + 5, 48)
    DrawCircleArc(cx, cy, outerRadius + 8, 48)

    -- Outer rotating ring with gaps
    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, alpha * 0.8)
    local outerRot = math.rad(HUD_STATE.rotation)
    for i = 0, 3 do
        local segStart = outerRot + i * math.pi / 2 + 0.15
        local segEnd = outerRot + (i + 1) * math.pi / 2 - 0.15
        DrawCircleArc(cx, cy, outerRadius, 12, segStart, segEnd)
    end

    -- Outer tick marks
    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, alpha * 0.5)
    DrawCircleTicks(cx, cy, outerRadius + 2, 24, 4, outerRot)

    -- Inner counter-rotating ring
    surface.SetDrawColor(THEME.SECONDARY.r, THEME.SECONDARY.g, THEME.SECONDARY.b, alpha * 0.7)
    local innerRot = math.rad(HUD_STATE.innerRotation)
    for i = 0, 5 do
        local segStart = innerRot + i * math.pi / 3 + 0.1
        local segEnd = innerRot + (i + 1) * math.pi / 3 - 0.1
        DrawCircleArc(cx, cy, innerRadius, 8, segStart, segEnd)
    end

    -- Corner brackets (expand with spread)
    local bracketDist = 35 + spreadPx * 0.5 + fireExpand
    local bracketSize = 12
    local bracketThick = 2

    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, alpha)
    DrawCornerBracket(cx - bracketDist, cy - bracketDist, bracketSize, bracketThick, 1)
    DrawCornerBracket(cx + bracketDist - bracketThick, cy - bracketDist, bracketSize, bracketThick, 2)
    DrawCornerBracket(cx + bracketDist - bracketThick, cy + bracketDist - bracketThick, bracketSize, bracketThick, 3)
    DrawCornerBracket(cx - bracketDist, cy + bracketDist - bracketThick, bracketSize, bracketThick, 4)

    -- Diagonal lines from corners
    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, alpha * 0.4)
    local diagLen = 8
    surface.DrawLine(cx - bracketDist - diagLen, cy - bracketDist - diagLen, cx - bracketDist, cy - bracketDist)
    surface.DrawLine(cx + bracketDist + diagLen, cy - bracketDist - diagLen, cx + bracketDist, cy - bracketDist)
    surface.DrawLine(cx + bracketDist + diagLen, cy + bracketDist + diagLen, cx + bracketDist, cy + bracketDist)
    surface.DrawLine(cx - bracketDist - diagLen, cy + bracketDist + diagLen, cx - bracketDist, cy + bracketDist)

    -- Core crosshair lines
    local coreGap = coreRadius + 3
    local coreLen = 8 + fireExpand * 0.3

    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, alpha)
    -- Horizontal
    surface.DrawRect(cx - coreGap - coreLen, cy - 1, coreLen, 2)
    surface.DrawRect(cx + coreGap, cy - 1, coreLen, 2)
    -- Vertical
    surface.DrawRect(cx - 1, cy - coreGap - coreLen, 2, coreLen)
    surface.DrawRect(cx - 1, cy + coreGap, 2, coreLen)

    -- Center dot with pulse
    local dotSize = 3 + pulse * 1
    local dotAlpha = alpha * (0.8 + pulse * 0.2)
    surface.SetDrawColor(THEME.SECONDARY.r, THEME.SECONDARY.g, THEME.SECONDARY.b, dotAlpha)
    surface.DrawRect(cx - dotSize / 2, cy - dotSize / 2, dotSize, dotSize)

    -- Spread indicator arcs (show accuracy)
    if spread > 0.02 then
        local spreadAlpha = math.Clamp((spread - 0.02) * 10, 0, 1) * alpha * 0.6
        local spreadColor = spread > 0.04 and THEME.WARNING or THEME.PRIMARY
        surface.SetDrawColor(spreadColor.r, spreadColor.g, spreadColor.b, spreadAlpha)

        -- Draw small arc segments at cardinal directions
        for i = 0, 3 do
            local baseAngle = i * math.pi / 2 - math.pi / 2
            DrawCircleArc(cx, cy, innerRadius - 5, 4, baseAngle - 0.2, baseAngle + 0.2)
        end
    end
end

--------------------------------------------------------------------------------
-- HUD PANEL RENDERING
--------------------------------------------------------------------------------

--[[
    Draw the weapon status HUD panel
    @param bobOffsetX - Horizontal bob/sway offset
    @param bobOffsetY - Vertical bob/sway offset
]]
function SWEP:DrawSciFiHUD(bobOffsetX, bobOffsetY)
    EnsureFonts()

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Default offsets if not provided
    bobOffsetX = bobOffsetX or 0
    bobOffsetY = bobOffsetY or 0

    local sw, sh = ScrW(), ScrH()
    local clip = self:Clip1()
    local maxClip = self.Primary.ClipSize
    local reserve = owner:GetAmmoCount(self.Primary.Ammo)
    local spread = self:GetCurrentSpread()
    local adsLerp = self.IronsightLerp or 0
    local ct = CurTime()
    local ft = FrameTime()

    -- Fire detection for pulse effect
    if clip < HUD_STATE.lastClip then
        HUD_STATE.firePulse = 1
    end
    HUD_STATE.lastClip = clip

    -- Panel position (bottom right) with bob/sway offset applied
    local panelW, panelH = 180, 100
    local panelX = sw - panelW - 30 + bobOffsetX
    local panelY = sh - panelH - 30 + bobOffsetY
    local panelAlpha = 200 * (1 - adsLerp * 0.3)

    -- Background panel with tech border
    surface.SetDrawColor(THEME.BACKGROUND.r, THEME.BACKGROUND.g, THEME.BACKGROUND.b, panelAlpha * 0.7)
    surface.DrawRect(panelX, panelY, panelW, panelH)

    -- Border lines
    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, panelAlpha * 0.8)
    -- Top border with notch
    surface.DrawRect(panelX, panelY, 40, 2)
    surface.DrawRect(panelX + 50, panelY, panelW - 50, 2)
    -- Bottom border
    surface.DrawRect(panelX, panelY + panelH - 2, panelW, 2)
    -- Left border
    surface.DrawRect(panelX, panelY, 2, panelH)
    -- Right border with gap
    surface.DrawRect(panelX + panelW - 2, panelY, 2, 30)
    surface.DrawRect(panelX + panelW - 2, panelY + 40, 2, panelH - 40)

    -- Corner accents
    surface.SetDrawColor(THEME.SECONDARY.r, THEME.SECONDARY.g, THEME.SECONDARY.b, panelAlpha)
    surface.DrawRect(panelX, panelY, 10, 2)
    surface.DrawRect(panelX, panelY, 2, 10)
    surface.DrawRect(panelX + panelW - 10, panelY + panelH - 2, 10, 2)
    surface.DrawRect(panelX + panelW - 2, panelY + panelH - 10, 2, 10)

    -- Ammo display
    local ammoX = panelX + 15
    local ammoY = panelY + 15

    -- Determine ammo color based on remaining rounds
    local ammoRatio = clip / maxClip
    local ammoColor = THEME.TEXT
    if ammoRatio <= 0.2 then
        ammoColor = THEME.CRITICAL
        -- Blink effect when critical
        if math.floor(ct * 4) % 2 == 0 then
            ammoColor = Color(THEME.CRITICAL.r, THEME.CRITICAL.g, THEME.CRITICAL.b, 100)
        end
    elseif ammoRatio <= 0.4 then
        ammoColor = THEME.WARNING
    end

    -- Main ammo count
    surface.SetFont("MH_SciFi_Large")
    surface.SetTextColor(ammoColor.r, ammoColor.g, ammoColor.b, panelAlpha)
    surface.SetTextPos(ammoX, ammoY)
    surface.DrawText(string.format("%02d", clip))

    -- Separator
    local sepX = ammoX + 55
    surface.SetDrawColor(THEME.TEXT_DIM.r, THEME.TEXT_DIM.g, THEME.TEXT_DIM.b, panelAlpha * 0.5)
    surface.DrawRect(sepX, ammoY + 5, 1, 25)

    -- Reserve ammo
    surface.SetFont("MH_SciFi_Medium")
    surface.SetTextColor(THEME.TEXT_DIM.r, THEME.TEXT_DIM.g, THEME.TEXT_DIM.b, panelAlpha)
    surface.SetTextPos(sepX + 8, ammoY + 8)
    surface.DrawText(string.format("%03d", reserve))

    -- Ammo type label
    surface.SetFont("MH_SciFi_Small")
    surface.SetTextColor(THEME.TEXT_DIM.r, THEME.TEXT_DIM.g, THEME.TEXT_DIM.b, panelAlpha * 0.7)
    surface.SetTextPos(ammoX, ammoY + 40)
    surface.DrawText(string.upper(self.Primary.Ammo or "AMMO"))

    -- Magazine capacity bar
    local barX = ammoX
    local barY = panelY + panelH - 25
    local barW = panelW - 30
    local barH = 6

    -- Bar background
    surface.SetDrawColor(THEME.BACKGROUND.r, THEME.BACKGROUND.g, THEME.BACKGROUND.b, panelAlpha)
    surface.DrawRect(barX, barY, barW, barH)

    -- Bar fill
    local fillW = barW * ammoRatio
    local barColor = ammoRatio > 0.4 and THEME.PRIMARY or (ammoRatio > 0.2 and THEME.WARNING or THEME.CRITICAL)
    surface.SetDrawColor(barColor.r, barColor.g, barColor.b, panelAlpha * 0.8)
    surface.DrawRect(barX, barY, fillW, barH)

    -- Bar segments (tick marks)
    surface.SetDrawColor(THEME.BACKGROUND.r, THEME.BACKGROUND.g, THEME.BACKGROUND.b, panelAlpha)
    for i = 1, maxClip - 1 do
        local tickX = barX + (barW / maxClip) * i
        surface.DrawRect(tickX, barY, 1, barH)
    end

    -- Bar border
    surface.SetDrawColor(THEME.PRIMARY.r, THEME.PRIMARY.g, THEME.PRIMARY.b, panelAlpha * 0.5)
    surface.DrawOutlinedRect(barX, barY, barW, barH, 1)

    -- Weapon mode indicator (top right of panel)
    local modeX = panelX + panelW - 50
    local modeY = panelY + 10

    surface.SetFont("MH_SciFi_Small")
    if self.InIronsights then
        surface.SetTextColor(THEME.SECONDARY.r, THEME.SECONDARY.g, THEME.SECONDARY.b, panelAlpha)
        surface.SetTextPos(modeX, modeY)
        surface.DrawText("◎ ADS")
    else
        surface.SetTextColor(THEME.TEXT_DIM.r, THEME.TEXT_DIM.g, THEME.TEXT_DIM.b, panelAlpha * 0.7)
        surface.SetTextPos(modeX, modeY)
        surface.DrawText("○ HIP")
    end

    -- Spread/accuracy indicator (small arc or bar)
    local spreadRatio = math.Clamp(spread / 0.06, 0, 1)
    local spreadX = panelX + panelW - 50
    local spreadY = panelY + 55
    local spreadBarW = 40
    local spreadBarH = 4

    surface.SetFont("MH_SciFi_Small")
    surface.SetTextColor(THEME.TEXT_DIM.r, THEME.TEXT_DIM.g, THEME.TEXT_DIM.b, panelAlpha * 0.7)
    surface.SetTextPos(spreadX, spreadY - 12)
    surface.DrawText("SPREAD")

    -- Spread bar bg
    surface.SetDrawColor(THEME.BACKGROUND.r, THEME.BACKGROUND.g, THEME.BACKGROUND.b, panelAlpha)
    surface.DrawRect(spreadX, spreadY, spreadBarW, spreadBarH)

    -- Spread bar fill
    local spreadColor = spreadRatio < 0.5 and THEME.SECONDARY or (spreadRatio < 0.8 and THEME.WARNING or THEME.CRITICAL)
    surface.SetDrawColor(spreadColor.r, spreadColor.g, spreadColor.b, panelAlpha * 0.8)
    surface.DrawRect(spreadX, spreadY, spreadBarW * spreadRatio, spreadBarH)

    -- Scanline effect (subtle)
    HUD_STATE.scanlineOffset = (HUD_STATE.scanlineOffset + ft * 50) % 4
    surface.SetDrawColor(0, 0, 0, 20)
    for scanY = panelY + HUD_STATE.scanlineOffset, panelY + panelH, 4 do
        surface.DrawRect(panelX, scanY, panelW, 1)
    end
end

--------------------------------------------------------------------------------
-- HUD HOOKS
--------------------------------------------------------------------------------

--[[
    Draw weapon crosshair
]]
function SWEP:DoDrawCrosshair(x, y)
    -- Hide crosshair when fully ADS
    local adsLerp = self.IronsightLerp or 0
    if adsLerp > 0.9 then return true end

    local owner = self:GetOwner()
    if not IsValid(owner) then return true end

    -- Calculate bob/sway offset
    local bobX, bobY = CalcHUDBobSway(owner, adsLerp)

    -- Apply offset to screen center for reticle
    local cx = ScrW() / 2 + bobX
    local cy = ScrH() / 2 + bobY
    local spread = self:GetCurrentSpread()

    -- Draw sci-fi reticle with bob/sway
    self:DrawSciFiReticle(cx, cy, adsLerp, spread)

    return true
end

--[[
    Draw custom HUD elements
]]
function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local adsLerp = self.IronsightLerp or 0

    -- Calculate bob/sway offset (shared state from DoDrawCrosshair)
    local bobX, bobY = CalcHUDBobSway(owner, adsLerp)

    -- Draw sci-fi weapon HUD with bob/sway
    self:DrawSciFiHUD(bobX, bobY)
end

--------------------------------------------------------------------------------
-- VIEW EFFECTS
--------------------------------------------------------------------------------

--[[
    Calculate view bob
]]
function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
    if not IsValid(self:GetOwner()) then return pos, ang end

    -- Let GetViewModelPosition handle the heavy lifting
    return self:GetViewModelPosition(pos, ang)
end

--[[
    Modify player view (recoil recovery, etc.)
]]
function SWEP:CalcView(ply, origin, angles, fov)
    -- Smooth recoil recovery could be added here
    return origin, angles, fov
end

--------------------------------------------------------------------------------
-- EFFECTS
--------------------------------------------------------------------------------

--[[
    Fire effects (muzzle flash, shell ejection)
]]
function SWEP:FireAnimationEvent(pos, ang, event, options)
    -- Muzzle flash
    if event == 21 or event == 5001 then
        local effectData = EffectData()
        effectData:SetEntity(self)
        effectData:SetAttachment(1)
        effectData:SetScale(0.8)
        util.Effect("MuzzleEffect", effectData)

        -- Dynamic light
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 180
            dlight.b = 80
            dlight.brightness = 2
            dlight.decay = 1000
            dlight.size = 128
            dlight.dietime = CurTime() + 0.05
        end

        return true
    end

    -- Shell ejection
    if event == 20 or event == 5002 then
        local effectData = EffectData()
        effectData:SetEntity(self)
        effectData:SetAttachment(2)
        util.Effect("ShellEject", effectData)
        return true
    end
end

--------------------------------------------------------------------------------
-- SCREEN EFFECTS
--------------------------------------------------------------------------------

--[[
    Apply screen blur when ADS (optional)
]]
function SWEP:RenderScreen()
    -- Could add depth of field blur here when ADS
end

--------------------------------------------------------------------------------
-- HOOKS
--------------------------------------------------------------------------------

--[[
    Handle ADS exit when sprinting
]]
function SWEP:StartCommand(cmd)
    -- Exit ironsights when sprinting
    if self.InIronsights and cmd:KeyDown(IN_SPEED) then
        self.InIronsights = false
        self:SetNWBool("Ironsights", false)
    end
end

--[[
    Adjust third-person holdtype
]]
function SWEP:GetHoldType()
    if self.InIronsights then
        return "revolver" -- More aimed stance
    end
    return self.HoldType
end

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

--[[
    Get ironsight state (for external use)
]]
function SWEP:IsInIronsights()
    return self.InIronsights or self:GetNWBool("Ironsights", false)
end

--[[
    Get spread for HUD display
]]
function SWEP:GetSpreadPercent()
    local base = self.Ballistics.Spread
    local current = self:GetCurrentSpread()
    return math.Clamp(current / (base * 4), 0, 1)
end

