{
  description = "Noonix - NixOS Hyprland system with Catppuccin everything";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    catppuccin,
    nixos-hardware,
    ...
  } @ inputs: {
    nixosConfigurations = {
      noonix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};

        modules = [
          ./nixos/configuration.nix
          catppuccin.nixosModules.catppuccin
          nixos-hardware.nixosModules.lenovo-thinkpad-t14s # CHANGEME: check https://github.com/NixOS/nixos-hardware
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nielsing.imports = [
              ./home-manager/home.nix 
              catppuccin.homeModules.catppuccin
            ];
            home-manager.extraSpecialArgs = {inherit inputs;};
          }
        ];
      };
    };
  };
}
