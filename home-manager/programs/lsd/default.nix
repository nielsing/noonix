{
  config,
  pkgs,
  ...
}: {
  programs.lsd = {
    enable = true;
    enableAliases = true;
    settings = {
      icons.when = "never";
    };
  };
}
