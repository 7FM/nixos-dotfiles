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

    nix-matlab = {
      url = "gitlab:doronbehar/nix-matlab";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { self, nixos-hardware, nixpkgs, home-manager, nur, nix-matlab, drynomore, tmdbot, ...}@inputs: {
    nixosConfigurations = let
      mkSys = {deviceName, system ? "x86_64-linux", userName ? "tm", customModules ? [], forceNoSecrets ? false}: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          {
            nixpkgs.overlays = [
              # Matlab overlay
              nix-matlab.overlay
              # NUR overlay
              nur.overlay
              # my custom tools
              (final: prev: {
                myTools = import ./common/lib deviceName;

                drynomore = drynomore.packages."${system}".default;
                tmdbot = tmdbot.packages."${system}".default;

                astroid = prev.astroid.overrideAttrs (oldAttrs: {
                  patches = oldAttrs.patches ++ [
                    (prev.fetchpatch {
                      name = "fix-message-view.patch";
                      url = "https://github.com/ibuclaw/astroid/commit/6b7e302ae2d183cc6a9ffbfdf8e5a2f9477e8b89.patch";
                      hash = "sha256-YPXIwle/mNymLm4Wuzq77Z3+/rKlw8B6Txe4NtWGq0c=";
                    })
                    (prev.fetchpatch {
                      name = "fix-attachments.patch";
                      url = "https://github.com/astroidmail/astroid/commit/7fd64c41435a2b99fb9e0a5770a83ba30cd11450.patch";
                      hash = "sha256-JW5WdSlagHmtjmX9HxLPzubR5HpenjkVjQxOJx5mgx0=";
                    })
                  ];
                });

                # waybar: enable experimental features
                waybar = prev.waybar.overrideAttrs (oldAttrs: {
                  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                });

                # fix mattermost in wayland mode
                mattermost-desktop = prev.mattermost-desktop.overrideAttrs (oldAttrs: {
                  runtimeDependencies = (oldAttrs.runtimeDependencies or []) ++ [ prev.wayland ];
                });
              })
            ];

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
      { deviceName = "octoprint-rpi2"; system = "armv7-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-2 ]; }

      { deviceName = "virtualbox"; forceNoSecrets = true; }

      { deviceName = "iso-image"; forceNoSecrets = true; customModules = [
        ({ pkgs, modulesPath, ... }: {
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
        })
      ]; }
    ];
  };
}
