{
  description = "System config flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs_prepatch.url = "nixpkgs/nixos-unstable";
    #nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs_prepatch";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs_prepatch";
    };
    drynomore = {
      url = "github:7FM/DryNoMore";
      inputs.nixpkgs.follows = "nixpkgs_prepatch";
    };

    tmdbot = {
      url = "github:7FM/TMDBot";
      inputs.nixpkgs.follows = "nixpkgs_prepatch";
      inputs.flake-utils.follows = "drynomore/flake-utils";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs_prepatch";
    };
  };

  outputs =
    {
      self,
      nixos-hardware,
      nixpkgs_prepatch,
      home-manager,
      nur,
      drynomore,
      tmdbot,
      nix-index-database,
      ...
    }@inputs:
    {
      nixosConfigurations =
        let
          mkSys =
            {
              deviceName,
              system ? "x86_64-linux",
              userName ? "tm",
              customModules ? [ ],
              nixpkgsOverlays ? [ ],
              nixpkgsPatches ? [ ],
              forceNoSecrets ? false,
            }:
            let
              patches = [
              ]
              ++ nixpkgsPatches;
              # Patching requires building the patched tree (import from derivation)
              # and re-evaluating nixpkgs' flake.nix, which is expensive. Skip all of
              # that and use the input as-is when there is nothing to patch.
              nixpkgs-src =
                if patches == [ ] then
                  inputs.nixpkgs_prepatch
                else
                  (import nixpkgs_prepatch {
                    inherit system;
                  }).applyPatches
                    {
                      name = "nixpkgs-patched";
                      src = inputs.nixpkgs_prepatch;
                      inherit patches;
                    };
              nixpkgs =
                if patches == [ ] then
                  nixpkgs_prepatch
                else
                  (import "${nixpkgs-src}/flake.nix").outputs { self = inputs.self; };
            in
            nixpkgs.lib.nixosSystem {
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

                      # waybar: enable experimental features + pulseaudio slider source target support
                      waybar = prev.waybar.overrideAttrs (oldAttrs: {
                        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
                        patches = (oldAttrs.patches or [ ]) ++ [
                          (prev.fetchpatch {
                            url = "https://github.com/Alexays/Waybar/pull/4908.patch";
                            hash = "sha256-bGweDV7E1f1ht7+tB3Z2R77KF0z8SRWm8A7JVuCJI1c=";
                          })
                        ];
                      });

                      # fix mattermost in wayland mode
                      mattermost-desktop = prev.mattermost-desktop.overrideAttrs (oldAttrs: {
                        runtimeDependencies = (oldAttrs.runtimeDependencies or [ ]) ++ [ prev.wayland ];
                      });
                    })
                  ]
                  ++ nixpkgsOverlays;

                  # Source: https://github.com/NixOS/nix/issues/3803#issuecomment-1181667475
                  # Hack to support legacy worklows that use `<nixpkgs>` etc.
                  nix.nixPath = [
                    "nixpkgs=${nixpkgs-src}"
                  ];
                }

                (import ./nixos/configuration.nix forceNoSecrets deviceName userName)

                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "backup"; # Avoid activation failures due to .htoprc changes
                  home-manager.users."${userName}" = import ./home-manager/home.nix;

                  home-manager.extraSpecialArgs = {
                    inherit deviceName;
                    inherit userName;
                    inherit nix-index-database;
                  };
                }
              ]
              ++ customModules;
            };

          mkSystems =
            sysDescs:
            builtins.listToAttrs (
              map (desc: {
                name = "nixos-" + desc.deviceName + (desc.confNameSuffix or "");
                value = (mkSys desc);
              }) sysDescs
            );
        in
        mkSystems [
          # Define systems
          {
            deviceName = "lenovo-laptop";
            customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga ];
          }
          {
            deviceName = "lenovo-laptop";
            confNameSuffix = "no-sec";
            customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga ];
            forceNoSecrets = true;
          }
          {
            deviceName = "work-laptop";
            customModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen ];
          }

          { deviceName = "desktop"; }
          {
            deviceName = "desktop";
            confNameSuffix = "no-sec";
            forceNoSecrets = true;
          }

          {
            deviceName = "rpi4";
            system = "aarch64-linux";
            customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
          }
          {
            deviceName = "tmserver-x86";
            nixpkgsOverlays = [
              # Option-A experiment: build OpenVINO's Intel-GPU plugin WITH
              # oneDNN-for-GPU. nixpkgs sets ENABLE_ONEDNN_FOR_GPU=OFF; Intel's
              # prebuilt OpenVINO (the working immich ML container) builds it ON.
              # onnxruntime's OpenVINO EP + immich-machine-learning rebuild against
              # this, so the native iGPU ML path exercises the oneDNN GPU kernels.
              (final: prev: {
                openvino = prev.openvino.overrideAttrs (old: {
                  cmakeFlags =
                    (builtins.filter (f: !(prev.lib.hasInfix "ENABLE_ONEDNN_FOR_GPU" f)) old.cmakeFlags)
                    ++ [ (prev.lib.cmakeBool "ENABLE_ONEDNN_FOR_GPU" true) ];
                });
              })
            ];
          }
          {
            deviceName = "octoprint";
            system = "aarch64-linux";
            customModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
            nixpkgsOverlays = [
              (self: super: {
                # Add not yet packaged octoprint plugins
                octoprint = super.octoprint.override (prevArgs: {
                  packageOverrides = super.callPackage ./custom_pkgs/octoprint_plugins.nix { };
                });
              })
            ];
          }

          {
            deviceName = "virtualbox";
            forceNoSecrets = true;
          }

          {
            deviceName = "iso-image";
            forceNoSecrets = true;
            customModules = [
              (
                { pkgs, modulesPath, ... }:
                {
                  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
                }
              )
            ];
          }
        ];

      # `nix fmt`. The tree is formatted with nixfmt (RFC style); declaring it
      # here makes that explicit instead of something you have to infer from the
      # existing files. Covers both architectures used by the systems above.
      #
      # Wrapped rather than using pkgs.nixfmt directly because nixfmt aborts on
      # git-crypt blobs ("hGetContents: invalid argument (cannot decode byte
      # sequence)") — and since no single machine holds every device key, some
      # secret is always still encrypted. Those are skipped by magic header.
      formatter =
        nixpkgs_prepatch.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            let
              pkgs = nixpkgs_prepatch.legacyPackages.${system};
            in
            pkgs.writeShellApplication {
              name = "nixfmt-skip-encrypted";
              runtimeInputs = with pkgs; [
                nixfmt
                findutils
                coreutils
              ];
              text = ''
                flags=()
                paths=()
                for arg in "$@"; do
                  case "$arg" in
                    -*) flags+=("$arg") ;;
                    *) paths+=("$arg") ;;
                  esac
                done
                [ ''${#paths[@]} -gt 0 ] || paths=(.)

                files=()
                while IFS= read -r f; do
                  # git-crypt blobs start with a NUL byte then "GITCRYPT"
                  [ "$(head -c 9 "$f" | tr -d '\0')" = "GITCRYPT" ] && continue
                  files+=("$f")
                done < <(find "''${paths[@]}" -type f -name '*.nix' -not -path '*/.git/*' | sort)

                [ ''${#files[@]} -gt 0 ] || exit 0
                exec nixfmt ''${flags[@]+"''${flags[@]}"} "''${files[@]}"
              '';
            }
          );
    };
}
