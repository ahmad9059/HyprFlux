# HyprFlux Modular System

## Overview

HyprFlux has been refactored into a modular architecture that provides better maintainability, flexibility, and user control while maintaining full backward compatibility.

## Architecture

### Directory Structure

```
HyprFlux/
├── install.sh                 # Main entry point (backward compatible)
├── dotsSetup.sh              # Dotfiles setup (backward compatible)
├── install_modular.sh        # New modular installer
├── dotsSetup_modular.sh      # New modular setup script
├── module_manager.sh         # Interactive module manager
├── lib/                      # Shared libraries
│   ├── colors.sh            # Color definitions
│   ├── utils.sh             # Utility functions
│   └── config.sh            # Configuration variables
├── config/                   # Configuration files
│   ├── packages.conf        # Package lists
│   └── webapps.conf         # Web application definitions
└── modules/                  # Modular components
    ├── core/                # Core functionality
    │   ├── logging.sh       # Logging setup
    │   ├── backup.sh        # Configuration backup
    │   ├── packages.sh      # Package management
    │   └── dotfiles.sh      # Dotfiles management
    ├── apps/                # Application setup
    │   ├── neovim.sh        # Neovim configuration
    │   ├── tmux.sh          # Tmux setup
    │   ├── webapps.sh       # Web applications
    │   └── shell.sh         # Shell refinements
    ├── themes/              # Theme management
    │   ├── gtk.sh           # GTK themes
    │   ├── icons.sh         # Icon themes
    │   ├── cursors.sh       # Cursor themes
    │   └── wallpapers.sh    # Wallpaper setup
    ├── system/              # System configuration
    │   ├── waybar.sh        # Waybar setup
    │   ├── sddm.sh          # SDDM theme
    │   └── quickshell.sh    # QuickShell config
    └── boot/                # Boot configuration
        ├── grub.sh          # GRUB theme
        └── plymouth.sh      # Plymouth setup
```

## Usage

### 1. Standard Installation (Backward Compatible)

```bash
# Same as before - automatically uses modular system if available
bash install.sh
bash dotsSetup.sh
```

### 2. Interactive Module Manager

```bash
# Launch interactive module manager
bash module_manager.sh

# Or use specific commands
bash module_manager.sh --list                    # List all modules
bash module_manager.sh --category core           # List core modules
bash module_manager.sh --run core/packages       # Run specific module
```

### 3. Direct Module Execution

```bash
# Run specific modules directly
bash dotsSetup_modular.sh                        # Full modular setup
bash modules/core/packages.sh                    # Individual module
```

## Module Categories

### Core Modules (Always Required)

- **logging.sh**: Setup logging system
- **backup.sh**: Backup existing configurations
- **packages.sh**: Install required packages
- **dotfiles.sh**: Copy dotfiles and configurations

### Application Modules

- **neovim.sh**: Neovim editor setup with plugins
- **tmux.sh**: Terminal multiplexer configuration
- **webapps.sh**: Progressive Web App creation
- **shell.sh**: Shell refinements and tweaks

### Theme Modules

- **gtk.sh**: GTK theme installation and configuration
- **icons.sh**: Icon theme setup (Papirus)
- **cursors.sh**: Cursor theme installation
- **wallpapers.sh**: Wallpaper repository setup

### System Modules

- **waybar.sh**: Status bar configuration
- **sddm.sh**: Login manager theme
- **quickshell.sh**: QuickShell desktop configuration

### Boot Modules

- **grub.sh**: GRUB bootloader theme
- **plymouth.sh**: Boot splash screen setup

## Benefits

### 1. Maintainability

- Each module handles a single responsibility
- Easier to debug and update individual components
- Clear separation of concerns

### 2. Flexibility

- Run only the modules you need
- Skip modules that aren't relevant to your setup
- Easy to add new modules or modify existing ones

### 3. Error Isolation

- Issues in one module don't affect others
- Better error handling and recovery
- Detailed logging for troubleshooting

### 4. Customization

- Easy to modify individual modules
- Configuration files separate from logic
- Extensible architecture for new features

### 5. Testing

- Each module can be tested independently
- Easier to validate specific functionality
- Better quality assurance

## Configuration

### Package Lists

Edit `config/packages.conf` to modify package installations:

- `REQUIRED_PACKAGES`: Always installed
- `PACMAN_PACKAGES`: Optional pacman packages
- `YAY_PACKAGES`: Optional AUR packages

### Web Applications

Edit `config/webapps.conf` to add/remove web applications:

```bash
# Format: "Name|URL|IconName"
"MyApp|https://myapp.com|myapp"
```

### Paths and Settings

Modify `lib/config.sh` to change default paths and settings.

## Backward Compatibility

The modular system is fully backward compatible:

- Existing `install.sh` and `dotsSetup.sh` work unchanged
- Automatically detects and uses modular system if available
- Falls back to legacy system if modular components are missing
- Same external interface and behavior

## Development

### Adding New Modules

1. Create module file in appropriate category:

```bash
# modules/category/mymodule.sh
#!/bin/bash

setup_mymodule() {
  print_section "Setting up My Module"

  echo -e "${ACTION} Doing something...${RESET}"

  # Your implementation here

  echo -e "${OK} My module setup completed.${RESET}"
  log_message "INFO" "My module setup completed"
  return 0
}
```

2. Add module to main setup script:

```bash
# In dotsSetup_modular.sh
load_module "$SCRIPT_DIR/modules/category/mymodule.sh"
execute_module "setup_mymodule" "My Module Description"
```

### Module Guidelines

- Use consistent function naming: `setup_<module_name>`
- Include proper error handling and logging
- Use shared utilities from `lib/utils.sh`
- Follow the established color coding system
- Include descriptive messages for user feedback
- Return appropriate exit codes (0 for success, 1 for failure)

## Troubleshooting

### Check Module Status

```bash
# List all available modules
bash module_manager.sh --list

# Run specific module for testing
bash module_manager.sh --run core/packages
```

### Logs

- Main log: `~/hyprflux_log/dotsSetup.log`
- Each module logs its activities
- Use `log_message` function for consistent logging

### Common Issues

1. **Module not found**: Check file path and permissions
2. **Function not found**: Verify function name matches module
3. **Permission denied**: Ensure sudo access is available
4. **Network issues**: Check internet connectivity for downloads

## Migration from Legacy

The modular system is automatically used when available. No migration is needed - your existing workflow continues to work while gaining the benefits of the modular architecture.

## Contributing

When contributing to HyprFlux:

1. Follow the modular architecture
2. Add new functionality as separate modules
3. Update configuration files instead of hardcoding values
4. Include proper error handling and logging
5. Test modules independently
6. Maintain backward compatibility
