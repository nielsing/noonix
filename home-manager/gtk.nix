{
  config,
  pkgs,
  ...
}: {
  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
      icon.enable = true;
    };
  };
}
