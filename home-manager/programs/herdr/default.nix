{...}: {
  programs.herdr = {
    enable = true;

    settings = {
      onboarding = false;
      keys = {
        prefix = "ctrl+a";
      };
    };
  };
}
