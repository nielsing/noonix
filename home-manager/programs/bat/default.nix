{
  config,
  pkgs,
  ...
}: {
  programs.bat = {
    enable = true;
    catppuccin.enable = true;
  };
}
