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
- **Shell:** Omarchy Quickshell bar/menu (with a built-in calculator and
  unit/currency conversion), plus custom `cure.*` plugins
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
- **Hybrid graphics** — the Intel iGPU is the primary display adapter
  (`modprobe.d/apple-gmux.conf` + `apple_gmux.force_igd=1`), and the AMD dGPU
  is powered off at boot by `systemd/amdgpu-off.service` (vgaswitcheroo). This
  is what makes suspend/resume actually work; see
  [Hybrid graphics](#hybrid-graphics-igpu-primary-dgpu-off).
- **Fans** — held at a fixed **75% of max** while awake, by `bin/t2fans-high`
  + `systemd/t2fans-high.service`; stopped outright during suspend by
  `systemd/system-sleep/99-t2fans-suspend` (see
  [Thermal tuning](#thermal-tuning-turbo-boost--fans)).
- **Boot** — `limine/limine-entry-tool.d/t2-mac.conf` adds
  `intel_iommu=on iommu=pt pm_async=off pcie_ports=compat mem_sleep_default=s2idle apple_gmux.force_igd=1 i915.enable_guc=3`,
  and `omarchy-defaults.conf` keeps T2 Macs on `linux-t2` via the `BOOT_ORDER`.
- **Suspend** — forced to `s2idle` because this T2's advertised S3 `deep` state
  does not hold (see [Suspend](#suspend-lid-close)); resume only works once the
  dGPU is off. Fans are silenced for the sleep by the same section.
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
| `cure.menu` | Omarchy command menu with inline calculator + unit/currency conversion |
| `cure.workspaces` | Workspace number indicators |

### Calculator & conversion in the menu

`cure.menu` has a calculator and unit/currency converter built into its search
box, so no separate launcher is needed. Start typing an expression and the
answer is pinned above the normal matches as its own row; press Enter to copy
it to the clipboard. It is backed by [`qalc`](https://qalculate.github.io/)
(`libqalculate`, already present as an Omarchy dependency).

```text
2+2*3              → = 8
(1920/2)/1.6       → = 600
sqrt(2)            → = 1.414213562
10 miles to km     → = 16.09344 km
100 km/h to mph    → = 62.13711922 mph
1 GiB to MB        → = 1073.741824 MB
150 USD to EUR     → = €132.10 EUR   (live exchange rate)
```

The trigger is deliberately conservative so the launcher does not mistake app
names or prose for math:

- Bare numbers, dates (`2024-06-01`), and words without a digit are ignored.
- A conversion only fires on the `<number> <unit> to|in <unit>` shape, so
  phrases like "log in" are not sent to qalc.
- Results that look like unit products (`1 g·pt − 4`) are discarded, and a
  result containing letters is only shown for an explicit conversion.

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
modprobe.d/
  apple-gmux.conf                     Forces the Intel iGPU as the display adapter
systemd/
  sleep.conf.d/                       Forces freeze/s2idle suspend
  amdgpu-off.service                  Powers off the AMD dGPU at boot (vgaswitcheroo)
  system-sleep/99-t2fans-suspend      Stops the fans during suspend, restores after
  t2fans-high.service                 Pins both fans at a fixed speed
bin/
  t2fans-high                         Fan-pinning script (/usr/local/bin)
tmpfiles.d/
  omarchy-no-turbo.conf               Disables Intel Turbo Boost at boot
legacy/               Pre-4.x .conf configs (kept for reference)
```

## Hybrid graphics (iGPU primary, dGPU off)

Out of the box the AMD dGPU is the firmware-default display adapter, so it has
to stay powered on. That is both the heat/battery problem and, on this machine,
the reason suspend hangs. The fix is two parts:

1. **Make the iGPU primary** via `modprobe.d/apple-gmux.conf`
   (`options apple-gmux force_igd=y`) and the `apple_gmux.force_igd=1` kernel
   parameter. After that the panel (`card1-eDP-1`) hangs off i915.
2. **Power the dGPU off** at boot with `systemd/amdgpu-off.service`, which
   writes `OFF` to `/sys/kernel/debug/vgaswitcheroo/switch`. Verify with
   `sudo cat /sys/kernel/debug/vgaswitcheroo/switch` → `IGD + Pwr`, `DIS Off`.

`i915.enable_guc=3` is also set (Gen9 ignores GuC *submission*, but HuC loads
and authenticates, which helps the display come back after resume).

```bash
sudo install -Dm644 modprobe.d/apple-gmux.conf /etc/modprobe.d/apple-gmux.conf
sudo install -Dm644 systemd/amdgpu-off.service /etc/systemd/system/amdgpu-off.service
sudo systemctl daemon-reload
sudo systemctl enable amdgpu-off.service
```

> Run this in two steps the first time: boot with the iGPU params and confirm
> the desktop comes up on i915 *before* enabling `amdgpu-off.service`.

## Suspend (lid close)

Lid-close sleep on this T2 only works as **s2idle**, and only once the dGPU is
off:

1. **Force `s2idle`, not `deep`.** The kernel advertises S3 `deep`, but on this
   T2 it does not hold: a deep suspend sits there with the fans on and then the
   machine powers itself off (tested repeatedly, including with the dGPU
   disabled — `rtcwake -m mem` never returned). Set `mem_sleep_default=s2idle`
   (boot) and the `[Sleep]` drop-in (`SuspendState=freeze`,
   `MemorySleepMode=s2idle`).
2. **The dGPU must be off for resume to work.** With the AMD dGPU as the
   primary adapter, s2idle resume hangs; with the iGPU primary and the dGPU
   disabled, `PM: suspend entry` → `PM: suspend exit` completes cleanly.
   See [Hybrid graphics](#hybrid-graphics-igpu-primary-dgpu-off).
3. **Silence the fans during sleep.** `t2fans-high` keeps the fans in manual
   mode at 75%, which the SMC holds through s2idle, so the fans stay on for the
   whole sleep. `systemd/system-sleep/99-t2fans-suspend` drops the manual
   target to 0 on suspend (stopping the fans) and restores 75% on resume.
4. **Make sure the parameter actually reaches the kernel.** `/etc/default/limine`
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
ramping. `systemd/t2fans-high.service` runs it once at boot and
`Conflicts=t2fanrd.service` so the curve daemon cannot fight it.

On this machine that pins fan1 to 4212 RPM (75% of 5616) and fan2 to 3900 RPM
(75% of 5200). There is no working "automatic" mode to fall back to: releasing
manual control (`fan*_manual=0`) makes the SMC ramp both fans to maximum,
because Linux has no macOS thermal handshake. A target of `0` *does* stop them,
which is what the suspend hook uses.

`systemd/system-sleep/99-t2fans-suspend` stops the fans for the duration of
s2idle: it drops the manual target to 0 on `pre` and restores 75% on `post`
(releasing manual control instead would cause the max-speed ramp above).

```bash
sudo install -Dm755 bin/t2fans-high /usr/local/bin/t2fans-high
sudo install -Dm644 systemd/t2fans-high.service /etc/systemd/system/t2fans-high.service
sudo install -Dm755 systemd/system-sleep/99-t2fans-suspend /usr/lib/systemd/system-sleep/99-t2fans-suspend
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

# Boot cmdline (T2 params + s2idle + iGPU), drop-ins, and sleep mode need root
sudo cp limine/default-limine /etc/default/limine
sudo cp limine/limine-entry-tool.d/*.conf /etc/limine-entry-tool.d/
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo cp systemd/sleep.conf.d/*.conf /etc/systemd/sleep.conf.d/
sudo limine-mkinitcpio   # rebuild the UKI with the new cmdline

# Hybrid graphics: iGPU primary + dGPU off. See that section for the two-step
# first-run caveat.
sudo install -Dm644 modprobe.d/apple-gmux.conf /etc/modprobe.d/apple-gmux.conf
sudo install -Dm644 systemd/amdgpu-off.service /etc/systemd/system/amdgpu-off.service
sudo systemctl daemon-reload
sudo systemctl enable amdgpu-off.service

# Thermal tuning (Turbo Boost off + fans pinned). See that section for details.
sudo install -Dm644 tmpfiles.d/omarchy-no-turbo.conf /etc/tmpfiles.d/omarchy-no-turbo.conf
sudo install -Dm755 bin/t2fans-high /usr/local/bin/t2fans-high
sudo install -Dm644 systemd/t2fans-high.service /etc/systemd/system/t2fans-high.service
sudo install -Dm755 systemd/system-sleep/99-t2fans-suspend /usr/lib/systemd/system-sleep/99-t2fans-suspend
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
