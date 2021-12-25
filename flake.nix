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

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, ...}: {
    nixosConfigurations = let
      mkSys = forceNoSecrets: deviceName: system: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # this adds a nur attribute set that can be used for example like this:
          #  ({ pkgs, ... }: {
          #    environment.systemPackages = [ pkgs.nur.repos.mic92.hello-nur ];
          #  })
          {
            nixpkgs.overlays = [
              nur.overlay
              (final: prev: {
                myTools = import ./common/lib deviceName;
              })
            ]; 

            # Source: https://github.com/malob/nixpkgs/blob/master/flake.nix
            # Hack to support legacy worklows that use `<nixpkgs>` etc.
            nix.nixPath = [
              # TODO is there a way to avoid this hardcoding? This is very much inpure
              # this assumes that the nixos-dotfiles repo is symlinked to /etc/nixos
              # if NIX_PATH is still not set properly, then use 'nix-index -f /etc/nixos/nixpkgs.nix' 
              "nixpkgs=/etc/nixos/nixpkgs.nix"
            ];
          }

          (import ./nixos/configuration.nix forceNoSecrets deviceName)

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
      nixos-lenovo-laptop = mkSys false "lenovo-laptop" "x86_64-linux";
      nixos-lenovo-laptop-no-sec = mkSys true "lenovo-laptop" "x86_64-linux";

      nixos-desktop = mkSys false "desktop" "x86_64-linux";
      nixos-desktop-no-sec = mkSys true "desktop" "x86_64-linux";

      nixos-virtualbox = mkSys true "virtualbox" "x86_64-linux";

    };
  };
}
