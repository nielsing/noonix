{ ... }: {
  services.mako = {
    enable = true;
    borderSize = 3;
    borderRadius = 5;
    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1
    '';
  };
}
