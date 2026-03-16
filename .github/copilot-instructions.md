# ZDEV - AI Coding Agent Instructions

ZDEV is a Garry's Mod Lua addon providing core development tools and systems for ZCOM Studios addons. No build system—code runs directly in-game via Garry's Mod's Lua VM.

## Critical Architecture Patterns

### Execution Context Separation
Files follow strict client/server separation:
- **`cl_*.lua`** - Client-only (UI, HUD, rendering, effects)
- **`sv_*.lua`** - Server-only (database, player management, entity logic)
- **`sh_*.lua`** - Shared (both realms, utilities, enums, entity definitions)

Server must explicitly send client files using `AddCSLuaFile("path/to/file.lua")` in `init.lua` (see `lua/zdev/init.lua` for pattern). Entities have three files: `init.lua` (server), `cl_init.lua` (client), `shared.lua` (both).

### Mandatory File Loading Pattern
Every file MUST start with this pattern to prevent duplicate loading:
```lua
local _f = 'relative/path/to/file.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end
-- ... file contents ...
ZDEV.FILE.SetLoaded( _f )
```

### Global Namespace Organization
- **`ZDEV`** - Primary namespace for all systems (`ZDEV.UTIL`, `ZDEV.VGUI`, `ZDEV.EDIT`, etc.)
- **`ZD`** - Hook table for game event handlers
- **`ZDEV_ADDONS`** - Registry for addon dependencies

All new functionality MUST be added under `ZDEV.*` subtables. Never pollute global scope.

### Catalog System & Function UIDs
Functions are tracked with unique IDs via special comments:
```lua
-- ZDEV_UID: ZDEV_FUNC_AF202117 | Path: ZDEV.CONT.LoadMaterials
function ZDEV.CONT.LoadMaterials( subdir )
```
When adding new `ZDEV.*` functions, run `zdev_inject_uids` (server console) to generate UIDs automatically. Catalog is maintained in `zdev_table_catalog.json`.

## Networking & Communication

### Network String Registration
Server MUST register all network strings in `lua/zdev/init.lua`:
```lua
util.AddNetworkString( "zdev_hud_msg_send" )
```

Client receives with `net.Receive("zdev_hud_msg_send", function() ... end)`. Server sends with `net.Start("name")`, `net.Send(player)`. See `lua/zdev/client/hud/zd_cl_hud_msg.lua` for examples.

### Hook Naming Convention
Hooks use namespace-qualified names: `"ZDEV.CHUD.DrawMessages"`, `"ZDEV.PLYR.InitialSpawn"`. Example:
```lua
hook.Add( "HUDPaint", "ZDEV.CHUD.DrawMessages", ZDEV.CHUD.DrawMessages )
```

## Development Workflow

### Testing & Debugging
- **No build step** - Edit files, then reload in-game
- **In-game console commands**: `zdev_debug 1`, `zdev_reload`, `zdev_menu_dev`
- **Logging**: Use `zdev.log(tag, message)` or `MsgC(Color(...), text)` for colored output
- **File tracking**: Check `ZDEV.FILE.INDEX` for loaded files

### Console Commands (Server)
```
zdev_catalog_generate      # Update function catalog
zdev_inject_uids           # Add UID comments to functions
zdev_maintenance_check     # Verify catalog integrity
```

### Key Directories
- `lua/autorun/` - Auto-executed on game start (loads core systems)
- `lua/zdev/` - Core addon logic (client/, server/, shared/ subdirs)
- `lua/entities/` - Custom entities (each in own folder with init.lua/cl_init.lua/shared.lua)
- `lua/weapons/` - Custom weapons (single files with SWEP structure)
- `materials/` - Textures (loaded via `Material()` or `ZDEV.CONT.LoadMaterials()`)

## Common Patterns & Anti-Patterns

### ✅ Correct Entity Definition
```lua
-- entities/myent/init.lua (server)
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:Initialize()
    self:SetModel("models/props_c17/oildrumchunk01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
end
```

### ✅ Correct HUD Drawing (Client)
```lua
-- CLIENT realm only
local function DrawCustomHUD()
    if not (LocalPlayer() and LocalPlayer():Alive()) then return end
    draw.SimpleText("Text", "Font", x, y, Color(255,255,255))
end
hook.Add("HUDPaint", "MyAddon.DrawHUD", DrawCustomHUD)
```

### ❌ Never Mix Realms
```lua
-- WRONG: LocalPlayer() doesn't exist on server
function ENT:Initialize()  -- Server function
    local ply = LocalPlayer()  -- CRASH! Client-only function
end
```

### ❌ Never Hardcode Paths
```lua
-- WRONG
include("C:/Users/me/Desktop/file.lua")

-- CORRECT - Use relative paths
include("zdev/shared/meta/zd_sh_meta_ent.lua")
```

## HUD & UI Specifics

HUD messages use typed system (see `lua/zdev/client/hud/zd_cl_hud_msg.lua`):
- `HUDMSG_INFO`, `HUDMSG_WARN`, `HUDMSG_ERROR` - Standard messages
- `HUDMSG_ANNOUNCE` - Center screen announcements
- `HUDMSG_MARKER` - World position markers attached to entities
- `HUDMSG_WORLD` - World position markers at Vector coordinates

ConVars control HUD colors: `zd_hud_clr_pri`, `zd_hud_clr_sec` (use `CONV_HUD_CLR_PRI()` helper).

## Data Persistence

Files stored in `garrysmod/data/zdev/` using GMod's `file.*` API:
```lua
file.Write("zdev/config.txt", data)  -- Writes to data/zdev/config.txt
local content = file.Read("zdev/config.txt", "DATA")
```
MySQL integration via `ZDEV.MSQL.*` (optional MySQLoo module dependency).

## External Dependencies

- **Garry's Mod** - Source Engine Lua API (entities, hooks, networking, rendering)
- **MySQLoo** (optional) - Database connectivity
- **Neural network module** - Custom C++ module at `includes/modules/neural_network.lua`

ZDEV itself is a dependency for other ZCOM addons—avoid adding new addon dependencies.

## Key Files for Reference

- `lua/autorun/zd_autorun.lua` - Initialization, global table setup, addon registration
- `lua/zdev/shared.lua` - File management, material loading, shared utilities
- `lua/zdev/init.lua` (server) / `lua/zdev/cl_init.lua` (client) - Realm-specific bootstrapping
- `lua/entities/zdev_grenade_base/` - Example of complete entity with all three files
- `CLAUDE.md` - Existing developer documentation (commands, structure overview)
