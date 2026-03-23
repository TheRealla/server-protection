# Server Protection 🛡️

**server-protection** is a lightweight, modular, shell-based hardening toolkit designed to quickly and securely lock down Linux servers (Ubuntu/Debian/CentOS/RHEL/Fedora/AlmaLinux/Rocky/Arch/...).  

It automates best-practice security configurations to protect against common attack vectors: brute-force login attempts, unauthorized root access, outdated/vulnerable packages, weak file permissions, exposed unnecessary services, and basic kernel-level exploits.

Ideal for:
- VPS / cloud instances
- Web servers (Nginx/Apache)
- Game servers (Minecraft, FiveM, Rust, etc.)
- Discord bots & small personal services
- Homelab & self-hosted environments
- Any internet-facing Linux machine that needs rapid, no-nonsense protection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Shell](https://img.shields.io/badge/language-Shell-blue?logo=gnu-bash)
![Tested on](https://img.shields.io/badge/tested%20on-Ubuntu%2020.04–24.04%20%7C%20Debian%2011–12%20%7C%20Rocky/AlmaLinux%208–9-green)

## ✨ Features

- **Firewall** setup (ufw or firewalld) — default-deny policy + service-specific rules
- **Fail2Ban** with optimized jails (sshd, nginx/apache, common services)
- **Automatic security updates** (unattended-upgrades / dnf-automatic)
- **SSH hardening** — disable root login, optional custom port, prefer key authentication
- **User & permission tightening** — remove risky packages/users, stricter umask, password policies
- **Sysctl / kernel hardening** — anti-spoofing, SYN cookies, ptrace restrictions, ASLR improvements
- **Basic rootkit/malware scanning** (rkhunter, chkrootkit, debsums where applicable)
- **Log monitoring** hooks (optional email or Discord webhook alerts)
- **One-command** full run with sane defaults + fully interactive mode
- **Modular execution** — run only the parts you want
- **Idempotent** — safe to re-run without breaking things
- Minimal external dependencies (curl/wget + distro package manager)

## 📋 Requirements

- Root or sudo access
- Supported families (actively tested):
  - Ubuntu 20.04 / 22.04 / 24.04
  - Debian 11 / 12
  - Rocky Linux 8 / 9
  - AlmaLinux 8 / 9
  - CentOS Stream 8 / 9 (partial support)
  - Fedora 39+
- Internet connection (package downloads)
- ≥ 512 MB RAM (1 GB+ recommended for comfort)

## 🚀 Quick Start (most users)

```bash
# One-liner (downloads and runs the latest version)
curl -sSL https://raw.githubusercontent.com/TheRealla/server-protection/main/install.sh | sudo bash
