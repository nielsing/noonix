-- Programs
local terminal = "kitty"
local fileManager = "thunar"
local browser = "firefox"
local menu = "wofi --show drun"
local mainMod = "SUPER"

-- Monitors
hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "DP-7",
  mode = "preferred",
  position = "1920x0",
  scale = 1,
})

hl.monitor({
  output = "DP-9",
  mode = "preferred",
  position = "4480x0",
  scale = 1,
})

-- Cursor customization
hl.exec_cmd([[dconf write /org/gnome/desktop/interface/cursor-theme "'Catppuccin-Macchiato-Blue'"]])
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("XCURSOR_SIZE", "20")
hl.env("XCURSOR_THEME", "Catppuccin-Macchiato-Blue")

-- Core configuration
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 7,
    border_size = 3,
    col = {
      active_border = {
        colors = {
          "rgba(8aadf4ee)",
          "rgba(c6a0f6ee)",
        },
        angle = 45,
      },
      inactive_border = "rgba(363a4fee)",
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  cursor = {
    inactive_timeout = 1,
  },

  decoration = {
    rounding = 5,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
  },

  animations = {
    enabled = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    mouse_move_enables_dpms = true,
  },

  binds = {
    workspace_back_and_forth = true,
  },

  input = {
    kb_layout = "us,is",
    kb_options = "caps:swapescape,grp:alt_space_toggle",
    repeat_delay = 180,
    repeat_rate = 70,
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
      disable_while_typing = true,
    },
  },
})

-- Animations
hl.curve("myBezier", {
  type = "bezier",
  points = {
    { 0.05, 0.9 },
    { 0.1, 1.05 },
  },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

-- Gestures
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

-- Common actions
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Open programs, lock screen, and Mako actions
hl.bind("CTRL + ALT + F", hl.dsp.exec_cmd(browser))
hl.bind("CTRL + ALT + A", hl.dsp.exec_cmd(browser .. " --profile /home/nielsing/.mozilla/firefox/5jljoj7z.ambaga"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("spotify"))
hl.bind("CTRL + ALT + B", hl.dsp.exec_cmd("burpsuite"))
hl.bind("CTRL + ALT + C", hl.dsp.exec_cmd("makoctl dismiss -a"))
hl.bind("CTRL + ALT + D", hl.dsp.exec_cmd("@doNotDisturb@"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("@wofiPass@"))
hl.bind("CTRL + ALT + Space", hl.dsp.exec_cmd("@wofiCalc@"))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.exec_cmd("bemoji -t -n"))
hl.bind(mainMod .. " + CTRL + Space", hl.dsp.exec_cmd("cliphist list | wofi -p '📋' -S dmenu | cliphist decode | wl-copy -n"))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -z -m region --clipboard-only"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -z -m window"))

-- Move focus with mainMod + Vim keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Resize windows
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Move to the previous workspace
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }), { repeating = true })

-- Switch and move windows between workspaces
for workspace = 1, 10 do
  local key = workspace % 10

  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({
    workspace = workspace,
    follow = true,
  }))
  hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({
    workspace = workspace,
    follow = false,
  }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = true }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1", follow = true }))
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }))

-- Move and resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Window rules
hl.window_rule({
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  match = { class = [[^(org\.pulseaudio\.pavucontrol)$]] },
  float = true,
})
hl.window_rule({
  match = { class = [[^(org\.pulseaudio\.pavucontrol)$]] },
  center = true,
})
hl.window_rule({
  match = { class = [[^(org\.pulseaudio\.pavucontrol)$]] },
  size = { 950, 867 },
})

hl.window_rule({
  match = { class = [[^(.blueman-manager-wrapped)$]] },
  float = true,
})
hl.window_rule({
  match = { class = [[^(.blueman-manager-wrapped)$]] },
  center = true,
})
hl.window_rule({
  match = { class = [[^(.blueman-manager-wrapped)$]] },
  size = { 838, 657 },
})

hl.window_rule({
  match = { initial_class = [[^(jetbrains-studio)$]] },
  float = true,
})
hl.window_rule({
  match = { initial_class = [[^(jetbrains-studio)$]] },
  center = true,
})
hl.window_rule({
  match = { initial_class = [[^(Emulator)$]] },
  float = true,
})

-- Workspace rules
hl.window_rule({
  match = { class = [[^(Slack)$]] },
  workspace = "1",
})
hl.window_rule({
  match = { class = [[^(discord)$]] },
  workspace = "1",
})
hl.window_rule({
  match = { class = [[^(Spotify)$]] },
  workspace = "1",
})
hl.window_rule({
  match = { class = [[^(burp-StartBurp)$]] },
  workspace = "5",
})

-- Hyperspecific rules
hl.window_rule({
  match = {
    float = true,
    class = [[^(kitty)$]],
  },
  size = { 120, 30 },
})

hl.window_rule({
  match = {
    initial_class = [[^(Emulator)$]],
    initial_title = [[(Android Emulator - .*)$]],
  },
  size = { 508, 1099 },
})

hl.window_rule({
  match = {
    initial_class = [[^(Emulator)$]],
    initial_title = [[(Android Emulator - .*)$]],
  },
  move = { 113, 164 },
})

