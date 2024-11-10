{
  config,
  pkgs,
  ...
}: {
  programs.ruff = {
    enable = true;
    settings = {};
  };
}
