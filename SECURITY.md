# Security Policy

## Supported Versions

HyprFlux is actively developed. Security updates are applied to the latest release.

| Version | Supported |
| ------- | --------- |
| main    | Yes       |
| older   | No        |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Do not** open a public GitHub issue for security vulnerabilities.

Instead, please:

1. Go to [GitHub Security Advisories](https://github.com/ahmad9059/HyprFlux/security/advisories)
2. Click "Report a vulnerability"
3. Provide a detailed description of the vulnerability

Or email the maintainer directly via GitHub: `ahmad9059`

### What to Include

Please provide:

- A description of the vulnerability
- Steps to reproduce
- Affected components
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Initial response**: Within 48 hours
- **Triage and assessment**: Within 1 week
- **Fix development**: Depends on severity and complexity
- **Disclosure**: After fix is released

## Security Considerations

### Installer Scripts

HyprFlux runs installation scripts with elevated privileges. We recommend:

- Reviewing scripts before running: `curl -fsSL https://hyprflux.dev/install | less`
- Running on fresh systems or VMs for testing
- Backing up existing configurations

### Trust Model

HyprFlux installs software from:

- Official Arch Linux repositories
- Arch User Repository (AUR)
- HyprFlux repository (for configurations and theming)

Review all package sources and configurations to ensure they meet your security requirements.

### System Access

HyprFlux configures:

- User-level configurations in `~/.config/`
- System-level configurations via `sudo`
- Login/display manager settings (SDDM)
- Boot loader settings (GRUB)

## Known Security Notes

- **Root/sudo access**: The installer requires sudo for system-level configurations
- **AUR packages**: Some packages come from the AUR which are not officially vetted by Arch Linux
- **Configuration backups**: Previous configs are backed up to `~/dotfiles_backup/`

## Disclosure Policy

We follow responsible disclosure:

1. Vulnerability is reported privately
2. Maintainers investigate and develop a fix
3. Fix is released
4. Security advisory is published
5. Credit is given to the reporter (if desired)

## Security Updates

Security updates will be announced via:

- GitHub Releases
- GitHub Security Advisories
- Project repository

---

Thank you for helping keep HyprFlux secure!