{
  inputs,
  ...
}: {
  programs.nix-ld.enable = true;
  nixpkgs.config = {
    allowUnfree = true;
  };
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    # Used for nixd LSP
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
