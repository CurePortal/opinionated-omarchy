#!/usr/bin/env bash
# Re-apply the Apple art to the Plymouth (LUKS/boot) screen and rebuild the UKI.
# This is independent of the session theme: whatever theme is active, the boot
# screen stays Apple.
#
# Mirrors `omarchy-plymouth-set <bg> <text> <logo>` for the apple theme without
# the unprivileged-logo-open dance. Run as root (e.g. via sudo or pkexec).
set -euo pipefail

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
SRC="$OMARCHY_PATH/default/plymouth"
THEME="${APPLE_THEME_DIR:-$HOME/.config/omarchy/themes/apple}"
DST=$(readlink -f /usr/share/plymouth/themes/omarchy)
SDDM=$(readlink -f /usr/share/sddm/themes/omarchy)

[[ -f $THEME/unlock.png ]] || { echo "missing $THEME/unlock.png" >&2; exit 1; }

# apple colors: background #000000, foreground #ffffff
tmp=$(mktemp -d /tmp/apple-plymouth.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
cp -a "$SRC"/. "$tmp"/

sed -i \
  -e 's/^Window.SetBackgroundTopColor.*/Window.SetBackgroundTopColor(0.000, 0.000, 0.000);/' \
  -e 's/^Window.SetBackgroundBottomColor.*/Window.SetBackgroundBottomColor(0.000, 0.000, 0.000);/' \
  "$tmp/omarchy.script"

for a in bullet.png entry.png lock.png progress_bar.png; do
  magick "$tmp/$a" -channel RGB +level-colors "#ffffff","#ffffff" "$tmp/$a"
done

cp -- "$THEME/unlock.png" "$tmp/logo.png"

for a in bullet.png entry.png lock.png logo.png omarchy.plymouth omarchy.script progress_bar.png progress_box.png; do
  install -o 0 -g 0 -m 0644 -- "$tmp/$a" "$DST/$a"
done

# Keep SDDM's logo in sync with the apple art too.
install -o 0 -g 0 -m 0644 -- "$THEME/unlock.png" "$SDDM/logo.png"

plymouth-set-default-theme omarchy
if command -v limine-mkinitcpio >/dev/null 2>&1; then
  limine-mkinitcpio
else
  mkinitcpio -P
fi

echo "Apple Plymouth restored (theme: apple)."
