{...}: {
  imports = [
    ./cliphist
    ./hypridle
    ./hyprpaper
    ./hyprsunset
    ./mako
  ];

  services = {
    hyprpolkitagent.enable = true;
    network-manager-applet.enable = true;
    blueman-applet.enable = true;
  };

  # Makes nm-applet use the indicator protocol supported by Waybar.
  xsession.preferStatusNotifierItems = true;

  systemd.user.services = {
    hyprpolkitagent.Service = {
      Restart = "on-failure";
      RestartSec = "2s";
    };

    network-manager-applet.Service = {
      Restart = "on-failure";
      RestartSec = "2s";
    };

    blueman-applet.Service = {
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
