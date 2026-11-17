{...}: {
  programs.herdr = {
    enable = true;

    settings = {
      onboarding = false;

      keys.prefix = "ctrl+a";

      ui = {
        status_indicators = "symbols";
        toast.delivery = "system";
      };
    };
  };
}
