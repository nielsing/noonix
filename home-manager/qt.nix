{
  config,
  pkgs,
  ...
}: {
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
    };
  };
}
