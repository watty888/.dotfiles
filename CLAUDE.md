# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is an Arch Linux development system with support for multiple programming languages and a polyglot workflow.

- **OS**: Arch Linux (kernel 6.18.21-1-lts)
- **Shell**: Zsh with Oh My Zsh, Powerlevel10k theme
- **Editor**: Neovim (primary), Vim (fallback), VS Code, Cursor IDE

## Available Languages & Tools

### Runtime Versions
- **Go**: 1.26.1 (system-installed)
- **Rust**: 1.94.1 (via rustup/cargo)
- **Node.js**: 24.11.0 (managed by fnm - Fast Node Manager)
- **Java**: OpenJDK 11.0.30
- **Python**: 3.14.3
- **Bun**: Available (modern JS runtime, in `~/.bun/bin/`)

### Package Managers
- **System packages**: `pacman` (Arch package manager)
- **JavaScript/Node**: fnm (Fast Node Manager) for Node versions, `npm` for packages
- **Rust**: `cargo` (Rust package manager)
- **Homebrew**: Linuxbrew available at `/home/linuxbrew/.linuxbrew/` (for cross-platform packages)

### Development Tools
- **Git**: 2.53.0
- **Docker**: 29.3.1
- **fzf**: Installed (fuzzy finder, integrated with shell history via Ctrl+R)

## Shell & Environment Configuration

### Key Aliases
- `v` → `nvim` (primary editor)
- `dot` → git worktree for dotfiles (`git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`)
- `zshconfig` → edit shell config in Neovim
- `zshupdate` → reload shell config
- `z` / `zi` → zoxide (smart directory jumping)

### Environment Setup
- **Editor**: Defaults to `nvim` (unless over SSH, then `vim`)
- **PATH**: Includes `~/.cargo/bin`, `~/.local/bin`, fnm, Bun, Linuxbrew
- **History**: Shared across terminals with zoxide integration

### Shell Keyboard Shortcuts
- `Ctrl+R` → fzf-powered command history search
- `Esc Esc` → Prepend `sudo` to last command

## Project Organization

### Key Directories
- `~/Projects/` → Main project workspace (Go, Rust, Crystal, Java, Next.js projects)
- `~/.dotfiles/` → System dotfiles (managed as git bare repo)
- `~/.config/` → XDG config directory (nvim, zsh, git, etc.)
- `~/workspace/github.com/` → Optional secondary workspace

### Language-Specific Directories
- Go projects typically in `~/Projects/go/`
- Rust projects can use `~/.cargo/` for global tools
- Node.js projects use fnm for version management

## Development Workflows

### Node.js / JavaScript
- fnm automatically detects `.node-version` or `.nvmrc` files
- Bun available as modern alternative to Node.js runtime
- Packages installed via `npm` (fnm manages Node versions)

### Go
- Standard `go build`, `go test`, `go run` commands
- Code at `~/Projects/go/`

### Rust
- `cargo` for building, testing, managing projects
- Global tools installed via `cargo install`

### Java
- jenv is lazy-loaded (first invocation initializes it)
- OpenJDK 11 configured
- `~/Projects/java/` for projects

### Python
- Python 3.14.3 available
- Use venv for virtual environments in projects

## Editor Configuration

### Neovim
- Primary editor, with various plugin configurations
- Config likely in `~/.config/nvim/`

### IDE Integration
- VS Code config in `~/.config/Code/`
- Cursor IDE config in `~/.config/Cursor/` (Cursor rules may override defaults)
- GitHub Copilot configured in both

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
pacman -S <package>      # Install system packages
brew install <package>   # Linuxbrew for cross-platform tools
cargo install <tool>     # Install Rust tools globally
npm install -g <pkg>     # Install Node tools globally
```

### Environment Variables
- `EDITOR` → Set to nvim/vim depending on context
- `PATH` → Includes multiple tool locations (see `.config/zsh/.zshrc`)
- `XDG_CONFIG_HOME` → `~/.config`

## Git & Version Control

- Git configured at `~/.config/git/`
- Dotfiles managed via bare git repo in `~/.dotfiles/`
- Use `dot` alias to manage dotfiles: `dot status`, `dot add`, `dot commit`

## Notes for Future Sessions

- Node.js versions are managed per-project via fnm. Don't assume a global version.
- When working with multiple languages, verify the correct version is active in the shell.
- For cross-platform tool development, Linuxbrew provides consistent environments.
- The system uses zoxide for directory jumping—typing `z <partial-path>` works well.
