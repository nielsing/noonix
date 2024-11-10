{
  config,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    catppuccin.enable = true;
  };
}
