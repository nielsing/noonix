{
  config,
  pkgs,
  ...
}: {
  services.mako = {
    enable = true;
    catppuccin.enable = true;
    borderSize = 3;
    borderRadius = 5;
  };
}
