{inputs, ...}: {
  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Used for nixd LSP
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    registry.nixpkgs.flake = inputs.nixpkgs;

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };
}
