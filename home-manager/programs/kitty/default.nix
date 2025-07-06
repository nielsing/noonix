{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    shellIntegration.enableZshIntegration = true;
  };
}
