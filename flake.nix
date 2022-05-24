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

                # Fix SANE udev rules: https://github.com/NixOS/nixpkgs/issues/147217, more specifically: https://github.com/NixOS/nixpkgs/issues/147217#issuecomment-1063139365
                sane-backends = prev.sane-backends.overrideAttrs (oldAttrs: rec {
                  postInstall = builtins.replaceStrings
                    ["./tools/sane-desc -m udev"]
                    ["./tools/sane-desc -m udev+hwdb -s doc/descriptions:doc/descriptions-external"]
                    oldAttrs.postInstall;
                });

                # patch zoom based on https://github.com/NixOS/nixpkgs/compare/master...tomjnixon:zoom_rebase and https://github.com/NixOS/nixpkgs/pull/166085
                zoom-us = let 
                  libs = prev.lib.makeLibraryPath (with prev; [
                    # $ LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH:$PWD ldd zoom | grep 'not found'
                    alsa-lib
                    atk
                    at-spi2-atk
                    at-spi2-core
                    cairo
                    cups
                    dbus
                    expat
                    libdrm
                    libGL
                    fontconfig
                    freetype
                    gtk3
                    gdk-pixbuf
                    glib
                    mesa
                    nspr
                    nss
                    pango
                    stdenv.cc.cc
                    wayland
                    xorg.libX11
                    xorg.libxcb
                    xorg.libXcomposite
                    xorg.libXdamage
                    xorg.libXext
                    libxkbcommon
                    xorg.libXrandr
                    xorg.libXrender
                    zlib
                    xorg.libxshmfence
                    xorg.xcbutilimage
                    xorg.xcbutilkeysyms
                    xorg.libXfixes
                    xorg.libXtst
                    udev
                    zlib
                    libpulseaudio
                  ]);
                in prev.zoom-us.overrideAttrs (old: rec {
                  version = "5.10.4.2845";
                  src = prev.fetchurl {
                      url = "https://zoom.us/client/${version}/zoom_x86_64.pkg.tar.xz";
                      sha256 = "9gspydrGaEjzAM0nK1u0XNm07HTupJ2wnPxCFWy+Nts=";
                  };

                  postFixup = prev.lib.optionalString prev.stdenv.isLinux ''
                    # Desktop File
                    substituteInPlace $out/share/applications/Zoom.desktop \
                        --replace "Exec=/usr/bin/zoom" "Exec=$out/bin/zoom"
                    for i in zopen zoom ZoomLauncher; do
                      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/zoom/$i
                    done
                    # ZoomLauncher sets LD_LIBRARY_PATH before execing zoom
                    # IPC breaks if the executable name does not end in 'zoom'
                    mv $out/opt/zoom/zoom $out/opt/zoom/.zoom
                    makeWrapper $out/opt/zoom/.zoom $out/opt/zoom/zoom \
                      --prefix LD_LIBRARY_PATH ":" ${libs}
                    rm $out/bin/zoom
                    # Zoom expects "zopen" executable (needed for web login) to be present in CWD. Or does it expect
                    # everybody runs Zoom only after cd to Zoom package directory? Anyway, :facepalm:
                    # Clear Qt paths to prevent tripping over "foreign" Qt resources.
                    # Clear Qt screen scaling settings to prevent over-scaling.
                    makeWrapper $out/opt/zoom/ZoomLauncher $out/bin/zoom \
                      --chdir "$out/opt/zoom" \
                      --unset QML2_IMPORT_PATH \
                      --unset QT_PLUGIN_PATH \
                      --unset QT_SCREEN_SCALE_FACTORS \
                      --prefix PATH : ${prev.lib.makeBinPath (with prev; [ coreutils glib.dev pciutils procps util-linux ])} \
                      --prefix LD_LIBRARY_PATH ":" ${libs}
                    # Backwards compatiblity: we used to call it zoom-us
                    ln -s $out/bin/{zoom,zoom-us}
                  '';
                });

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

                modem-manager-gui = prev.modem-manager-gui.overrideAttrs (old: {
                  patches = (old.patches or []) ++ [
                    (prev.fetchpatch {
                      url = "https://salsa.debian.org/debian/modem-manager-gui/-/commit/8ccffd6dd6b42625d09d5408f37f155d91411116.patch";
                      sha256 = "sha256-q+B+Bcm3uitJ2IfkCiMo3reFV1C06ekmy1vXWC0oHnw=";
                    })
                  ];
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

            # Workaround for https://github.com/NixOS/nixpkgs/issues/169193
            home-manager.users.root.programs.git = {
              enable = true;
              extraConfig.safe.directory = "/home/${userName}/nixos-dotfiles";
            };

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
