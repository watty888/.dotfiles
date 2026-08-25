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
  (UAS, 5 Gb/s). TRIM does not pass through the bridge by default.
- `/dev/nvme0n1` → Windows (Ableton, games). Do not repartition.
- `/dev/sda` → 1 TB Seagate ST1000LM049 (spinning), unmounted, not in fstab.
- `/dev/sdc` → 1 TB external, NTFS + ext4, unmounted.

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
- Version numbers in this file were verified against the live system on 2026-08-25.
  Re-verify rather than trusting them if the date is far in the past.
