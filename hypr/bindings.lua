-- Personal keybinding overrides, ported from the pre-Quattro
-- "opinionated-omarchy" bindings.conf (github.com/CurePortal/opinionated-omarchy).
--
-- Hyprland now reads this Lua file instead of bindings.conf.
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Send a chord to the focused surface (the compositor-native replacement for
-- the old `bind = ..., sendshortcut, ...`). Down/up are split because a single
-- send_shortcut can leave synthetic key state stuck/repeating.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- ---------------------------------------------------------------------------
-- Keys that Quattro binds by default and that these overrides replace.
-- ---------------------------------------------------------------------------
hl.unbind("SUPER + W")            -- was: close window
hl.unbind("SUPER + T")            -- was: toggle window floating/tiling
hl.unbind("SUPER + 0")            -- was: switch to workspace 10
hl.unbind("SUPER + SHIFT + S")    -- was: Google Maps webapp
hl.unbind("SUPER + SHIFT + P")    -- was: Google Photos webapp
hl.unbind("SUPER + SHIFT + D")    -- was: Docker TUI
hl.unbind("SUPER + SHIFT + G")    -- was: Signal
hl.unbind("SUPER + SHIFT + O")    -- was: Obsidian (default launcher)
hl.unbind("SUPER + SHIFT + SLASH") -- was: 1Password
hl.unbind("SUPER + CTRL + Z")     -- was: Zoom in
hl.unbind("XF86KbdBrightnessUp")  -- was: omarchy keyboard brightness
hl.unbind("XF86KbdBrightnessDown")

-- ---------------------------------------------------------------------------
-- Application bindings
-- ---------------------------------------------------------------------------
-- These keys keep Omarchy's stock bindings (SUPER+RETURN terminal,
-- SUPER+ALT+RETURN tmux, SUPER+SHIFT+RETURN browser, SUPER+SHIFT+F nautilus,
-- SUPER+SHIFT+B browser, SUPER+SHIFT+ALT+B private, SUPER+SHIFT+Y YouTube),
-- so they are intentionally NOT redefined here to avoid double launches.

-- Overrides of stock bindings (each has a matching hl.unbind above).
o.bind("SUPER + SHIFT + O", "Obsidian", 'omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime"')
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- keepassxc")
o.bind("SUPER + SHIFT + D", "Blender", "blender")
o.bind("SUPER + SHIFT + G", "Gemini", 'omarchy-launch-webapp "https://gemini.google.com"')
o.bind("SUPER + SHIFT + P", "Photoshop", "krita --nosplash")
o.bind("SUPER + SHIFT + S", "Screenshot Region to Clipboard", 'grim -g "$(slurp)" - | wl-copy')

-- ---------------------------------------------------------------------------
-- Window controls / misc
-- ---------------------------------------------------------------------------
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + Y", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

-- Ctrl chords sent to the focused window (old sendshortcut bindings).
o.bind("SUPER + T", "Send Ctrl+T", send_shortcut_once("CTRL", "T"))
o.bind("SUPER + A", "Send Ctrl+A", send_shortcut_once("CTRL", "A"))

-- KeepassXC special workspace.
o.bind("SUPER + 0", "KeePass workspace", hl.dsp.workspace.toggle_special("keepass"))

-- Keyboard backlight (old `binde` = repeating) on the white:kbd_backlight device.
o.bind(
  "XF86KbdBrightnessUp",
  "Keyboard brightness up",
  "brightnessctl --device=':white:kbd_backlight' set +10%",
  { repeating = true, locked = true }
)
o.bind(
  "XF86KbdBrightnessDown",
  "Keyboard brightness down",
  "brightnessctl --device=':white:kbd_backlight' set 10%-",
  { repeating = true, locked = true }
)

-- Whisper dictation toggle.
-- Whis's setup instructions suggest Ctrl+Alt+W; bound to Super+Option(Alt)+Z instead.
o.bind("SUPER + ALT + Z", "Toggle Whis", "flatpak run ink.whis.Whis --toggle")

-- Swallow the bare function keys (old config bound them to `exec, true`).
for _, key in ipairs({ "F1", "F3", "F5", "F6", "F7", "F10", "F11", "F12" }) do
  hl.bind(key, hl.dsp.no_op())
end
