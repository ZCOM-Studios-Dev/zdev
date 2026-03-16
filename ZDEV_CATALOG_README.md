# ZDEV Table Catalog System

This document describes the ZDEV table cataloging system that indexes and maintains all contents of the global "ZDEV" table.

## Overview

The ZDEV catalog system automatically:

1. **Scans** all ZDEV functions and tables across the codebase
2. **Generates unique IDs** (UIDs) for each function and table
3. **Adds UID comments** above each function definition
4. **Maintains a JSON catalog** with all ZDEV table contents
5. **Keeps the catalog up-to-date** through automatic monitoring

## Components

### 1. Catalog Generator (`zdev_catalog_generator.lua`)

- Recursively scans the ZDEV table structure
- Generates unique 8-character hexadecimal UIDs for each function/table
- Creates a comprehensive JSON catalog with metadata
- Provides console commands for manual catalog generation

**Key Functions:**
- `ZDEV.CATALOG.Generate()` - Generates complete catalog
- `ZDEV.CATALOG.SaveToFile()` - Saves catalog to JSON
- `ZDEV.CATALOG.LoadFromFile()` - Loads existing catalog
- `ZDEV.CATALOG.AutoUpdate()` - Updates catalog if needed

### 2. UID Injector (`zdev_uid_injector.lua`)

- Adds UID comments above ZDEV function definitions
- Updates existing comments with new UIDs when needed
- Processes all Lua files in the ZDEV addon
- Creates processed files in `data/zdev/processed/` directory

**Key Functions:**
- `ZDEV.UID_INJECTOR.ProcessFile()` - Process single file
- `ZDEV.UID_INJECTOR.ProcessAllFiles()` - Process all ZDEV files

### 3. Maintenance System (`zdev_catalog_maintenance.lua`)

- Monitors file changes and automatically updates catalog
- Runs periodic checks for modifications
- Provides console commands for manual maintenance
- Ensures catalog stays synchronized with code changes

**Key Functions:**
- `ZDEV.MAINTENANCE.Check()` - Perform maintenance check
- `ZDEV.MAINTENANCE.ScanForChanges()` - Scan for file modifications

## Usage

### Automatic Operation

The system runs automatically when the addon loads:

1. **Initial Scan**: Generates catalog 5 seconds after addon load
2. **Periodic Checks**: Monitors for changes every 60 seconds
3. **Auto-Update**: Regenerates catalog when changes detected

### Manual Commands (Server Console)

```lua
-- Generate catalog manually
zdev_catalog_generate

-- Inject UIDs into source files
zdev_inject_uids

-- Run maintenance check
zdev_maintenance_check

-- Toggle auto-maintenance
zdev_maintenance_toggle

-- Show catalog information
zdev_catalog_info
```

## Catalog Format

The JSON catalog contains:

```json
{
  "version": "1.0.0",
  "generated": "2025-08-13T08:29:42.087825",
  "datetime": "2025-08-13 08:29:42",
  "stats": {
    "totalFunctions": 180,
    "totalTables": 77,
    "scanPath": "/path/to/zdev"
  },
  "functions": {
    "ZDEV.FUNCTION.Path": {
      "uid": "ZDEV_FUNC_ABCD1234",
      "path": "ZDEV.FUNCTION.Path",
      "file": "/path/to/file.lua",
      "line": 42,
      "type": "function"
    }
  },
  "tables": {
    "ZDEV.TABLE.Path": {
      "uid": "ZDEV_TBL_EFGH5678",
      "path": "ZDEV.TABLE.Path",
      "file": "/path/to/file.lua", 
      "line": 15,
      "type": "table"
    }
  }
}
```

## UID Comments

Each ZDEV function gets a comment above its definition:

```lua
-- ZDEV_UID: ZDEV_FUNC_ABCD1234 | Path: ZDEV.FUNCTION.Path
function ZDEV.FUNCTION.Path(args)
    -- Function implementation
end
```

## File Locations

- **Catalog JSON**: `zdev_table_catalog.json` (in addon root)
- **Latest Catalog**: `data/zdev/zdev_catalog_latest.json`
- **Processed Files**: `data/zdev/processed/` (with UID comments)
- **Backup Files**: `*.backup` (created before modifying source)

## Statistics

Current ZDEV table contains:
- **180 functions** across 35+ files
- **77 tables** with nested structures
- **Comprehensive coverage** of all ZDEV namespaces

## Benefits

1. **Documentation**: Complete index of all ZDEV functionality
2. **Tracking**: Unique identifiers for every function
3. **Maintenance**: Automated catalog updates
4. **Integration**: Easy API discovery and reference
5. **Debugging**: Quick function location and identification

## Integration with Development Workflow

The catalog system integrates seamlessly with ZDEV development:

1. **Add new functions** - Automatically cataloged on next scan
2. **Modify existing functions** - UIDs preserved, catalog updated
3. **Remove functions** - Catalog reflects current state
4. **File reorganization** - Tracked through file paths and line numbers

This system ensures that the ZDEV table documentation stays current and provides a comprehensive reference for all ZCOM Studios addon development.