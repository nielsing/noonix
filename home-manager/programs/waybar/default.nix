{...}: {
  programs.waybar = {
    enable = true;
    settings = [
      {
        position = "top";
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = [
          "network"
          "pulseaudio"
          "battery"
          "hyprland/language"
          "clock"
          "tray"
        ];

        "network" = {
          "format-wifi" = "<span size='11000' foreground='#8aadf4'>  </span>{essid}";
          "format-ethernet" = "<span size='11000' foreground='#8aadf4'>󰈀  </span> Wired";
          "format-linked" = "<span size='11000' foreground='#eed49f'>󰈀  </span>{ifname} (No IP)";
          "format-disconnected" = "<span size='11000' foreground='#ed8796'>󰤭  </span>Disconnected";
          "tooltip-format-wifi" = "Signal Strenght: {signalStrength}%";
        };

        "battery" = {
          "states" = {
            "warning" = 25;
            "critical" = 15;
          };
          "format" = "<span size='11000' foreground='#a6da95'>{icon} </span> {capacity}%";
          "format-warning" = "<span size='11000' foreground='#eed49f'>{icon} </span> {capacity}%";
          "format-critical" = "<span size='11000' foreground='#ed8796'>{icon} </span> {capacity}%";
          "format-charging" = "<span size='11000' foreground='#a6da95'> </span>{capacity}%";
          "format-plugged" = "<span size='11000' foreground='#a6da95'> </span>{capacity}%";
          "format-alt" = "<span size='11000' foreground='#a6da95'>{icon} </span> {time}";
          "format-full" = "<span size='11000' foreground='#a6da95'> </span>{capacity}%";
          "format-icons" = ["" "" "" "" ""];
          "tooltip-format" = "{time}";
        };

        "clock" = {
          "format" = "<span foreground='#c6a0f6'>  </span>{:%a %d %H:%M}";
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "pulseaudio" = {
          "format" = "{icon} {volume}%";
          "format-muted" = " {volume}%";
          "format-icons" = {
            "default" = ["" "" " "];
          };
          "on-click" = "pavucontrol";
        };

        "hyprland/language" = {
          format = "{}";
          format-en = "🇺🇸🦅";
          format-is = "🇮🇸🦈";
        };

        "tray" = {
          "icon-size" = 19;
          "spacing" = 5;
        };
      }
    ];

    style = ''
      * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12px;
          min-height: 0;
          font-weight: bold;
      }

      window#waybar {
          background: transparent;
          background-color: @base;
          color: @overlay0;
          transition-property: background-color;
          transition-duration: 0.1s;
      }

      #window {
          margin: 8px;
          padding-left: 8;
          padding-right: 8;
      }

      button {
          box-shadow: inset 0 -3px transparent;
          border: none;
          border-radius: 0;
      }

      #workspaces {
          margin-top: 2px;
          margin-bottom: 2px;
          padding-left: 5px;
          padding-right: 5px;
      }

      #workspaces button {
          padding: 0 4px;
          border-bottom: 2px solid @text
      }

      #workspaces button:hover {
          background: inherit;
          color: @mauve;
          border-bottom: 2px solid @mauve;
      }

      #workspaces button.focused {
          background-color: @mantle;
          color: @rosewater;
          border-bottom: 2px solid @rosewater;
      }

      #workspaces button.active {
          background-color: @mantle;
          color: @blue;
          border-bottom: 2px solid @blue;
      }

      #workspaces button.urgent {
          background-color: @mantle;
          color: @red;
          border-bottom: 2px solid @red;
      }

      #pulseaudio,
      #clock,
      #language,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #wireplumber,
      #tray,
      #network,
      #mode,
      #scratchpad {
        margin-top: 2px;
        margin-bottom: 2px;
        margin-left: 5px;
        margin-right: 5px;
        padding-left: 5px;
        padding-right: 5px;
      }

      #clock {
          color: @mauve;
          border-bottom: 2px solid @mauve;
      }

      #language {
          color: @peach;
          border-bottom: 2px solid @peach;
      }

      #clock.date {
          color: @mauve;
          border-bottom: 2px solid @mauve;
      }

      #pulseaudio {
          color: @flamingo;
          border-bottom: 2px solid @flamingo;
      }

      #network {
          color: @blue;
          border-bottom: 2px solid @blue;
      }

      #idle_inhibitor {
          margin-right: 12px;
          color: #7cb342;
      }

      #idle_inhibitor.activated {
          color: @red;
      }

      #battery {
          color: @green;
          border-bottom: 2px solid @green;
      }

      #battery.warning:not(.charging) {
          color: @yellow;
          border-bottom: 2px solid @yellow;
      }

      #battery.critical:not(.charging) {
          color: @red;
          border-bottom: 2px solid @red;
      }

      #tray {
          border-bottom: 2px solid @text;
      }

      /* If workspaces is the leftmost module, omit left margin */
      .modules-left>widget:first-child>#workspaces {
          margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
      .modules-right>widget:last-child>#workspaces {
          margin-right: 0;
      }
    '';
  };
}
