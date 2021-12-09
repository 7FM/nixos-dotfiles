# Folder structure
TODO TBD

| Folder | Function |
--- | ---
| . | TODO |
| common | TODO |
| common/lib | TODO |
| common/settings | TODO |
| home-manager | TODO |
| home-manager/configs | TODO |
| home-manager/configs/secrets | TODO |
| home-manager/configs/example_secrets | TODO |
| home-manager/devices | TODO |
| home-manager/devices | TODO |
| home-manager/modules | TODO |
| home-manager/modules/collections | TODO |
| home-manager/modules/submodule | TODO |
| nixos | TODO |
| nixos/devices | TODO |
| nixos/modules | TODO |
| nixos/secrets | TODO |
| nixos/example_secrets | TODO |
| misc | TODO |
| misc/envs | TODO |
| misc/scripts | TODO |

# Adding a new device named <new-device>
`<new-device>` will be used in the following as placeholder for your new device's name.
Also ensure that it does not include underscores (`_`) as this seems to produce inconsistent hostnames and won't necessarily detect the correct flake configuration for subsequent `nixos-rebuild switch` executions.
### Modify the following files:
- `flake.nix`:
    * Add below `# Define systems` something like this:
      ```
        nixos-<new-device> = mkSys false "<new-device>" "x86_64-linux";
        nixos-<new-device>-no-sec = mkSys true "<new-device>" "x86_64-linux";
      ```
      The first system will try to use the git-crypt secrets whereas the second system will replace them with dummy secrets, in order to allow a first time installation without decrypting the repository.
### Create the following files:
- `common/settings/<new-device.nix>` aka `nixos/common/settings/<new-device.nix>` aka `home-manager/common/settings/<new-device.nix>` for general device settings:
    * `custom.useDummySecrets`
    * `custom.gui`
    * `custom.cpu`
    * `custom.gpu`
        - **Note**: I haven't tested my setup & modules with an nvidia gpu. Hence, it probably doesn't work.
- `nixos/devices/<new-device>.nix` which contains the hardware specific setup. This is basically the `hardware.nix` generated by `nixos-generate-config`. Additionally, the following settings are available:
    * `custom.enableVirtualization`
    * `custom.useUEFI`
    * `custom.bluetooth`
    * `custom.cpuFreqGovernor`
    * `custom.adb`
    * `custom.internationalization.timeZone`
    * `custom.internationalization.defaultLocale`
    * `custom.internationalization.keyboardLayout`
    * `custom.internationalization.consoleFont`
    * `custom.security.usbguard.enforceRules`
    * `custom.security.usbguard.fixedRules`
    * `custom.sshServer.enable`
    * `custom.sshServer.ports`
    * `custom.swapfile.enable`
    * `custom.swapfile.size`
    * `custom.swapfile.path`
    * `custom.networking.networking`
    * `custom.networking.wifiSupport`
    * `custom.networking.withNetworkManager`
- `home-manager/devices/<new-device>.nix` to enable predefined program sets and adjusting their options:
    * `custom.hm.modules.xdg.enable`
    * `custom.hm.modules.alacritty.enable`
    * `custom.hm.modules.ssh.enable`
    * `custom.hm.modules.git.enable`
    * `custom.hm.modules.zsh.enable`
    * `custom.hm.modules.neovim.enable`
    * `custom.hm.modules.gtk.enable`
    * `custom.hm.modules.qt.enable`
    * `custom.hm.modules.email.enable`
    * `custom.hm.modules.optimize_storage.enable`
    * `custom.hm.modules.sway.laptopDisplay`
    * `custom.hm.modules.sway.disp1`
    * `custom.hm.modules.sway.disp2`
    * `custom.hm.modules.sway.virtualboxWorkaround`
    * `custom.hm.modules.waybar.hwmonPath`
    * `custom.hm.modules.waybar.thermalZone`
    * `custom.hm.collections.utilities.enable`
    * `custom.hm.collections.gui_utilities.enable`
    * `custom.hm.collections.communication.enable`
    * `custom.hm.collections.development.enable`
    * `custom.hm.collections.office.enable`
    * `custom.hm.collections.media.enable`
    * `custom.hm.collections.diyStuff.enable`
    * `custom.hm.collections.gaming.enable`
