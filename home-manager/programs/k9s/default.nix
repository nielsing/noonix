{
  config,
  pkgs,
  ...
}: {
  programs.k9s = {
    enable = true;
    catppuccin.enable = true;
  };
}
