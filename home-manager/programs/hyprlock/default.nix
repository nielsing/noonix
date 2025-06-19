{...}: {
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      # BACKGROUND
      background {
          path = ~/pics/ambaga-bg.jpg
          blur_passes = 2
          color = $base
      }
    '';
  };
}
