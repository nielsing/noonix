{
  config,
  pkgs,
  ...
}: {
  home.username = "nielsing";
  home.homeDirectory = "/home/nielsing";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  imports = [
    ./catppuccin.nix
    ./gtk.nix
    ./programs
    ./services
    ./qt.nix
    ./xdg.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.catppuccin-cursors.macchiatoBlue;
    name = "Catppuccin-Macchiato-Blue";
    size = 24;
  };

  catppuccin.accent = "blue";
  catppuccin.flavor = "macchiato";

  programs.home-manager.enable = true;
}
