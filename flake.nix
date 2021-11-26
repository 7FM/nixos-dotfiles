{
  description = "System config flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, ...}: {
    nixosConfigurations = let
      mkSys = deviceName: system: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # this adds a nur attribute set that can be used for example like this:
          #  ({ pkgs, ... }: {
          #    environment.systemPackages = [ pkgs.nur.repos.mic92.hello-nur ];
          #  })
          { nixpkgs.overlays = [ nur.overlay ]; }

          (import ./nixos/configuration.nix deviceName)

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tm = import ./home-manager/home.nix;

            home-manager.extraSpecialArgs = {
              inherit deviceName;
            };
          }
        ];
      };
    in {

      # Define systems
      nixos-lenovo-laptop = mkSys "lenovo-laptop" "x86_64-linux";
      nixos-desktop = mkSys "desktop" "x86_64-linux";
      nixos-virtualbox = mkSys "virtualbox" "x86_64-linux";

    };
  };
}
