--[[
    ui3d2d.lua
    Lightweight 3D2D UI helper for Garry's Mod
    https:--github.com/zcomstudios/ui3d2d
    Author: ZCOM Studios
]]

-- Usage:
-- ui3d2d.Start(pos, ang, scale)
--   ...draw VGUI or custom UI...
-- ui3d2d.End()

ui3d2d = ui3d2d or {}

function ui3d2d.Start(pos, ang, scale)
    cam.Start3D2D(pos, ang, scale or 1)
end

function ui3d2d.End()
    cam.End3D2D()
end

-- Optionally, add helpers for drawing panels, backgrounds, etc.
function ui3d2d.DrawPanel(x, y, w, h, color)
    draw.RoundedBox(8, x, y, w, h, color or Color(40,40,60,220))
end

-- Example: ui3d2d.DrawText(text, font, x, y, color)
function ui3d2d.DrawText(text, font, x, y, color, alignX, alignY)
    draw.SimpleText(text, font, x, y, color or color_white, alignX or TEXT_ALIGN_LEFT, alignY or TEXT_ALIGN_TOP)
end

-- You can expand this with more helpers as needed.

-- End of ui3d2d.lua
