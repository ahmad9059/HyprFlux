# Contributing to HyprFlux

Thank you for your interest in contributing to HyprFlux! This document provides guidelines and instructions for contributing to the project.

## About HyprFlux

HyprFlux is an MIT-licensed, OSI-approved free and open source software project. It is a complete Arch Linux desktop operating system built around Hyprland, featuring a live ISO, installer, boot experience, login flow, theming, tooling, and a maintained desktop environment.

## Ways to Contribute

### Reporting Bugs

If you encounter a bug, please [open an issue](https://github.com/ahmad9059/HyprFlux/issues) with:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- System information (Arch Linux version, Hyprland version, hardware details)
- Relevant logs and screenshots
- The version of HyprFlux you're using

### Suggesting Enhancements

Feature requests are welcome! Please [open an issue](https://github.com/ahmad9059/HyprFlux/issues) with:

- A clear description of the feature
- Why it would benefit HyprFlux users
- Any implementation ideas or references

### Pull Requests

We welcome pull requests! Please follow these steps:

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Test your changes** thoroughly on an Arch Linux system
4. **Update documentation** if applicable
5. **Submit a pull request** with a clear description

## Development Setup

### Prerequisites

- Arch Linux installation
- Basic tools: `git`, `curl`, `sudo`
- Familiarity with shell scripting, Hyprland, and related tools

### Getting Started

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/HyprFlux.git
cd HyprFlux

# Create a branch for your changes
git checkout -b feature/your-feature-name
```

### Project Structure

```text
HyprFlux/
├── config/          # Project configuration
├── dotsSetup.sh     # Modular platform setup entrypoint
├── install.sh       # Primary install entrypoint
├── lib/             # Shared install helpers
├── modules/         # Modular setup steps
├── scripts/         # Installer helper scripts
├── utilities/       # Themes, archives, logos, cursors
└── .config/         # Desktop environment files
    ├── hypr/        # Hyprland configs
    ├── waybar/      # Waybar configs
    └── rofi/        # Rofi configs
```

## Coding Standards

### Shell Scripts

- Use `shellcheck` to validate your scripts
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Include error handling and meaningful output messages
- Ensure scripts are idempotent where possible

### Configuration Files

- Maintain consistency with existing configuration style
- Comment complex configurations
- Use meaningful variable names

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests when applicable

Example:
```
Add Plymouth theme configuration module

- Create modules/plymouth/setup.sh
- Update dotsSetup.sh to include Plymouth module
- Add documentation in README.md

Fixes #123
```

## Testing

Before submitting a pull request:

1. Test your changes on a fresh Arch Linux installation or VM
2. Verify the installer completes successfully
3. Check that desktop components load correctly
4. Ensure no regressions in existing functionality

### Testing with QEMU

```bash
# Build and test ISO changes
cd references/Hyprflux-ISO
./build.sh
qemu-system-x86_64 -cdrom output/hyprflux.iso -m 4096
```

## Areas for Contribution

- **Installer improvements**: reliability, hardware support, edge cases
- **Documentation**: guides, troubleshooting, translations
- **Theming**: GTK themes, icon packs, wallpapers
- **Desktop workflows**: keybinds, scripts, automation
- **ISO development**: boot experience, TUI refinements
- **Bug fixes**: stability, compatibility, performance

## Review Process

1. Maintainers will review your pull request
2. Feedback may be provided for changes
3. Once approved, your PR will be merged

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## License

By contributing to HyprFlux, you agree that your contributions will be licensed under the [MIT License](LICENSE).

## Questions?

Feel free to [open an issue](https://github.com/ahmad9059/HyprFlux/issues) for questions or discussions about the project.

---

Thank you for contributing to HyprFlux!