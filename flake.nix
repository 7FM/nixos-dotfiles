{
  description = "System config flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    #nixpkgs.url = "nixpkgs/nixpkgs-unstable";
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

    drynomore = {
      url = "github:7FM/DryNoMore";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmdbot = {
      url = "github:7FM/TMDBot";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "drynomore/flake-utils";
    };
  };

  outputs = { self, nixos-hardware, nixpkgs, home-manager, nur, drynomore, tmdbot, ...}@inputs: {
    nixosConfigurations = let
      mkSys = {deviceName, system ? "x86_64-linux", userName ? "tm", customModules ? [], nixpkgsOverlays ? [], forceNoSecrets ? false}: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          {
            nixpkgs.overlays = [
              # NUR overlay
              nur.overlays.default
              #nur.modules.nixos.default
              # my custom tools
              (final: prev: {
                myTools = import ./common/lib deviceName;

                drynomore = drynomore.packages."${system}".default;
                tmdbot = tmdbot.packages."${system}".default;

                # waybar: enable experimental features
                waybar = prev.waybar.overrideAttrs (oldAttrs: {
                  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                });

                # fix mattermost in wayland mode
                mattermost-desktop = prev.mattermost-desktop.overrideAttrs (oldAttrs: {
                  runtimeDependencies = (oldAttrs.runtimeDependencies or []) ++ [ prev.wayland ];
                });
              })
            ] ++ nixpkgsOverlays;

            # Source: https://github.com/NixOS/nix/issues/3803#issuecomment-1181667475
            # Hack to support legacy worklows that use `<nixpkgs>` etc.
            nix.nixPath = [
              "nixpkgs=${inputs.nixpkgs}"
            ];
          }

          (import ./nixos/configuration.nix forceNoSecrets deviceName userName)

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup"; # Avoid activation failures due to .htoprc changes
            home-manager.users."${userName}" = import ./home-manager/home.nix;

            home-manager.extraSpecialArgs = {
              inherit deviceName;
              inherit userName;
            };
          }
        ] ++ customModules;
      };

      mkSystems = sysDescs: builtins.listToAttrs (map (desc: { name = "nixos-" + desc.deviceName + (desc.confNameSuffix or ""); value = (mkSys desc); }) sysDescs);
    in mkSystems [
      # Define systems
      { deviceName = "lenovo-laptop"; customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga ]; }
      { deviceName = "lenovo-laptop"; confNameSuffix = "no-sec"; customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga ]; forceNoSecrets = true; }
      { deviceName = "work-laptop"; customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen ]; }

      { deviceName = "desktop"; }
      { deviceName = "desktop"; confNameSuffix = "no-sec"; forceNoSecrets = true; }

      { deviceName = "rpi4"; system = "aarch64-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ]; }
      { deviceName = "tmserver"; system = "aarch64-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ]; }
      { deviceName = "octoprint"; system = "aarch64-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
        nixpkgsOverlays = [
          # https://discourse.nixos.org/t/nixos-and-raspberry-pi-zero-2w-pi-camera-module-v3/46319
          (self: super: {
            # https://patchwork.libcamera.org/patch/19420
            libcamera = super.libcamera.overrideAttrs ({ patches ? [ ], ... }: {
              patches = patches ++ [
                (self.fetchpatch {
                  url = "https://patchwork.libcamera.org/patch/19420/raw";
                  hash = "sha256-xJ8478CAKvyo2k1zrfIytDxFQ1Qdd8ilMdABQoNcdPU=";
                })
              ];
            });
          })
        ];
      }

      { deviceName = "virtualbox"; forceNoSecrets = true; }

      { deviceName = "iso-image"; forceNoSecrets = true; customModules = [
        ({ pkgs, modulesPath, ... }: {
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
        })
      ]; }
    ];
  };
}
