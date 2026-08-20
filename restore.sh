#!/usr/bin/env bash
# Arch Linux post-install restore.
#
# Run as your normal user (NOT root, NOT with sudo). It escalates per-command.
#
#   ./restore.sh                 # essential packages + dotfiles
#   ./restore.sh --with-nvidia   # also install the legacy Pascal driver (GTX 10xx)
#   ./restore.sh --skip-aur      # official repo packages only
#
# Machine notes (HP Pavilion Gaming 17-cd0xxx):
#   GTX 1050 Max-Q is Pascal. NVIDIA's 590 branch dropped Maxwell/Pascal/Volta,
#   and Arch's `nvidia` package tracks the current branch — it will NOT drive this
#   GPU. The only working option is nvidia-580xx-dkms from the AUR, which is why
#   NVIDIA is opt-in here rather than in the package list.
#   If Arch runs on the Intel iGPU only, skip it entirely.

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/watty888/.dotfiles.git}"
MIRROR_COUNTRIES="${MIRROR_COUNTRIES:-Austria,Germany}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WITH_NVIDIA=0
SKIP_AUR=0
for arg in "$@"; do
  case "$arg" in
    --with-nvidia) WITH_NVIDIA=1 ;;
    --skip-aur)    SKIP_AUR=1 ;;
    -h|--help)     sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

# ── Preconditions ───────────────────────────────────────────────────────────
# Running the whole script under sudo resets $HOME to /root under env_reset,
# which would install every dotfile into root's home instead of yours.
[[ $EUID -eq 0 ]] && die "run as your normal user, not root. It calls sudo itself."
command -v sudo >/dev/null || die "sudo is not installed. Install it and add yourself to wheel."
ping -c1 -W3 archlinux.org >/dev/null 2>&1 || die "no network."

log "Requesting sudo (cached for the rest of the run)"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

# ── Mirrors ─────────────────────────────────────────────────────────────────
if command -v reflector >/dev/null; then
  log "Ranking mirrors ($MIRROR_COUNTRIES)"
  sudo reflector --country "$MIRROR_COUNTRIES" --age 12 --protocol https \
       --sort rate --save /etc/pacman.d/mirrorlist \
    || warn "reflector failed; keeping existing mirrorlist"
fi

# ── Full system upgrade ─────────────────────────────────────────────────────
# -Sy alone leaves a partially-upgraded system, which is the single most common
# way to break an Arch install. Always -Syu.
log "Synchronising and upgrading the system"
sudo pacman -Syu --noconfirm

# ── Official packages ───────────────────────────────────────────────────────
PKGFILE="$SCRIPT_DIR/packages-essential.txt"
[[ -f $PKGFILE ]] || die "packages-essential.txt not found next to this script."

mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$PKGFILE")
[[ ${#PKGS[@]} -gt 0 ]] || die "package list is empty."

log "Installing ${#PKGS[@]} packages from the official repos"
# --needed so reruns are cheap; no pipe to tail, so a failure actually stops us.
sudo pacman -S --needed --noconfirm -- "${PKGS[@]}"

# ── AUR helper ──────────────────────────────────────────────────────────────
if [[ $SKIP_AUR -eq 0 ]]; then
  if ! command -v paru >/dev/null; then
    log "Building paru-bin"
    # Must build as an unprivileged user with a writable dir and a real HOME.
    # (Building as `nobody` in a root-owned dir cannot work.)
    build=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build/paru-bin"
    ( cd "$build/paru-bin" && makepkg -si --noconfirm )
    rm -rf "$build"
  fi

  AURFILE="$SCRIPT_DIR/packages-aur-essential.txt"
  if [[ -f $AURFILE ]]; then
    mapfile -t AURPKGS < <(grep -vE '^\s*(#|$)' "$AURFILE")
    if [[ ${#AURPKGS[@]} -gt 0 ]]; then
      log "Installing ${#AURPKGS[@]} AUR packages"
      paru -S --needed --noconfirm -- "${AURPKGS[@]}"
    fi
  fi
fi

# ── NVIDIA (opt-in, legacy branch only) ─────────────────────────────────────
if [[ $WITH_NVIDIA -eq 1 ]]; then
  [[ $SKIP_AUR -eq 1 ]] && die "--with-nvidia needs the AUR; drop --skip-aur."
  log "Installing legacy Pascal driver (nvidia-580xx-dkms)"
  paru -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils
  warn "Reboot before expecting nvidia to load. Verify with: nvidia-smi"
fi

# ── Dotfiles ────────────────────────────────────────────────────────────────
log "Restoring dotfiles from $DOTFILES_REPO"
dot() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }

if [[ ! -d $HOME/.dotfiles ]]; then
  git clone --bare "$DOTFILES_REPO" "$HOME/.dotfiles"
fi
dot config --local status.showUntrackedFiles no

# checkout -f would silently destroy pre-existing files; move them aside instead.
if ! dot checkout 2>/dev/null; then
  backup="$HOME/.dotfiles-replaced-$(date +%Y%m%d-%H%M%S)"
  warn "existing files conflict with the repo; moving them to $backup"
  mkdir -p "$backup"
  dot checkout 2>&1 \
    | grep -oP '^\s+\K[^\s].*' \
    | while read -r f; do
        [[ -e $HOME/$f ]] || continue
        mkdir -p "$backup/$(dirname "$f")"
        mv "$HOME/$f" "$backup/$f"
      done
  dot checkout
fi

# ── Services ────────────────────────────────────────────────────────────────
log "Enabling services"
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service 2>/dev/null || true

# ── Shell ───────────────────────────────────────────────────────────────────
if [[ ${SHELL:-} != */zsh ]]; then
  log "Setting zsh as the login shell"
  chsh -s /usr/bin/zsh
fi

mkdir -p "$HOME/.local/bin" "$HOME/.cache" "$HOME/.config"

# ── Post-flight ─────────────────────────────────────────────────────────────
log "Done. Remaining manual steps:"
cat <<'EOF'

  1. Terminal — the sway config sets $term to ~/.local/bin/kitty, which is a
     manual upstream install, not a package. Either:
        sudo pacman -S kitty     &&  edit .config/sway/config: set $term kitty
     or reinstall upstream:
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
     Without one of these, Sway starts with no working terminal binding.

  2. Wallpaper — .config/sway/config execs
     ~/.config/sway/scripts/wallpaper-slideshow.sh, which is not in the repo.
     Recreate it or comment out that exec line.

  3. Git identity:
        git config --global user.name  "..."
        git config --global user.email "..."

  4. SSH key (the dotfiles remote is HTTPS; switch it to SSH once you have one):
        ssh-keygen -t ed25519
        git --git-dir=$HOME/.dotfiles --work-tree=$HOME \
            remote set-url origin git@github.com:watty888/.dotfiles.git

  5. Credentialed apps, installed by hand on purpose:
        paru -S anydesk-bin ngrok

EOF
