{
  config,
  pkgs,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = ["~/pics/mandelbrot.png"];
      wallpaper = [", ~/pics/mandelbrot.png"];
    };
  };
}
