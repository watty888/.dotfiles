# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is an Arch Linux development system with support for multiple programming languages and a polyglot workflow.

- **OS**: Arch Linux (kernel 6.18.46-1-lts)
- **Shell**: Zsh with Oh My Zsh, Powerlevel10k theme
- **Editor**: Neovim 0.12.5 (primary), Vim (fallback)
- **Desktop**: Sway (Wayland) with waybar, mako, swaylock-effects, fuzzel, kanshi
- **Terminal**: kitty

Root runs from an external USB-attached SATA SSD; the internal NVMe holds Windows
for Ableton and games. See "Storage layout" below before assuming device paths.

## Available Languages & Tools

### Runtime Versions
- **Go**: 1.27.0 (system-installed)
- **Rust**: 1.98.0 (via rustup/cargo)
- **Node.js**: 26.7.0 (system `node`; fnm available for per-project versions)
- **Java**: OpenJDK 26.0.2.1
- **Python**: 3.14.7
- **Bun**: 1.4.0 (in `~/.bun/bin/`)

### Package Managers
- **System packages**: `pacman`, with `paru` for the AUR
- **JavaScript/Node**: fnm for Node versions, `npm` for packages
- **Rust**: `cargo`

### Development Tools
- **Git**: 2.55.0
- **Docker**: 29.7.2
- **fzf**: fuzzy finder, integrated with shell history via Ctrl+R
- **zoxide**: smart directory jumping
- **yazi**: terminal file manager

## Claude Code

- **Binary**: `~/.local/bin/claude`
- **User config**: `~/.claude/`
  - `settings.json`, `settings.local.json`, `keybindings.json` — tracked in dotfiles
  - `plugins/known_marketplaces.json` — tracked; its `lastUpdated` field churns on
    every plugin refresh, so expect spurious diffs
- **This file** (`~/CLAUDE.md`) is the user-level instruction file and is tracked.
- **Never track**: `~/.claude/.credentials.json` (OAuth token), plus `projects/`,
  `sessions/`, `session-env/`, `file-history/`, `paste-cache/`, `shell-snapshots/`,
  `backups/`, `history.jsonl` — all local state.

## Shell & Environment Configuration

### Key Aliases
- `v` → `nvim` (primary editor)
- `dot` → dotfiles git wrapper (`git --git-dir=$HOME/.dotfiles --work-tree=$HOME`)
- `zshconfig` / `zshupdate` → edit / reload shell config
- `ohmyzsh` → edit the Oh My Zsh directory
- `kitty-conf` → edit `~/.config/kitty/kitty.conf`
- `swayconf` → edit `~/.config/sway/config`
- `z` / `zi` → zoxide

### Environment Setup
- **Editor**: Defaults to `nvim` (unless over SSH, then `vim`)
- **PATH**: Includes `~/.cargo/bin`, `~/.local/bin`, fnm, Bun
- **SSH agent**: `SSH_AUTH_SOCK` is exported in `~/.zshenv` and points at the
  socket-activated systemd unit `ssh-agent.socket`. GnuPG's ssh emulation
  (`gpg-agent-ssh.socket`) is masked — do not re-enable both at once.
- Don't confuse the two SSH roles: the agent above is the **client** side, holding keys
  for outbound use (GitHub/GitLab/dotfiles). The SSH **server** (`sshd`) is disabled —
  see "Firewall & remote access".

### Shell Keyboard Shortcuts
- `Ctrl+R` → fzf-powered command history search
- `Esc Esc` → Prepend `sudo` to last command

## Project Organization

### Key Directories
- `~/Projects/` → main project workspace (currently empty; work is cloned per-task)
- `~/.dotfiles/` → dotfiles git directory, with `$HOME` as the work tree
- `~/.config/` → XDG config (nvim, zsh, git, sway, waybar, kitty, …)

Note: `~/Projects/` has no committed contents. Clone repositories into it as needed
rather than assuming a `go/`, `java/`, or similar subdirectory already exists.

## Storage layout

