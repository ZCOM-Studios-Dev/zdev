# ZDEV
 Core Addon for ZCOM Development Suite Addon Pack
# ZDEV Core Addon

![ZCOM Studios](zdev/logo_zcom_studios.png)

**ZCOM Development Master Addon** - The core foundation for all ZCOM Studios addons and gamemodes in Garry's Mod.

[![License: GPL v3](https:--img.shields.io/badge/License-GPLv3-blue.svg)](https:--www.gnu.org/licenses/gpl-3.0)
![Version](https:--img.shields.io/badge/Version-0.7.2-green.svg)
![Garry's Mod](https:--img.shields.io/badge/Garry's%20Mod-Compatible-orange.svg)

## Overview

ZDEV is a comprehensive development addon for Garry's Mod that serves as the primary dependency for all other addons and gamemodes released by ZCOM Studios. It provides a robust foundation with development tools, utilities, and frameworks to enhance the modding experience.

## Features

### Core Systems
- **Animation Framework** - Advanced bone animation library with motion capture support
- **Development Tools** - Comprehensive suite of in-game development utilities
- **Database Integration** - MySQL database support with secure connection handling
- **Custom HUD System** - Extensible heads-up display framework
- **VGUI Framework** - Advanced menu and interface system
- **Effect System** - Particle and visual effects management
- **Entity Extensions** - Enhanced entity, player, and weapon meta functions

### Development Tools
- **Admin Panel** - Server administration interface
- **Material Editor** - In-game material and texture tools
- **Particle Editor** - Visual particle effect creation system
- **Environment Tools** - Map and environment manipulation utilities
- **Font Manager** - Custom font integration and management
- **Weapon Testing** - Comprehensive weapon development suite
- **NPC Tools** - Non-player character development utilities

### Developer Features
- **File Management System** - Automated resource tracking and loading
- **Debug Console** - Advanced debugging and logging capabilities
- **Network Utilities** - Streamlined client-server communication
- **Hook System** - Organized event handling framework
- **Utility Libraries** - Common functions and helpers

## Installation

### Prerequisites
- **Garry's Mod** - Latest version required
- **Source Engine** - Steam installation
- **Server Access** - For server-side features (optional)

### Installation Steps

1. **Download the Addon**
   ```bash
   # Clone the repository
   git clone https:--github.com/zcomstudios/zdev_core.git
   ```

2. **Steam Workshop Installation** (Recommended)
   - Subscribe to the addon on Steam Workshop
   - The addon will automatically download and install

3. **Manual Installation**
   - Download the `zdev` folder
   - Place it in your Garry's Mod addons directory:
     ```
     steamapps/common/GarrysMod/garrysmod/addons/zdev_core/
     ```

4. **Server Installation**
   - Upload the addon to your server's addons directory
   - Restart the server or change the map to load the addon

## Usage

### Basic Setup

Once installed, ZDEV will automatically initialize when Garry's Mod starts. The addon provides various in-game menus and tools accessible through:

- **Admin Menu** - Access administrative functions
- **Developer Console** - Use ZDEV commands and utilities
- **VGUI Menus** - Interactive development interfaces

### Console Commands

```lua
-- Enable debug mode
zdev_debug 1

-- Access developer tools
zdev_menu_dev

-- Reload ZDEV components
zdev_reload
```

### Configuration

ZDEV can be configured through ConVars and configuration files:

```lua
-- Example configuration
zdev_database_enable 1      -- Enable database features
zdev_debug_level 2          -- Set debug verbosity
zdev_hud_enabled 1          -- Enable custom HUD elements
```

## Development

### Building Dependencies

This addon requires other ZCOM Studios addons for full functionality:

- ZCOM Core Libraries
- ZCOM Animation System
- ZCOM Database Module

### File Structure

```
zdev/
├── addon.json              # Addon metadata
├── info.txt                # Addon information
├── LICENSE                 # GPL v3 License
├── lua/                    # Lua source code
│   ├── autorun/            # Auto-loading scripts
│   ├── zdev/               # Core ZDEV files
│   ├── anim/               # Animation system
│   ├── entities/           # Custom entities
│   ├── effects/            # Effect definitions
│   └── weapons/            # Weapon definitions
├── materials/              # Textures and materials
└── resource/               # Fonts and resources
```

### API Reference

#### Core Functions

```lua
-- Initialize ZDEV
ZDEV.Initialize()

-- Log messages
zdev.log(tag, message)

-- File management
ZDEV.FILE.Loaded(filename)
ZDEV.FILE.SetLoaded(filename)
```

#### Development Tools

```lua
-- Access development menus
zdev.OpenDevMenu()
zdev.OpenAdminPanel()

-- Database operations
ZDEV.Database.Connect()
ZDEV.Database.Query(sql, callback)
```

### Contributing

We welcome contributions to ZDEV! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate documentation
4. Test thoroughly in Garry's Mod
5. Submit a pull request

#### Code Style
- Follow Lua naming conventions
- Use meaningful variable names
- Comment complex functionality
- Maintain compatibility with existing systems

## Credits

### Development Team
- **Adrian 'ZCOM' L.** - Lead Developer
- **ZCOM Studios** - Development Studio

### Third-Party Components
- **LuaAnimations API Library** - By William "JetBoom" Moohde
- **tmysqloo** - MySQL library integration
- **Splinter-Cell Models & Textures** - Ubisoft (Fair Use)

### Special Thanks
- The Garry's Mod community
- Contributors and testers
- ZCOM Studios supporters

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](zdev/LICENSE) file for details.

```
ZDEV Core Addon
Copyright (C) 2020 ZCOM Studios

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

## Support

### Getting Help
- **Documentation** - Check this README and in-game help
- **Issues** - Report bugs on GitHub Issues
- **Community** - Join our Discord server
- **Email** - zcomstudios@gmail.com

### Links
- **Website** - [https:--zcomstudios.com](https:--zcomstudios.com)
- **Steam Workshop** - [Subscribe to ZDEV](https:--steamcommunity.com/sharedfiles/filedetails/?id=YOUR_WORKSHOP_ID)
- **GitHub** - [ZCOM Studios](https:--github.com/zcomstudios)

## Version History

### v0.7.2 (Current)
- Enhanced development tools
- Improved database integration
- Bug fixes and optimizations

### v0.7.0
- Initial public release
- Core framework implementation
- Basic development tools

---

**Made with ❤️ by ZCOM Studios**

*ZDEV is not affiliated with Facepunch Studios or Valve Corporation. Garry's Mod is a trademark of Facepunch Studios.*