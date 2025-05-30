{
  description = "Noonix - NixOS Hyprland system with Catppuccin everything";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    revert-firmware.url = "github:NixOS/nixpkgs/5ed6b8e022f560b68f0d5503c42d48eb2f1469d7";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent";
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    self,
    nixpkgs,
    revert-firmware,
    home-manager,
    hyprland,
    catppuccin,
    nixos-hardware,
    hyprpolkitagent,
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    revertFirmware = revert-firmware.legacyPackages.${system};
  in {
    nixosConfigurations = {
      noonix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs system;};
        modules = [
          ./nixos/configuration.nix
          {
            nixpkgs.overlays = [
              (final: prev: {
                linux-firmware = revertFirmware.linux-firmware;
              })
            ];
          }
          catppuccin.nixosModules.catppuccin
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s # CHANGEME: check https://github.com/NixOS/nixos-hardware
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nielsing = {imports = [./home-manager/home.nix catppuccin.homeModules.catppuccin];};
            home-manager.extraSpecialArgs = {inherit inputs;};
          }
        ];
      };
    };
  };
}
