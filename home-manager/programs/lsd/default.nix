{
  config,
  pkgs,
  ...
}: {
  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      icons.when = "never";
    };
  };
}