- `/` and `/boot` → `/dev/sdb` — Samsung 860 EVO SATA SSD in a Ugreen USB enclosure
  (ASMedia 174c:235c, UAS, 5 Gb/s). The bridge does not advertise LBPME, so TRIM is
  off by default; `/etc/udev/rules.d/10-usb-trim.rules` forces `provisioning_mode=unmap`
  and `fstrim.timer` handles the weekly trim. Don't remove that rule casually.
- `/dev/nvme0n1` → Windows (Ableton, games). Do not repartition.
- `/dev/sda` → 1 TB Seagate ST1000LM049 (spinning), unmounted, not in fstab.
- `/dev/sdc` → 1 TB external, NTFS + ext4, unmounted.
- **Swap**: none on disk, by design. `zram-generator` provides compressed RAM swap
  (`/dev/zram0`, `ram / 2` ≈ 7.7 GiB, zstd, priority 100) via
  `/etc/systemd/zram-generator.conf`, with zram-appropriate tuning in
  `/etc/sysctl.d/99-zram.conf` (`vm.swappiness=180`, `vm.page-cluster=0`).
  Do not add a swap file: paging across the USB bridge is slow, and a bus hiccup while
  swap is live on it can hang the kernel hard. Hibernation is therefore unavailable.

## Boot & dual-boot

- GRUB boots from the USB SSD via the removable-media path
  (`/boot/EFI/BOOT/BOOTX64.EFI`). There is no dedicated NVRAM entry for it, which is
  correct for portable media — don't "fix" this.
- Windows is reachable from the GRUB menu through a **static** entry in
  `/etc/grub.d/40_custom`, chainloading `\EFI\Microsoft\Boot\bootmgfw.efi` from the
  Windows ESP (`nvme0n1p1`, FS UUID `6C01-2008`). `os-prober` is deliberately NOT
  installed; the static entry keeps the menu to one clean Windows item instead of also
  surfacing the recovery partition. If Windows is reinstalled, re-check that UUID with
  `lsblk -o NAME,FSTYPE,UUID /dev/nvme0n1` and update the `search` line.
- After editing anything in `/etc/grub.d/`, regenerate and validate:
  `sudo grub-mkconfig -o /boot/grub/grub.cfg && grub-script-check /boot/grub/grub.cfg`
- **Clocks**: Arch keeps the RTC in UTC (`/etc/adjtime`). Windows was configured to
  match via `RealTimeIsUniversal=1` (DWORD) under
  `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`, which fixed a recurring
  2-hour offset. Do **not** address clock drift with `timedatectl set-local-rtc 1` —
  it breaks DST handling. Verify health with `timedatectl`: `RTC time` should equal
  `Universal time`, not local time.
- `/boot` is a 1 GB ESP sitting near 70% full, because the nvidia modules in `MODULES=`
  make the initramfs large (~291 MB, plus a ~372 MB fallback). A second kernel will not
  fit. Don't strip those modules to make room — they're needed for early KMS.

## Development Workflows

### Node.js / JavaScript
- fnm detects `.node-version` / `.nvmrc`; don't assume the system Node version
- Bun available as an alternative runtime
- Packages via `npm`

### Go
- Standard `go build`, `go test ./...`, `go fmt ./...`

### Rust
- `cargo` for building, testing, managing projects
- Global tools via `cargo install`

### Java
- jenv is lazy-loaded (first invocation initializes it)
- OpenJDK 26 is the active JDK

### Python
- Python 3.14.7; use venv for per-project environments

## Editor Configuration

### Neovim
- Primary editor, AstroNvim-based config in `~/.config/nvim/`
- `~/.config/nvim/CLAUDE.md` carries Neovim-specific guidance

No GUI IDE is installed on this machine — VS Code, Cursor, and GitHub Copilot were
removed. Don't suggest workflows that depend on them.

## Building & Testing Across Projects

Each project has its own build system. Common patterns:
- **Go**: `go build`, `go test ./...`, `go fmt ./...`
- **Rust**: `cargo build`, `cargo test`, `cargo fmt`
- **Node.js**: `npm run build`, `npm test`
- **Python**: `pytest`, `python -m unittest`

Check individual project CLAUDE.md files (if they exist) for language-specific instructions.

## System Management

