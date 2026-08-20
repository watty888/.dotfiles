#!/bin/bash
# Arch Linux Restore Script
# Restores system from dotfiles + package lists
# Usage: bash restore.sh [full]
#   restore.sh          - Install essential packages only
#   restore.sh full     - Install all packages (takes longer)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/watty88/dotfiles}"
MODE="${1:-essential}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Arch Linux System Restore"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "⚠ This script must be run as root for package installation"
   echo "Attempting with sudo..."
   exec sudo bash "$0" "$@"
fi

# Step 2: Initialize dotfiles repo if needed
if [[ ! -d "$HOME/.dotfiles/.git" ]]; then
    echo "📦 Cloning dotfiles repository..."
    git clone --bare "$DOTFILES_REPO" "$HOME/.dotfiles"

    # Configure git alias
    mkdir -p "$HOME/.config/git"
    echo '[alias]
    dot = !git --git-dir=$HOME/.dotfiles --work-tree=$HOME' >> "$HOME/.config/git/config"

    # Checkout dotfiles
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" checkout -f
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no
fi

# Step 3: Update pacman mirrors (optional)
if command -v reflector &> /dev/null; then
    echo "🌍 Updating pacman mirrors..."
    reflector -c US -a 12 --sort rate --save /etc/pacman.d/mirrorlist || true
fi

# Step 4: Sync pacman database
echo "📦 Syncing pacman database..."
pacman -Sy

# Step 5: Install essential packages
echo "📥 Installing essential packages..."
PKGFILE="${SCRIPT_DIR}/packages-essential.txt"
if [[ ! -f "$PKGFILE" ]]; then
    echo "⚠ packages-essential.txt not found in $SCRIPT_DIR"
    echo "Creating minimal essential packages..."
    ESSENTIAL_PKGS="base linux-lts linux-firmware grub efibootmgr zsh git neovim sway pipewire networkmanager"
else
    ESSENTIAL_PKGS=$(grep -v '^#' "$PKGFILE" | grep -v '^$' | xargs)
fi

pacman -S --noconfirm $ESSENTIAL_PKGS 2>&1 | tail -10

# Step 6: Install paru for AUR access
echo "📦 Setting up AUR helper (paru)..."
if ! command -v paru &> /dev/null; then
    # Build paru from source
    mkdir -p /tmp/paru-build
    cd /tmp/paru-build
    git clone https://aur.archlinux.org/paru.git . 2>/dev/null || true
    if [[ -f PKGBUILD ]]; then
        sudo -u nobody makepkg -si --noconfirm 2>&1 | tail -5
    fi
    cd -
fi

# Step 7: Install AUR packages
echo "📥 Installing AUR packages..."
AURPKGFILE="${SCRIPT_DIR}/packages-aur-essential.txt"
if [[ -f "$AURPKGFILE" ]]; then
    AUR_PKGS=$(grep -v '^#' "$AURPKGFILE" | grep -v '^$' | xargs)
    if [[ -n "$AUR_PKGS" ]]; then
        paru -S --noconfirm $AUR_PKGS 2>&1 | tail -10
    fi
fi

# Step 8: Apply dotfiles configurations
echo "🔧 Applying dotfiles configurations..."
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" checkout -f
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no

# Step 9: Optional - Install full package list
if [[ "$MODE" == "full" ]]; then
    echo "📥 Installing full package list (this may take a while)..."
    FULLPKGFILE="${SCRIPT_DIR}/packages-full.txt"
    if [[ -f "$FULLPKGFILE" ]]; then
        FULL_PKGS=$(grep -v '^#' "$FULLPKGFILE" | grep -v '^$' | xargs)
        pacman -S --noconfirm $FULL_PKGS 2>&1 | tail -20
        echo "✓ Full package installation complete"
    fi
fi

# Step 10: Post-install setup
echo "🔨 Running post-install setup..."

# Set shell to zsh if not already
if [[ "$SHELL" != */zsh ]]; then
    chsh -s /usr/bin/zsh
    echo "✓ Default shell changed to zsh"
fi

# Create necessary directories
mkdir -p "$HOME/.local/bin" "$HOME/.cache" "$HOME/.config"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Restore Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Verify configurations: nvim, zsh, sway, etc."
echo "2. For GPU drivers, run: nvidia-driver-updates (if NVIDIA)"
echo "3. Generate SSH keys if needed: ssh-keygen -t ed25519"
echo "4. Configure git: git config --global user.name/email"
echo ""
echo "To install full package list later, run:"
echo "  bash restore.sh full"
echo ""
