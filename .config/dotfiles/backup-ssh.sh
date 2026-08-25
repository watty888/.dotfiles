#!/usr/bin/env bash
# Encrypted backup of ~/.ssh.
#
#   backup-ssh.sh <destination-directory>
#
# Produces <dest>/ssh-backup-YYYY-MM-DD.tar.gz.gpg, symmetrically encrypted with
# AES-256 from a passphrase you type. Then decrypts it back and diffs the file
# list against the original, so a corrupt or mistyped archive is caught now
# rather than on the day you need it.
#
# The passphrase is the only thing standing between the archive and your private
# keys. Use something long, and store it somewhere that is NOT this machine --
# a password manager on another device, or on paper.
#
# Restore:
#   gpg -d ssh-backup-YYYY-MM-DD.tar.gz.gpg | tar -xz -C "$HOME"
#   (tar restores the 0600 modes; verify with `ls -l ~/.ssh`)

set -euo pipefail

SRC="$HOME/.ssh"
DEST="${1:-}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -n "$DEST" ]   || die "usage: $(basename "$0") <destination-directory>"
[ -d "$DEST" ]   || die "destination is not a directory: $DEST"
[ -w "$DEST" ]   || die "destination is not writable: $DEST"
[ -d "$SRC" ]    || die "no $SRC to back up"
command -v gpg >/dev/null || die "gpg not found"

# Refuse to write the backup onto the same filesystem as the source -- that is
# not a backup, it is a second copy of the same failure domain.
src_fs=$(df --output=source "$SRC"  | tail -1)
dst_fs=$(df --output=source "$DEST" | tail -1)
if [ "$src_fs" = "$dst_fs" ]; then
    printf 'warning: %s is on the same filesystem (%s) as %s.\n' "$DEST" "$dst_fs" "$SRC" >&2
    printf 'This protects against accidental deletion but NOT against drive failure.\n' >&2
    # Without a terminal there is nobody to answer, and a bare `read` would block
    # forever (cron, a wrapper script). Fail loudly instead of hanging.
    [ -t 0 ] || die "same filesystem as $SRC, and no terminal to confirm on; pick another destination"
    read -rp 'Continue anyway? [y/N] ' reply
    [ "$reply" = "y" ] || [ "$reply" = "Y" ] || die "aborted"
fi

STAMP=$(date +%Y-%m-%d)
OUT="$DEST/ssh-backup-$STAMP.tar.gz.gpg"
[ -e "$OUT" ] && die "$OUT already exists; move or remove it first"

# The tarball staged below is PLAINTEXT private keys, so it must never reach a
# disk. /dev/shm is tmpfs (RAM), and swap here is zram -- compressed RAM, never
# persistent storage -- so the plaintext stays in memory and dies with the trap.
# Do NOT relax this back to a bare `mktemp -d`: that honours $TMPDIR, which can
# point at real disk, and the keys would be written out in the clear.
[ -d /dev/shm ] || die "/dev/shm unavailable; refusing to stage plaintext keys on disk"
work=$(mktemp -d -p /dev/shm) || die "mktemp failed"
trap 'rm -rf "$work"' EXIT

# -C "$HOME" so the archive holds relative ".ssh/..." paths and cannot be
# extracted to an absolute location by accident. -p preserves the 0600 modes.
tar -czpf "$work/ssh.tar.gz" -C "$HOME" .ssh || die "tar failed"

printf '\n--- encrypting (you will be asked for a passphrase, twice) ---\n'
gpg --symmetric \
    --cipher-algo AES256 \
    --digest-algo SHA512 \
    --s2k-mode 3 \
    --s2k-digest-algo SHA512 \
    --s2k-count 65011712 \
    --output "$OUT" \
    "$work/ssh.tar.gz" || die "gpg encryption failed"

chmod 600 "$OUT"

printf '\n--- verifying (decrypting the archive back) ---\n'
gpg --quiet --decrypt "$OUT" > "$work/verify.tar.gz" || die "VERIFY FAILED: cannot decrypt $OUT"

tar -tzf "$work/ssh.tar.gz"   | sort > "$work/list-orig"
tar -tzf "$work/verify.tar.gz" | sort > "$work/list-back"
diff -q "$work/list-orig" "$work/list-back" >/dev/null \
    || die "VERIFY FAILED: decrypted archive does not match the original"

printf '\nOK  %s\n' "$OUT"
printf '    %s bytes, %s entries, verified by round-trip decryption\n' \
    "$(stat -c%s "$OUT")" "$(wc -l < "$work/list-orig")"
printf '\nContents:\n'
sed 's/^/    /' "$work/list-orig"
printf '\nNow copy it somewhere off this machine. The passphrase is not stored anywhere.\n'
