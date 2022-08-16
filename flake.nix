{
  description = "System config flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    #nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
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

                # Update to waybar master # TODO remove this after the next release!
                waybar = prev.waybar.overrideAttrs (oldAttrs: {
                  src = prev.fetchFromGitHub {
                    owner = "Alexays";
                    repo = "Waybar";
                    rev = "fb2ac8a7651a8a4222b063557e37bdf088506028";
                    sha256 = "sha256-BD89Gzr8oXkTs0eNsqzEdFnzAR2YzPu1TOFuCFQyurA=";
                  };
                  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                });

                klipper = prev.stdenv.mkDerivation rec {
                  pname = "klipper";
                  version = "unstable-2022-03-14";

                  src = prev.fetchFromGitHub {
                    owner = "KevinOConnor";
                    repo = "klipper";
                    rev = "30098db22a43274ceb87e078e603889f403a35c4";
                    sha256 = "sha256-ORpXBFGPY6A/HEYX9Hhwb3wP2KcAE+z3pTxf6j7CwGg=";
                  };

                  sourceRoot = "source/klippy";

                  # there is currently an attempt at moving it to Python 3, but it will remain
                  # Python 2 for the foreseeable future.
                  # c.f. https://github.com/KevinOConnor/klipper/pull/3278
                  # NB: This is needed for the postBuild step
                  nativeBuildInputs = [ (prev.python3.withPackages ( p: with p; [ cffi ] )) ];

                  buildInputs = [ (prev.python3.withPackages (p: with p; [ cffi pyserial greenlet jinja2 numpy ])) ];

                  # we need to run this to prebuild the chelper.
                  postBuild = "python3 ./chelper/__init__.py";

                  # NB: We don't move the main entry point into `/bin`, or even symlink it,
                  # because it uses relative paths to find necessary modules. We could wrap but
                  # this is used 99% of the time as a service, so it's not worth the effort.
                  installPhase = let
                    patchPythonInterpreter = f: "substituteInPlace ${f} --replace '#!/usr/bin/env python2' '#!/usr/bin/env python3'";
                  in ''
                    runHook preInstall

                    ${patchPythonInterpreter "./klippy.py"}
                    ${patchPythonInterpreter "./console.py"}
                    ${patchPythonInterpreter "./parsedump.py"}

                    mkdir -p $out/lib/klipper
                    cp -r ./* $out/lib/klipper

                    # Moonraker expects `config_examples` and `docs` to be available
                    # under `klipper_path`
                    cp -r $src/docs $out/lib/docs
                    cp -r $src/config $out/lib/config

                    chmod 755 $out/lib/klipper/klippy.py
                    runHook postInstall
                  '';
                };
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

      { deviceName = "rpi4"; system = "aarch64-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ]; }

      { deviceName = "virtualbox"; forceNoSecrets = true; }
    ];
  };
}
