{
  description = "System config flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs.url = "nixpkgs/nixpkgs-unstable";
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

  outputs = { self, nixos-hardware, nixpkgs, home-manager, nur, ...}: {
    nixosConfigurations = let
      mkSys = {deviceName, system ? "x86_64-linux", userName ? "tm", customModules ? [], forceNoSecrets ? false}: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          {
            nixpkgs.overlays = [
              # NUR overlay
              nur.overlay
              # my custom tools
              (final: prev: {
                myTools = import ./common/lib deviceName;

                # patch astroid to fix: https://github.com/NixOS/nixpkgs/issues/168381 via https://github.com/astroidmail/astroid/pull/716
                astroid = prev.astroid.overrideAttrs (old: {
                  patches = (old.patches or []) ++ [
                    (prev.fetchpatch {
                      url = "https://patch-diff.githubusercontent.com/raw/astroidmail/astroid/pull/716.patch";
                      sha256 = "sha256-hZHOg1wUR8Kpd6017fWzhMmG+/WQxSOCnsiyIvUcpbU=";
                    })
                  ];
                  preFixup = (old.preFixup or "") + ''
                    # On some systems (at least, Intel TGL iGPU), the email composer is
                    # broken since Webkit enables accelerated rending by default in
                    # 2.36. See #168645.
                    gappsWrapperArgs+=(--set WEBKIT_DISABLE_COMPOSITING_MODE 1)
                  '';
                });
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

      { deviceName = "desktop"; }
      { deviceName = "desktop"; confNameSuffix = "no-sec"; forceNoSecrets = true; }

      { deviceName = "virtualbox"; forceNoSecrets = true; }
    ];
  };
}
