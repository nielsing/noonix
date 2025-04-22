{
  config,
  pkgs,
  ...
}: {
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      # BACKGROUND
      background {
          path = ~/pics/mandelbrot.png
          blur_passes = 2
          color = $base
      }
    '';
  };
}
