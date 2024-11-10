{
  config,
  pkgs,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = ["~/pics/catppuccin-smile.png"];
      wallpaper = [", ~/pics/catppuccin-smile.png"];
    };
  };
}
