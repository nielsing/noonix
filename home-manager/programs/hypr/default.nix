{
  config,
  lib,
  pkgs,
  ...
}: let
  passwordStoreDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;

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
        notify-send --expire-time 5000 "Notifications turned on"
      else
        notify-send --expire-time 5000 "Notifications turned off"
        sleep 1
      fi

      makoctl mode -t do-not-disturb
    '';
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;

    # Installed and managed by NixOS
    package = null;
    portalPackage = null;

    configType = "lua";

    extraLuaFiles."config" = {
      content =
        builtins.replaceStrings
        [
          "@doNotDisturb@"
          "@wofiPass@"
          "@wofiCalc@"
        ]
        [
          "${doNotDisturb}/bin/do-not-disturb"
          "${wofiPassScript}/bin/wofi-pass"
          "${wofiCalcScript}/bin/wofi-calc"
        ]
        (builtins.readFile ./config.lua);
      autoLoad = true;
    };
  };
}
