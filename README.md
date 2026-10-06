# opinionated-omarchy

An opinionated [Omarchy](https://omarchy.org) setup tuned for **one specific
machine**: the **16-inch Intel MacBook Pro (2019, `MacBookPro16,1`, Core
i9-9980HK)**. It keeps DHH's Omarchy defaults but layers on the fixes and
cosmetics that make a T2 Mac actually feel like a Mac while running Arch.

If you are not on this laptop, most of this will still apply to any Omarchy
4.x machine, but the boot, display, audio, and input tuning is written for
this T2 Mac.

- **Omarchy target:** 4.x ("Quattro", Quickshell-based; Waybar is gone)
- **Compositor:** Hyprland, configured in Lua (`hypr/*.lua`)
- **Shell:** Omarchy Quickshell bar/menu, plus custom `cure.*` plugins
- **Boot:** Limine with an Apple-styled boot screen
- **Theme:** Solitude 

The pre-4.x version of this config lives in [`legacy/`](legacy/) for
historical reference.

## Hardware target

| | |
|---|---|
| Model | MacBook Pro 16-inch (2019), `MacBookPro16,1` |
| CPU | Intel Core i9-9980HK @ 2.40GHz |
| Display | Apple Color LCD, 3072x1920 @ 60Hz |
| Kernel | `linux-t2` (Watanare T2 patches), e.g. `7.2.7-arch1-Watanare-T2-2-t2` |
| Keyboard | Apple keyboard with white keyboard backlight |
| Trackpad | Apple Force Touch trackpad |

### Mac-specific tuning baked in

- **Display** — `hypr/monitors.lua` pins `scale = 1.6` (physical
  3072x1920) and `GDK_SCALE = 2`, so the HiDPI panel and GTK apps line up.
- **Keyboard** — Caps Lock stays Caps Lock (`input.lua`) instead of Omarchy's
  default compose mapping; F1/F3/F5/F6/F7/F10/F11/F12 are swallowed and the
  Apple `:white:kbd_backlight` device is wired to the keyboard brightness keys
  (`hypr/bindings.lua`).
- **Trackpad** — natural scroll, clickfinger right-click, three-finger drag and
  workspace gestures (`input.lua`).
- **Turbo Boost** — disabled at boot by
  `tmpfiles.d/omarchy-no-turbo.conf`, which writes `1` to
  `/sys/devices/system/cpu/intel_pstate/no_turbo` (see
  [Thermal tuning](#thermal-tuning-turbo-boost--fans)).
- **Fans** — held at a fixed **75% of max**, never ramping and never off, by
  `bin/t2fans-high` + `systemd/t2fans-high.service` (see
  [Thermal tuning](#thermal-tuning-turbo-boost--fans)).
- **Boot** — `limine/limine-entry-tool.d/t2-mac.conf` adds
  `intel_iommu=on iommu=pt pm_async=off pcie_ports=compat mem_sleep_default=s2idle`,
  and `omarchy-defaults.conf` keeps T2 Macs on `linux-t2` via the `BOOT_ORDER`.
- **Suspend** — forced to `s2idle` because this T2's advertised S3 `deep` state
  does not hold (see [Suspend](#suspend-lid-close)).
- **Audio** — designed to run alongside the out-of-tree T2 audio stack
  ([`snd_hda_macbookpro`](https://github.com/davidjo/snd_hda_macbookpro),
  [`t2-apple-audio-dsp`](https://github.com/lemmyg/t2-apple-audio-dsp)) for the
  6-speaker system. Those drivers are not vendored here.
- **Keyboard/dictation** — Super+Alt+Z toggles Whis dictation.

## Apple look & feel

- **Limine boot menu** — `omarchy/apple/limine-wallpaper.png` plus
  `apply-limine-apple.sh`, which installs the wallpaper and rewrites the global
  options in `/boot/limine.conf` (Apple grayscale palette, `macOS` branding,
  black backdrop). The generated config is committed at `limine/limine.conf`.
- **Plymouth screen (LUKS/boot)** — the Apple art pinned by
  `apply-apple-plymouth.sh` (black background, white accents, the Apple glyph
  from the theme's `unlock.png`). This is applied to Plymouth/SDDM directly, so
  it stays Apple whichever session theme is active. Omarchy updates overwrite
  `/usr/share/plymouth/themes/omarchy/*`; the
  `omarchy/hooks/post-update.d/restore-apple-plymouth.hook` re-applies it.
- **Lock screen** — the custom `cure.lock` Quickshell plugin and the `apple`
  theme's `unlock.png`.
- **Branding** — `omarchy/branding/` holds the ASCII `about.txt` and the Apple
  `screensaver.txt` logo.
- **Theme** — `omarchy/themes/apple/` is a clone of the stock **Solitude** theme
  (same `colors.toml`, btop/hyprland/neovim/vscode/icons), keeping Apple's own
  `unlock.png`, plus five Apple-style wallpapers in `backgrounds/` (Sequoia,
  Big Sur, Ventura, Graphite, Monterey). A `preview.png` is present so the theme
  appears in the Omarchy theme chooser.
- **Quickshell Bar** — a bottom, non-transparent bar with a center media widget, left
  workspaces, and right-side tray/agents/bluetooth/network/audio/monitor/power
  and an Apple-style 12-hour clock (`omarchy/shell.json`). The bundled
  `omarchy.lock` and `omarchy.menu` are disabled in favor of the `cure.*` clones.

## Custom Quickshell plugins (`omarchy/plugins/`)

| Plugin | Purpose |
|---|---|
| `cure.bar` | Bottom status bar and its widgets/indicators |
| `cure.clock` | Apple-style clock with calendar popup |
| `cure.lock` | Lock screen (separate password + fingerprint PAM flows) |
| `cure.media` | Transport controls with Tidal fallback |
| `cure.menu` | Omarchy command menu |
| `cure.workspaces` | Workspace number indicators |

## Layout

```
hypr/                 Hyprland 4.x Lua config (hyprland, bindings, input,
                      looknfeel, monitors, autostart) + hyprsunset.conf
omarchy/
  shell.json          Quickshell bar/idle/plugin layout
  shell.toml          Shell font settings
  apple/              Limine + Plymouth Apple boot art and apply scripts
  branding/           about.txt / screensaver.txt ASCII art
  extensions/         omarchy-menu.jsonc extensions
  hooks/post-update.d/ Keeps the Apple Plymouth after omarchy updates
  themes/apple/       Solitude clone + Apple unlock art + wallpapers
  plugins/            Custom cure.* Quickshell plugins
limine/
  limine.conf                        Generated Apple-styled boot config
  default-limine                     /etc/default/limine (authoritative cmdline)
  limine-entry-tool.d/               T2 Mac + Omarchy bootloader overrides
systemd/
  sleep.conf.d/                       Forces freeze/s2idle suspend
  t2fans-high.service                 Pins both fans at a fixed speed
bin/
  t2fans-high                         Fan-pinning script (/usr/local/bin)
tmpfiles.d/
  omarchy-no-turbo.conf               Disables Intel Turbo Boost at boot
legacy/               Pre-4.x .conf configs (kept for reference)
```

## Suspend (lid close)

Lid-close sleep on this machine needs two things, and both are easy to get
wrong on Omarchy 4.x:

1. **Force `s2idle`, not `deep`.** The kernel advertises S3 `deep`, but on this
   T2 it aborts a couple of seconds in and the system falls back to `s2idle`
   mid-suspend — the screen wakes while the lid is still closed. Set
   `mem_sleep_default=s2idle` (boot) and the `[Sleep]` drop-in
   (`SuspendState=freeze`, `MemorySleepMode=s2idle`).
2. **Make sure the parameter actually reaches the kernel.** `/etc/default/limine`
   uses `KERNEL_CMDLINE[default]=`, and per `limine-entry-tool`, that file
   **overrides** the `+=` drop-ins in `/etc/limine-entry-tool.d/`. If
   `/etc/default/limine` exists, the T2 drop-in is silently ignored and the
   kernel boots with `[deep]` (the firmware default). Keep the T2/Omarchy params
   in `limine/default-limine` so they always apply, then rebuild:

   ```bash
   sudo cp limine/default-limine /etc/default/limine
   sudo cp limine/limine-entry-tool.d/*.conf /etc/limine-entry-tool.d/
   sudo mkdir -p /etc/systemd/sleep.conf.d
   sudo cp systemd/sleep.conf.d/*.conf /etc/systemd/sleep.conf.d/
   sudo limine-mkinitcpio
   ```

   Verify after reboot: `cat /proc/cmdline` shows the T2 params and
   `cat /sys/power/mem_sleep` shows `[s2idle]`.

## Thermal tuning (Turbo Boost + fans)

The i9-9980HK in this chassis runs hot and loud under load. Two tweaks keep it
smooth and predictable: **Turbo Boost off** and **fans pinned at a constant
speed**.

### Disable Intel Turbo Boost

`tmpfiles.d/omarchy-no-turbo.conf` writes `1` to
`/sys/devices/system/cpu/intel_pstate/no_turbo` on every boot, capping the CPU
at its base clock. This removes the short bursts that spiked temperatures (and
fans) and made the machine throttle unevenly. The `w!` flag is boot-only, so it
is reapplied at each start but will not fight a manual override during a
session.

```bash
sudo install -Dm644 tmpfiles.d/omarchy-no-turbo.conf /etc/tmpfiles.d/omarchy-no-turbo.conf
# apply now without rebooting:
sudo systemd-tmpfiles --create /etc/tmpfiles.d/omarchy-no-turbo.conf
```

Verify: `cat /sys/devices/system/cpu/intel_pstate/no_turbo` → `1`.

### Pin the fans at 75%

The kernel exposes the T2 fans through `applesmc`
(`fan{1,2}_manual` / `_output`), but the usual daemons only offer a temperature
curve or full blast. `bin/t2fans-high` instead sets each fan to manual mode at
`T2FANS_PERCENT` (default **75%**) of its own max, then holds it there — no
ramping, and never off. `systemd/t2fans-high.service` runs it once at boot and
`Conflicts=t2fanrd.service` so the curve daemon cannot fight it.

On this machine that pins fan1 to 4212 RPM (75% of 5616) and fan2 to 3900 RPM
(75% of 5200).

```bash
sudo install -Dm755 bin/t2fans-high /usr/local/bin/t2fans-high
sudo install -Dm644 systemd/t2fans-high.service /etc/systemd/system/t2fans-high.service
sudo systemctl disable --now t2fanrd.service   # curve daemon, if present
sudo systemctl enable --now t2fans-high.service
```

To change the speed, override `T2FANS_PERCENT` with a drop-in rather than
editing the script, then restart:

```bash
sudo systemctl edit t2fans-high.service   # add: [Service]\nEnvironment=T2FANS_PERCENT=90
sudo systemctl restart t2fans-high.service
```

Verify: `cat /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:104/APP0001:00/fan{1,2}_output`.

## Installing

These files map onto `~/.config` and `/boot`. From the repo root:

```bash
# Hyprland config
cp -r hypr/.        ~/.config/hypr/
cp -r omarchy/.     ~/.config/omarchy/
cp -r limine/.      ~/.config/opinionated-omarchy-limine/   # reference copy

# Apply the Apple boot screen (installs wallpaper + rewrites /boot/limine.conf)
~/.config/omarchy/apple/apply-limine-apple.sh

# Boot cmdline (T2 params + s2idle), drop-ins, and sleep mode need root
sudo cp limine/default-limine /etc/default/limine
sudo cp limine/limine-entry-tool.d/*.conf /etc/limine-entry-tool.d/
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo cp systemd/sleep.conf.d/*.conf /etc/systemd/sleep.conf.d/
sudo limine-mkinitcpio   # rebuild the UKI with the new cmdline

# Thermal tuning (Turbo Boost off + fans pinned). See that section for details.
sudo install -Dm644 tmpfiles.d/omarchy-no-turbo.conf /etc/tmpfiles.d/omarchy-no-turbo.conf
sudo install -Dm755 bin/t2fans-high /usr/local/bin/t2fans-high
sudo install -Dm644 systemd/t2fans-high.service /etc/systemd/system/t2fans-high.service
sudo systemctl disable --now t2fanrd.service
sudo systemctl enable --now t2fans-high.service
sudo systemd-tmpfiles --create /etc/tmpfiles.d/omarchy-no-turbo.conf

# Quickshell plugins: ensure ~/.config/omarchy/shell.json references cure.*
omarchy-restart-shell   # or reboot
```

Review `limine/limine.conf` before copying it to `/boot` — it contains
machine-specific `PARTUUID` values and snapshot entries and is regenerated by
`limine-entry-tool`. Use `apply-limine-apple.sh` on a live system instead of
copying it directly.

## Notes

- The `.conf` files in `legacy/` are from Omarchy 3.x and are no longer read by
  Hyprland; Hyprland now loads the Lua files in `hypr/`.
- SSH `git@` auth may fail without an askpass helper; use HTTPS or `gh`.
