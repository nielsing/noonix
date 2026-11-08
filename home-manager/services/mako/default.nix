{...}: {
  services.mako = {
    enable = true;

    settings = {
      border-radius = 5;
      border-size = 3;

      "mode=do-not-disturb" = {
        invisible = true;
      };
    };
  };
}
