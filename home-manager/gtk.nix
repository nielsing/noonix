{pkgs, ...}: {
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "catppuccin-macchiato-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        variant = "macchiato";
      };
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
