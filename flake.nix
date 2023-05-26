{
  description = "System config flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    #nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    nur = {
      url = "github:nix-community/NUR";
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
  };

  outputs = { self, nixos-hardware, nixpkgs, home-manager, nur, nix-matlab, ...}@inputs: {
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

                tor-browser-bundle-bin = prev.tor-browser-bundle-bin.override {
                  useHardenedMalloc = false;
                };

                # waybar: enable experimental features
                waybar = prev.waybar.overrideAttrs (oldAttrs: {
                  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                });

                # fix mattermost in wayland mode
                mattermost-desktop = prev.mattermost-desktop.overrideAttrs (oldAttrs: {
                  runtimeDependencies = oldAttrs.runtimeDependencies ++ [ prev.wayland ];
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

      { deviceName = "desktop"; }
      { deviceName = "desktop"; confNameSuffix = "no-sec"; forceNoSecrets = true; }

      { deviceName = "rpi4"; system = "aarch64-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ]; }
      { deviceName = "octoprint-rpi2"; system = "armv7-linux"; customModules = [ nixos-hardware.nixosModules.raspberry-pi-2 ]; }

      { deviceName = "virtualbox"; forceNoSecrets = true; }
    ];
  };
}
