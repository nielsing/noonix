{
  config,
  lib,
  pkgs,
  ...
}: let
  passwordStoreDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;

  startupScript = pkgs.pkgs.writeShellScriptBin "startup" ''
    systemctl --user start hyprpolkitagent
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator &
    blueman-applet &
  '';

  wofiPassScript = pkgs.writeShellApplication {
    name = "wofi-pass";

    runtimeInputs = [
      config.programs.password-store.package
      pkgs.fd
      pkgs.gnused
      pkgs.libnotify
      pkgs.wl-clipboard
      pkgs.wofi
    ];

    text = ''
      export PASSWORD_STORE_DIR=${lib.escapeShellArg passwordStoreDir}

      selected="$(
        fd \
          --base-directory "$PASSWORD_STORE_DIR" \
          --type f \
          --extension gpg \
          . \
          | sed 's|\.gpg$||' \
          | wofi --prompt pass --show dmenu
      )" || exit 0

      [[ -n "$selected" ]] || exit 0

      if pass show "$selected" \
        | sed -n '1p' \
        | wl-copy --sensitive --trim-newline
      then
        notify-send -t 5000 \
          "Password copied" \
          "$selected"
      else
        notify-send -u critical -t 5000 \
          "Could not copy password"
        exit 1
      fi
    '';
  };

  wofiCalcScript = pkgs.writeShellApplication {
    name = "wofi-calc";

    runtimeInputs = with pkgs; [
      coreutils
      gnused
      libqalculate
      wl-clipboard
      wofi
    ];

    text = ''
      result_directory="''${XDG_CONFIG_HOME:-"$HOME/.config"}/qalculate"
      result_file="$result_directory/qalc.result.history"
      last_input=""

      while true; do
        history=""

        if [[ -f "$result_file" ]]; then
          history="$(tail -n 1000 -- "$result_file" | tac)"
        fi

        if wofi_result="$(
          wofi \
            --dmenu \
            --prompt calc \
            --sort-order default \
            --cache-file /dev/null \
            <<< "$history"
        )"; then
          if [[ "$wofi_result" == *"="* ]]; then
            result="$(awk '{ print $NF }' <<< "$wofi_result")"
            printf '%s' "$result" | wl-copy
            exit 0
          fi

          calculation="$(qalc "$wofi_result")"
          last_input="$wofi_result"

          mkdir -p -- "$result_directory"
          printf '%s\n' "$calculation" >> "$result_file"
        else
          if [[ -n "$last_input" ]]; then
            result="$(qalc -t "$last_input")"
            printf '%s' "$result" | wl-copy
          fi

          exit 0
        fi
      done
    '';
  };

  doNotDisturb = pkgs.writeShellApplication {
    name = "do-not-disturb";

    runtimeInputs = with pkgs; [
      libnotify
      mako
    ];

    text = ''
      if [[ "$(makoctl mode)" == *"do-not-disturb"* ]]; then
        message="Notifications turned on"
      else
        message="Notifications turned off"
      fi

      notify-send --expire-time 5000 "$message"
      makoctl mode --toggle do-not-disturb
    '';
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;

    # Installed and managed by NixOS
    package = null;
    portalPackage = null;

    configType = "hyprlang";
    extraConfig = ''
      # Default monitor
      monitor = eDP-1,preferred,0x0,1
      monitor = DP-7,preferred,1920x0,1
      monitor = DP-9,preferred,4480x0,1
      # monitor = DP-10,preferred,4480x0,1

      # Default programs
      $terminal = kitty
      $fileManager = thunar
      $browser = firefox
      $editor = nvim
      $menu = wofi --show drun

      # Autostart
      exec-once = ${startupScript}/bin/startup # Start everything after login

      # Cursor customization
      #exec-once = hyprctl setcursor "Catppuccin-Macchiato-Blue" 24
      exec = dconf write /org/gnome/desktop/interface/cursor-theme "'Catppuccin-Macchiato-Blue'"
      env = HYPRCURSOR_SIZE,20
      env = XCURSOR_SIZE,20
      env = XCURSOR_THEME,Catppuccin-Macchiato-Blue

      # Look & feel
      general {
        gaps_in = 3
        gaps_out = 7
        border_size = 3

        #col.active_border = rgba($blueAlphaee) rgba($mauveAlphaee) 45deg
        #col.inactive_border = rgba($surface0Alphaee)
        col.active_border = rgba(8aadf4ee) rgba(c6a0f6ee) 45deg
        col.inactive_border = rgba(363a4fee)

        resize_on_border = false
        allow_tearing = false
        layout = dwindle
      }

      cursor {
        inactive_timeout = 1
      }

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration {
        rounding = 5

        # Change transparency of focused and unfocused windows
        active_opacity = 1.0
        inactive_opacity = 1.0

        shadow {
          enabled = true
                range = 4
                render_power = 3
                color = rgba(1a1a1aee)
        }
      }

      # https://wiki.hyprland.org/Configuring/Variables/#animations
      animations {
        enabled = true

        # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
      }

      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      master {
        new_status = master
      }

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc {
        force_default_wallpaper = 0
        disable_hyprland_logo = true
        disable_splash_rendering = true
        mouse_move_enables_dpms = true
      }

      binds {
        workspace_back_and_forth = true
      }

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input {
          kb_layout = us,is
          kb_options = caps:swapescape,grp:alt_space_toggle
          repeat_delay = 180
          repeat_rate = 70
          follow_mouse = 1
          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

          touchpad {
            natural_scroll = false
            disable_while_typing = true
          }
      }

      # Gestures
      # https://wiki.hypr.land/Configuring/Gestures/
      gesture = 3, horizontal, workspace

      # See https://wiki.hyprland.org/Configuring/Keywords/
      $mainMod = SUPER

      # See https://wiki.hyprland.org/Configuring/Binds/ for more
      ## Common actions
      bind = $mainMod, Space, exec, $menu
      bind = $mainMod, Return, exec, $terminal
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, W, killactive,
      bind = $mainMod, T, togglefloating,
      bind = $mainMod, F, fullscreen
      # bind = $mainMod, P, pseudo, # dwindle
      # bind = $mainMod, J, togglesplit, # dwindle

      # Open programs, lock screen and mako stuff
      bind = CTRL ALT, F, exec, firefox
      bind = CTRL ALT, A, exec, firefox --profile /home/nielsing/.mozilla/firefox/5jljoj7z.ambaga
      bind = CTRL ALT, L, exec, hyprlock
      bind = CTRL ALT, S, exec, spotify
      bind = CTRL ALT, B, exec, burpsuite
      bind = CTRL ALT, C, exec, makoctl dismiss -a
      bind = CTRL ALT, D, exec, ${doNotDisturb}/bin/do-not-disturb
      bind = CTRL ALT, P, exec, ${wofiPassScript}/bin/wofi-pass
      bind = CTRL ALT, Space, exec, ${wofiCalcScript}/bin/wofi-calc
      bind = $mainMod SHIFT, Space, exec, bemoji -t -n
      bind = $mainMod CTRL, Space, exec, cliphist list | wofi -p '📋' -S dmenu | cliphist decode | wl-copy -n

      # Special Keys
      ## Volume
      binde = , XF86AudioRaiseVolume, exec, pamixer -i 5
      binde = , XF86AudioLowerVolume, exec, pamixer -d 5
      bind = , XF86AudioMute, exec, pamixer -t

      ## Brightness
      binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
      binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

      ## Print screen
      bind = , PRINT, exec, hyprshot -z -m region --clipboard-only
      bind = $mainMod, PRINT, exec, hyprshot -z -m window

      # Move focus with mainMod + vim keys
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, L, movefocus, r
      bind = $mainMod, K, movefocus, u
      bind = $mainMod, J, movefocus, d

      # Move windows
      bind = $mainMod SHIFT, H, movewindow, l
      bind = $mainMod SHIFT, L, movewindow, r
      bind = $mainMod SHIFT, K, movewindow, u
      bind = $mainMod SHIFT, J, movewindow, d

      # Resize windows
      binde = $mainMod CTRL, H, resizeactive,-50 0
      binde = $mainMod CTRL, L, resizeactive,50 0
      binde = $mainMod CTRL, K, resizeactive,0 -50
      binde = $mainMod CTRL, J, resizeactive,0 50

      # Move to previous workspace
      binde = $mainMod, Tab, workspace, previous

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
      bind = $mainMod SHIFT, bracketleft, movetoworkspace, -1
      bind = $mainMod SHIFT, bracketright, movetoworkspace, +1

      # Move active window to a workspace with mainMod + CTRL + [0-9] silent
      bind = $mainMod CTRL, 1, movetoworkspacesilent, 1
      bind = $mainMod CTRL, 2, movetoworkspacesilent, 2
      bind = $mainMod CTRL, 3, movetoworkspacesilent, 3
      bind = $mainMod CTRL, 4, movetoworkspacesilent, 4
      bind = $mainMod CTRL, 5, movetoworkspacesilent, 5
      bind = $mainMod CTRL, 6, movetoworkspacesilent, 6
      bind = $mainMod CTRL, 7, movetoworkspacesilent, 7
      bind = $mainMod CTRL, 8, movetoworkspacesilent, 8
      bind = $mainMod CTRL, 9, movetoworkspacesilent, 9
      bind = $mainMod CTRL, 0, movetoworkspacesilent, 10
      bind = $mainMod CTRL, bracketleft, movetoworkspacesilent, -1
      bind = $mainMod CTRL, bracketright, movetoworkspacesilent, +1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      # Window Rules
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules
      windowrule = suppress_event maximize, match:class .*

      # Windows we want to float & possibly center
      windowrule = float on, match:class ^(org\.pulseaudio\.pavucontrol)$
      windowrule = center on, match:class ^(org\.pulseaudio\.pavucontrol)$
      windowrule = size 950 867, match:class ^(org\.pulseaudio\.pavucontrol)$
      windowrule = float on, match:class ^(.blueman-manager-wrapped)$
      windowrule = center on, match:class ^(.blueman-manager-wrapped)$
      windowrule = size 838 657, match:class ^(.blueman-manager-wrapped)$
      windowrule = float on, match:initial_class ^(jetbrains-studio)$
      windowrule = center on, match:initial_class ^(jetbrains-studio)$
      windowrule = float on, match:initial_class ^(Emulator)$

      # Workspace rules
      windowrule = workspace 1, match:class ^(Slack)$
      windowrule = workspace 1, match:class ^(discord)$
      windowrule = workspace 1, match:class ^(Spotify)$
      windowrule = workspace 5, match:class ^(burp-StartBurp)$

      # Hyperspecific rules
      windowrule = size 120 30, match:float true, match:class ^(kitty)$
      windowrule = size 508 1099, match:initial_class ^(Emulator), match:initial_title (Android Emulator - .*)$
      windowrule = move 113 164, match:initial_class ^(Emulator), match:initial_title (Android Emulator - .*)$
    '';
  };
}
