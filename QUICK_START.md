# HyprFlux Modular System - Quick Start Guide

## Installation

### Full Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/ahmad9059/HyprFlux.git
cd HyprFlux

# Run the installer (automatically uses modular system)
bash install.sh
```

### Dotfiles Only

```bash
# If you already have Hyprland installed
bash dotsSetup.sh
```

## Module Manager

### Interactive Mode

```bash
# Launch interactive menu
bash module_manager.sh
```

### Command Line Usage

```bash
# List all modules
bash module_manager.sh --list

# List modules in a category
bash module_manager.sh --category core
bash module_manager.sh --category themes
bash module_manager.sh --category apps

# Run a specific module
bash module_manager.sh --run core/packages
bash module_manager.sh --run themes/gtk
bash module_manager.sh --run apps/neovim
```

## Common Tasks

### Install Only Themes

```bash
bash module_manager.sh --run themes/gtk
bash module_manager.sh --run themes/icons
bash module_manager.sh --run themes/cursors
bash module_manager.sh --run themes/wallpapers
```

### Setup Applications

```bash
bash module_manager.sh --run apps/neovim
bash module_manager.sh --run apps/tmux
bash module_manager.sh --run apps/webapps
```

### Configure System

```bash
bash module_manager.sh --run system/waybar
bash module_manager.sh --run system/sddm
bash module_manager.sh --run system/quickshell
```

### Setup Boot

```bash
bash module_manager.sh --run boot/grub
bash module_manager.sh --run boot/plymouth
```

## Module Categories

| Category   | Description             | Modules                             |
| ---------- | ----------------------- | ----------------------------------- |
| **core**   | Essential functionality | logging, backup, packages, dotfiles |
| **apps**   | Application setup       | neovim, tmux, webapps, shell        |
| **themes** | Visual customization    | gtk, icons, cursors, wallpapers     |
| **system** | System configuration    | waybar, sddm, quickshell            |
| **boot**   | Boot configuration      | grub, plymouth                      |

## Configuration

### Edit Package Lists

```bash
# Edit package configuration
nano config/packages.conf

# Modify:
# - REQUIRED_PACKAGES (always installed)
# - PACMAN_PACKAGES (optional)
# - YAY_PACKAGES (optional AUR)
```

### Edit Web Applications

```bash
# Edit web app configuration
nano config/webapps.conf

# Add new apps in format:
# "AppName|https://url.com|iconname"
```

### Edit Paths and Settings

```bash
# Edit global configuration
nano lib/config.sh

# Modify paths, URLs, and settings
```

## Logs

```bash
# View main log
tail -f ~/hyprflux_log/dotsSetup.log

# View install log
tail -f ~/hyprflux_log/install.log
```

## Troubleshooting

### Module Failed

```bash
# Re-run specific module
bash module_manager.sh --run category/module

# Check logs
cat ~/hyprflux_log/dotsSetup.log | grep ERROR
```

### Reset Configuration

```bash
# Restore backup
cp -r ~/dotfiles_backup/.config/* ~/.config/
cp ~/dotfiles_backup/.zshrc ~/
cp ~/dotfiles_backup/.tmux.conf ~/
```

### Clean Install

```bash
# Remove existing installation
rm -rf ~/HyprFlux
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar

# Clone and reinstall
git clone https://github.com/ahmad9059/HyprFlux.git
cd HyprFlux
bash install.sh
```

## Tips

1. **Run modules individually** for faster testing and debugging
2. **Check logs** after each module for detailed information
3. **Use interactive mode** to explore available modules
4. **Backup before changes** - automatic backups are created
5. **Test modules** in a VM before applying to main system

## Examples

### Minimal Setup (Core Only)

```bash
bash module_manager.sh --run core/packages
bash module_manager.sh --run core/backup
bash module_manager.sh --run core/dotfiles
```

### Theme Refresh

```bash
bash module_manager.sh --run themes/gtk
bash module_manager.sh --run themes/icons
bash module_manager.sh --run themes/cursors
```

### Application Update

```bash
bash module_manager.sh --run apps/neovim
bash module_manager.sh --run apps/tmux
```

### Full Reinstall

```bash
bash dotsSetup_modular.sh
```

## Help

```bash
# Show help for module manager
bash module_manager.sh --help

# Show help for installer
bash install_modular.sh --help

# Show help for setup script
bash dotsSetup_modular.sh --help
```

## Next Steps

1. Explore modules with `bash module_manager.sh --list`
2. Customize configurations in `config/` directory
3. Run specific modules as needed
4. Check logs for any issues
5. Enjoy your modular HyprFlux setup!
