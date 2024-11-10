{pkgs, ...}: {
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "nielsing";
      };
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "nielsing";
      };
    };
  };
}
