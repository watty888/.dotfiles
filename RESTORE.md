# System Restore Guide

Complete guide to restore your Arch Linux system from dotfiles after migration/reinstall.

## What's Included

- **restore.sh** - Automated restore script (main tool)
- **packages-essential.txt** - Minimal package set (~85 packages)
- **packages-aur-essential.txt** - Essential AUR packages (~7 packages)

## Quick Start (Fresh Arch Install)

After installing base Arch Linux:

```bash
# 1. Clone or download this restore script
git clone <your-dotfiles-repo> ~/dotfiles-temp
cd ~/dotfiles-temp

# 2. Run restore (requires sudo/root)
sudo bash restore.sh

# 3. Done! Your system is restored
```

## What Gets Restored

### Essential System (restore.sh with no args)

**Base System:**
- Linux kernel (LTS), firmware, bootloader
- Essential build tools (gcc, make, cmake)

**Development:**
- Git, GitHub CLI
- Neovim, tmux, screen
- Node.js, Python, Rust, Go

**Shell:**
- Zsh with dotfiles config
- fzf, ripgrep, fd, jq, bat (modern CLI tools)
- Zoxide (smart directory jumping)

**Display/Desktop:**
- Sway (Wayland window manager)
- Kanshi (display management)
- Fuzzel (launcher)
- Wayland stack

**Audio/Video:**
- PipeWire (audio server)
- NVIDIA drivers (LTS)

**Network/System:**
- NetworkManager
- OpenSSH
- systemd

**UI/Fonts:**
- Noto fonts (including emoji)
- Nerd font symbols
- Adwaita themes

**AUR Packages:**
- Brave Browser (bin)
- Cursor IDE (bin)
- Proton GE (gaming)
- Bruno API client
- Informant (news)

### Excluded (Secrets)

The following are intentionally excluded to avoid credential leaks:
- ❌ anydesk-bin (requires auth setup)
- ❌ ngrok (requires token)
- ❌ xivlauncher (game account config)
- ❌ Full VS Code (use cursor-bin or web version)

You can reinstall these manually after restore if needed.

---

## Usage Modes

### Minimal Restore (Recommended First Time)
```bash
sudo bash restore.sh
```

This installs:
- ~85 essential official packages
- ~7 essential AUR packages
- All your dotfiles configs

Time: ~10-20 minutes
Space: ~2-3GB

### Full Restore (After Initial Setup)
```bash
sudo bash restore.sh full
```

This adds:
- All 1,545 packages from your current system
- Everything from essential restore

**Note:** Requires `packages-full.txt` in same directory
Time: ~40-60 minutes
Space: ~15-20GB

---

## Step-by-Step Restore Process

### Phase 1: Fresh Arch Installation

Boot Arch installation media and:

```bash
# Partition your disk (SSD in your case: /dev/sdb)
fdisk /dev/sdb
# Create partitions:
# - Boot: 1GB FAT32 (EFI)
# - Root: remainder ext4

mkfs.fat -F 32 /dev/sdb1
mkfs.ext4 /dev/sdb2

mount /dev/sdb2 /mnt
mkdir -p /mnt/boot
mount /dev/sdb1 /mnt/boot

# Install base system
pacstrap /mnt base linux-lts linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into system
arch-chroot /mnt

# Inside chroot - basic setup
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime  # Adjust timezone
hwclock --systohc
echo "hostname" > /etc/hostname

# Edit /etc/locale.gen, uncomment en_US.UTF-8
locale-gen

# Install bootloader
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set root password
passwd

# Exit chroot and reboot
exit
reboot
```

### Phase 2: Boot New System & Run Restore

```bash
# Log in as root (or sudo)

# Clone dotfiles or download restore.sh
git clone <your-dotfiles-repo> ~/dotfiles-setup
cd ~/dotfiles-setup

# Run restore
sudo bash restore.sh

# Follow prompts, wait for completion
```

### Phase 3: Post-Restore Setup

```bash
# 1. Verify configs work
nvim --version
zsh --version
sway --version

# 2. Set up SSH keys (if not in dotfiles)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# 3. Configure git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 4. Re-add secrets (auth configs for excluded packages)
# - Reinstall anydesk-bin, configure auth
# - Set up ngrok token
# - Configure game launchers

# 5. Install additional packages if needed
paru -S <package-name>
```

---

## Troubleshooting

### "restore.sh: command not found"
Make sure script is executable:
```bash
chmod +x restore.sh
```

### "Packages not found"
If pacman can't find packages, check your mirrorlist:
```bash
sudo pacman -Syy
```

### "Permission denied" on dotfiles checkout
The script should handle this with sudo, but if issues:
```bash
sudo chown -R $USER ~/.dotfiles
```

### Nvidia drivers not working
After restore, test:
```bash
nvidia-smi
```

If missing, the LTS kernel drivers may need rebuilding:
```bash
paru -S nvidia-lts
```

### Paru AUR helper fails to build
If paru build fails during restore, install manually:
```bash
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si
```

---

## Creating Full Package List

To generate `packages-full.txt` from current system:

```bash
pacman -Qn > packages-full.txt      # Official packages
pacman -Qm > packages-aur-full.txt  # AUR packages
```

Then add to dotfiles:
```bash
cd ~
dot add packages-full.txt packages-aur-full.txt
dot commit -m "Add full package lists"
```

---

## Migration Timeline (Your Case)

**Before migration:**
- ✅ Commit pending dotfiles changes
- ✅ Create package lists & restore script
- ✅ Test restore script (optional but recommended)

**During migration:**
1. Backup current Arch to external drive
2. Partition SSD for new Arch
3. Install fresh Arch on SSD
4. Run `restore.sh`
5. Install Windows on NVMe

**After migration:**
- Verify all tools work (nvim, zsh, git, etc.)
- Install optional excluded packages manually
- Test gaming on Windows (on NVMe)

---

## Notes

- **Dotfiles location:** Uses bare git repo at `~/.dotfiles/`
- **Alias:** Use `dot status`, `dot add`, etc. (defined in `.config/git/config`)
- **Exclusions:** Secrets/credentials must be added manually (see "Excluded" section)
- **Package updates:** Keep `packages-*.txt` updated with `dot commit` after changes
- **Gaming:** Once Windows is installed, Steam library can live on HDD partition

---

## Support

If restore.sh fails:

1. Check which step failed (look at output)
2. Run that step manually for more details
3. Consult `/var/log/pacman.log` for pacman errors
4. Use `paru` directly for AUR package debugging

Most issues are network-related; ensure internet is working and mirrors are synced.
