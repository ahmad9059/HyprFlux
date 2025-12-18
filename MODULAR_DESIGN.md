# HyprFlux Modular Design Proposal

## Architecture Overview

### Current State

- **install.sh**: Entry point (handles Arch-Hyprland + HyprFlux)
- **dotsSetup.sh**: Monolithic script (~877 lines) handling all configurations
- **modules/**: Empty directory structure

### Proposed Modular Structure

```
HyprFlux/
├── install.sh                 # Main entry point (refactored)
├── dotsSetup.sh              # Modular orchestrator (refactored)
├── modules/
│   ├── core/
│   │   ├── packages.sh       # Package management
│   │   ├── backup.sh         # Backup functionality
│   │   ├── dotfiles.sh       # Dotfiles copying
│   │   └── logging.sh        # Logging utilities
│   ├── apps/
│   │   ├── neovim.sh         # Neovim setup
│   │   ├── tmux.sh           # Tmux/Tmuxifier setup
│   │   ├── webapps.sh        # PWA creation
│   │   └── shell.sh          # Zsh/shell configuration
│   ├── themes/
│   │   ├── gtk.sh            # GTK themes
│   │   ├── icons.sh          # Icon themes
│   │   ├── cursors.sh        # Cursor themes
│   │   └── wallpapers.sh     # Wallpaper setup
│   ├── system/
│   │   ├── waybar.sh         # Waybar configuration
│   │   ├── sddm.sh           # SDDM theme setup
│   │   ├── quickshell.sh     # QuickShell configuration
│   │   └── desktop.sh        # Desktop environment setup
│   ├── boot/
│   │   ├── grub.sh           # GRUB theme
│   │   └── plymouth.sh       # Plymouth setup
│   ├── optional/
│   │   ├── pacman_packages.sh    # Optional pacman packages
│   │   └── aur_packages.sh       # Optional AUR packages
│   └── fixes/
│       └── refinements.sh    # System refinements and fixes
├── lib/
│   ├── colors.sh             # Color definitions
│   ├── utils.sh              # Utility functions
│   └── config.sh             # Configuration variables
└── config/
    ├── packages.conf         # Package lists
    ├── paths.conf            # Path definitions
    └── settings.conf         # Default settings
```

## Module Design Principles

### 1. Single Responsibility

Each module handles one specific aspect of the system setup.

### 2. Independence

Modules can be run independently or skipped based on user preferences.

### 3. Shared Libraries

Common functionality (colors, logging, utilities) extracted to shared libraries.

### 4. Configuration-Driven

Settings and package lists moved to configuration files.

### 5. Error Handling

Each module includes proper error handling and rollback capabilities.

## Module Categories

### Core Modules (Always Run)

- **packages.sh**: Required package installation
- **backup.sh**: Backup existing configurations
- **dotfiles.sh**: Copy new dotfiles
- **logging.sh**: Setup logging system

### Application Modules

- **neovim.sh**: Neovim configuration and plugin setup
- **tmux.sh**: Tmux and tmuxifier installation
- **webapps.sh**: Progressive Web App creation
- **shell.sh**: Zsh and Oh My Zsh setup

### Theme Modules

- **gtk.sh**: GTK theme installation and configuration
- **icons.sh**: Icon theme setup (Papirus)
- **cursors.sh**: Cursor theme installation
- **wallpapers.sh**: Wallpaper repository setup

### System Modules

- **waybar.sh**: Waybar configuration and styling
- **sddm.sh**: SDDM theme installation
- **quickshell.sh**: QuickShell configuration
- **desktop.sh**: Desktop environment tweaks

### Boot Modules

- **grub.sh**: GRUB theme installation
- **plymouth.sh**: Plymouth boot screen setup

### Optional Modules

- **pacman_packages.sh**: Optional pacman packages
- **aur_packages.sh**: Optional AUR packages

### Fix Modules

- **refinements.sh**: System refinements and fixes

## Benefits of Modular Design

1. **Maintainability**: Easier to update and debug individual components
2. **Flexibility**: Users can skip modules they don't need
3. **Testability**: Each module can be tested independently
4. **Reusability**: Modules can be reused in other projects
5. **Parallel Execution**: Independent modules can run in parallel
6. **Error Isolation**: Issues in one module don't affect others
7. **Customization**: Easy to add new modules or modify existing ones

## Implementation Strategy

1. **Phase 1**: Extract shared libraries and configuration
2. **Phase 2**: Create core modules (packages, backup, dotfiles)
3. **Phase 3**: Create application and theme modules
4. **Phase 4**: Create system and boot modules
5. **Phase 5**: Create optional modules
6. **Phase 6**: Refactor main scripts to use modular system
7. **Phase 7**: Add module selection interface

## Backward Compatibility

The refactored `dotsSetup.sh` will maintain the same external interface, ensuring existing users can upgrade seamlessly.
