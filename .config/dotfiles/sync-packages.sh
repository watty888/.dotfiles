#!/usr/bin/env bash
# Snapshot the explicitly-installed package lists into the dotfiles repo, then
# commit and push if they changed. Run weekly by dotfiles-sync.timer.
#
# Deliberately path-limited: it only ever stages and commits the two package
# files. Anything else you have staged in the index is left untouched, so this
# can fire safely in the middle of your own half-finished work.

set -uo pipefail

export GIT_DIR="$HOME/.dotfiles"
export GIT_WORK_TREE="$HOME"

OUT_DIR="$HOME/.config/dotfiles"
REL_EXPLICIT=".config/dotfiles/packages-explicit.txt"
REL_AUR=".config/dotfiles/packages-aur.txt"
BRANCH="main"
REMOTE="origin"

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v pacman >/dev/null || die "pacman not found"
command -v git    >/dev/null || die "git not found"
[ -d "$GIT_DIR" ] || die "dotfiles git dir missing: $GIT_DIR"

mkdir -p "$OUT_DIR"

# Write via temp files so a failed pacman never truncates a good list.
tmp_e=$(mktemp) || die "mktemp failed"
tmp_a=$(mktemp) || die "mktemp failed"
trap 'rm -f "$tmp_e" "$tmp_a"' EXIT

pacman -Qqe | sort -u > "$tmp_e" || die "pacman -Qqe failed"
pacman -Qqm | sort -u > "$tmp_a" || die "pacman -Qqm failed"
[ -s "$tmp_e" ] || die "pacman -Qqe returned nothing; refusing to write an empty list"

mv "$tmp_e" "$HOME/$REL_EXPLICIT"
mv "$tmp_a" "$HOME/$REL_AUR"

git add -- "$REL_EXPLICIT" "$REL_AUR" || die "git add failed"

if git diff --cached --quiet HEAD -- "$REL_EXPLICIT" "$REL_AUR"; then
    log "package lists unchanged ($(wc -l < "$HOME/$REL_EXPLICIT") explicit, $(wc -l < "$HOME/$REL_AUR") AUR)"
else
    n_e=$(wc -l < "$HOME/$REL_EXPLICIT")
    n_a=$(wc -l < "$HOME/$REL_AUR")
    # -- <paths> keeps this commit to these two files regardless of what else
    # happens to be sitting in the index.
    git commit -q -m "Refresh package snapshot ($n_e explicit, $n_a AUR)" \
        -- "$REL_EXPLICIT" "$REL_AUR" || die "git commit failed"
    log "committed: $n_e explicit, $n_a AUR"
fi

# Push whatever is unpushed, including commits made by hand.
if git push -q "$REMOTE" "$BRANCH" 2>/dev/null; then
    log "pushed to $REMOTE/$BRANCH"
    git branch --set-upstream-to="$REMOTE/$BRANCH" "$BRANCH" >/dev/null 2>&1 || true
    exit 0
fi

# Push failed. Almost always the SSH key isn't in the agent -- this key is
# passphrase-protected and nothing can type it unattended. The commit is safe
# locally; exiting non-zero makes the failure visible in `systemctl --user
# --failed` rather than disappearing into the journal.
if git rev-parse --verify --quiet "$REMOTE/$BRANCH" >/dev/null; then
    state="$(git rev-list --count "$REMOTE/$BRANCH".."$BRANCH") commit(s) unpushed"
else
    state="no $REMOTE/$BRANCH ref locally, so nothing has been pushed yet"
fi
die "push to $REMOTE/$BRANCH failed ($state). If the SSH key is not loaded, run 'ssh-add ~/.ssh/id_ed25519_github' in a terminal and re-run: systemctl --user start dotfiles-sync.service"