### Package Management
```bash
pacman -S <package>      # official repos
paru -S <package>        # AUR
cargo install <tool>     # Rust tools, globally
npm install -g <pkg>     # Node tools, globally
```

The NVIDIA GTX 1050 Max-Q is Pascal. NVIDIA's 590 branch dropped Pascal support and
Arch's `nvidia` package tracks the current branch, so this machine needs
`nvidia-580xx-dkms` from the AUR. Do not "fix" this by installing plain `nvidia`.

Wi-Fi regulatory: `wireless-regdb` is installed and `/etc/conf.d/wireless-regdom` sets
`WIRELESS_REGDOM="AT"` (applied at boot by a udev rule). Note the Intel Wireless-AC 9560
is a *self-managed* regulatory phy — `iw reg get` reports its own `country AT`
independently of the global domain, so the global setting only really matters for other
adapters. `/sys/module/cfg80211/parameters/ieee80211_regdom` reading `00` is the
boot-time module option, not the live domain; that is not a fault.

### Firewall & remote access

- **`ufw` is the firewall**, enabled and active: default deny incoming, allow outgoing,
  with a single rule allowing tcp/22 from `192.168.0.0/24`. Inspect with
  `sudo ufw status verbose`. Manage the firewall through ufw, not by editing nftables —
  the stock `/etc/nftables.conf` is untouched and `nftables.service` stays disabled.
  Never run both; they fight over the same netfilter engine.
- **`sshd` is disabled and nothing listens on port 22.** It was only ever used from a
  work laptop that has since been wiped and returned. To bring it back:
  `sudo systemctl enable --now sshd` (the ufw rule is already in place). Note this must
  be done *at the machine* — you cannot enable it remotely. If you do re-enable it, set
  up key-only auth at that point: `~/.ssh/authorized_keys` does not exist and OpenSSH
  defaults `PasswordAuthentication` to `yes`.
- `default deny incoming` also blocks inbound mDNS, so Chromecast discovery in the
  browser won't work until you add:
  `sudo ufw allow from 192.168.0.0/24 to any port 5353 proto udp`

### Environment Variables
- `EDITOR` → nvim/vim depending on context
- `XDG_CONFIG_HOME` → `~/.config`
- `SSH_AUTH_SOCK` → `$XDG_RUNTIME_DIR/ssh-agent.socket` (set in `~/.zshenv`)

## Git & Version Control

- Git config at `~/.config/git/`; global ignore at `~/.config/git/ignore`
- Dotfiles live in a git directory at `~/.dotfiles/` with `$HOME` as the work tree
- Use the `dot` alias: `dot status`, `dot add`, `dot commit`, `dot push`
- `status.showUntrackedFiles = no` is set, so `dot status` will **never** list new
  files. Add anything new by explicit path, and check `git check-ignore -v <path>`
  if an add is refused.
- Never use `dot add -A` / `dot add .` from `$HOME` — it sweeps in browser profiles
  and credentials. Stage by explicit path.

## Notes for Future Sessions

- Node.js versions are managed per-project via fnm. Don't assume a global version.
- When working with multiple languages, verify the correct version is active in the shell.
- The system uses zoxide for directory jumping—typing `z <partial-path>` works well.
- Version numbers in this file were verified against the live system on 2026-08-26.
  Re-verify rather than trusting them if the date is far in the past.
- **Deliberate decisions — these are not gaps, don't "fix" them:**
  - No `tlp` / `power-profiles-daemon` / `thermald`. `intel_pstate` runs in active mode
    with the `powersave` governor and `balance_performance` EPP, which is already
    reasonable. If battery life becomes a complaint, `power-profiles-daemon` is the
    minimal place to start.
  - `reflector.timer` stays disabled. Its shipped config is `--latest 5 --sort age` with
    no country filter, which would replace the official CDN mirrors
    (`fastly`/`geo.mirror.pkgbuild.com`) with five arbitrary ones — likely worse.
  - `KEYMAP` in `/etc/vconsole.conf` is intentionally unset. Sway uses
    `xkb_layout "us,de,ru"` with `us` first, so the TTY default already matches.
