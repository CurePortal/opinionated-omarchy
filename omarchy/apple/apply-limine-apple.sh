#!/bin/bash
# Apply the Apple-themed Limine boot screen.
# Copies the wallpaper into /boot/limine/, then rewrites the global options in
# /boot/limine.conf while preserving all auto-generated OS/snapshot entries.
set -euo pipefail

WALL_SRC="$HOME/.config/omarchy/apple/limine-wallpaper.png"
WALL_DST="/boot/limine/apple-wallpaper.png"
CONF="/boot/limine.conf"

[[ -f $WALL_SRC ]] || { echo "Missing wallpaper: $WALL_SRC" >&2; exit 1; }

echo "Installing Apple Limine theme..."
sudo install -m 0644 -- "$WALL_SRC" "$WALL_DST"
sudo cp -- "$CONF" "$CONF.bak.apple.$(date +%s)"

sudo python3 - "$CONF" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

blocked = re.compile(
    r'^\s*(timeout|default_entry|interface_|term_|backdrop|wallpaper|'
    r'graphics|mouse|quiet|hash_mismatch_panic|editor_)\b'
)
first_entry = len(lines)
for i, line in enumerate(lines):
    if line.startswith('/'):
        first_entry = i
        break

rest = lines[first_entry:]

new_header = """### Apple-themed boot screen (user customization)
timeout: 3
default_entry: 2
interface_branding: macOS
interface_branding_color: ffffff
interface_help_color: 8e8e93
interface_help_color_bright: ffffff
hash_mismatch_panic: no

wallpaper: boot():/limine/apple-wallpaper.png
wallpaper_style: stretched
backdrop: 000000

term_background: 00000000
term_foreground: ffffff
term_foreground_bright: ffffff
term_background_bright: 1c1c1e
# Apple grayscale palette
term_palette: 000000;ff453a;30d158;ffd60a;0a84ff;bf5af2;64d2ff;d1d1d6
term_palette_bright: 3a3a3c;ff453a;30d158;ffd60a;0a84ff;bf5af2;64d2ff;ffffff
"""

with open(path, 'w') as f:
    f.write(new_header + ''.join(rest))
print("limine.conf updated")
PYEOF

echo "Apple Limine theme applied. Reboot to see it."
