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
| home-manager/configs/secrets/**/<device-name> | TODO |
| home-manager/configs/example_secrets | TODO |
| home-manager/modules | TODO |
| home-manager/modules/collections | TODO |
| home-manager/modules/submodule | TODO |
| nixos | TODO |
| nixos/modules | TODO |
| nixos/secrets | TODO |
| nixos/secrets/**/<device-name> | TODO |
| nixos/example_secrets | TODO |

# Adding a new device named <new-device>
**`<new-device>`** will be used in the following as placeholder for your new device's name.
Also ensure that it does not include underscores (`_`) as this seems to produce inconsistent hostnames and won't necessarily detect the correct flake configuration for subsequent `nixos-rebuild switch` executions.
### Run the following init commands:
- **`git-crypt init -k <new-device>`** to create the device specific key
- Recommended: export & backup this key via: **`git-crypt export-key -k <new-device> <new-key-path>`** with `<new-key-path>` describing where to export the key to
#### Other useful commands:
- To lock the repo with **all** keys use **`git-crypt lock -a`**
- To lock the repo with a specific device key named i.e. `<my-device>` use **`git-crypt lock -k <my-device>`**
- To unlock (decrypt) the repo simply use `git-crypt unlock <my-key-path>`
    * Note that you might want to unlock the repository with multiple key files to have access to device specific secrets. Simply repeat the command for the all required keys.
### Modify the following files:
- **`flake.nix`**:
    * Add below `# Define systems` something like this:
      ```
        { deviceName = <new-device>; userName = <username>; }
        { deviceName = <new-device>; userName = <username>; confNameSuffix = "no-sec"; forceNoSecrets = true; }
      ```
      The first system will try to use the git-crypt secrets whereas the second system will replace them with dummy secrets, in order to allow a first time installation without decrypting the repository.
- **`.gitattributes`**:
    * To add support for device specific secrets with their own keys append similar to the other devices the following line:
      ```
      **/secrets/**/<new-device>/** filter=git-crypt-<new-device> diff=git-crypt-<new-device>
      ```
### Create the following file:
- **`common/settings/<new-device.nix>`** which contains:
    - general device settings:
        * `custom.useDummySecrets`
        * `custom.gui`
        * `custom.cpu`
        * `custom.gpu`
            - **Note**: I haven't tested my setup & modules with an nvidia gpu. Hence, it probably doesn't work.
        * `custom.bluetooth`
    - all hardware specific setup. This is basically the `hardware.nix` generated by `nixos-generate-config`. 
    - More settings are available:
        * `custom.enableVirtualization`
        * `custom.grub.enable`
        * `custom.grub.useUEFI`
        * `custom.cpuFreqGovernor`
        * `custom.laptopPowerSaving`
        * `custom.adb`
        * `custom.audio.backend`
        * `custom.internationalization.timeZone`
        * `custom.internationalization.defaultLocale`
        * `custom.internationalization.defaultLcTime`
        * `custom.internationalization.defaultLcPaper`
        * `custom.internationalization.defaultLcMeasurement`
        * `custom.internationalization.keyboardLayout`
        * `custom.internationalization.consoleFont`
        * `custom.security.usbguard.enforceRules`
        * `custom.security.usbguard.fixedRules`
        * `custom.smartcards`
        * `custom.sshServer.enable`
        * `custom.sshServer.ports`
        * `custom.sshServer.authorizedKeys`
        * `custom.swapfile.enable`
        * `custom.swapfile.size`
        * `custom.swapfile.path`
        * `custom.nano_conf.enable`
        * `custom.networking.hostname`
        * `custom.networking.nfsSupport`
        * `custom.networking.wifiSupport`
        * `custom.networking.withNetworkManager`
        * `custom.networking.openvpn.client.enable`
        * `custom.networking.openvpn.client.autoConnect`
    - And even more settings to enable predefined program sets and adjusting their options:
        * `custom.hm.modules.alacritty.enable`
        * `custom.hm.modules.alacritty.virtualboxWorkaround`
        * `custom.hm.modules.bash.enable`
        * `custom.hm.modules.calendar.enable`
        * `custom.hm.modules.easyeffects.enable`
        * `custom.hm.modules.email.enable`
        * `custom.hm.modules.git.enable`
        * `custom.hm.modules.git.scripts.enable`
        * `custom.hm.modules.gtk.enable`
        * `custom.hm.modules.neovim.enable`
        * `custom.hm.modules.optimize_storage.enable`
        * `custom.hm.modules.qt.enable`
        * `custom.hm.modules.ssh.enable`
        * `custom.hm.modules.sway.laptopDisplay`
        * `custom.hm.modules.sway.disp1`
        * `custom.hm.modules.sway.disp1_pos`
        * `custom.hm.modules.sway.disp1_res`
        * `custom.hm.modules.sway.disp2`
        * `custom.hm.modules.sway.disp2_pos`
        * `custom.hm.modules.sway.disp2_res`
        * `custom.hm.modules.sway.extraConfig`
        * `custom.hm.modules.waybar.hwmonPath`
        * `custom.hm.modules.waybar.thermalZone`
        * `custom.hm.modules.waybar.gpu.tempCmd`
        * `custom.hm.modules.waybar.gpu.mhzFreqCmd`
        * `custom.hm.modules.waybar.gpu.usageCmd`
        * `custom.hm.modules.xdg.enable`
        * `custom.hm.modules.zsh.enable`
        * `custom.hm.collections.communication.enable`
        * `custom.hm.collections.development.enable`
        * `custom.hm.collections.diyStuff.enable`
        * `custom.hm.collections.gaming.enable`
        * `custom.hm.collections.gui_utilities.enable`
        * `custom.hm.collections.media.enable`
        * `custom.hm.collections.office.enable`
        * `custom.hm.collections.utilities.enable`

# Misc

## Waybar
My config is a mashup of [Pipshag's config](https://github.com/Pipshag/dotfiles_nord) and [genofire's config](https://gist.github.com/genofire/07234e810fcd16f9077710d4303f9a9e) and looks as follows:
![](./doc/waybar.png)

## Building the ISO image

`nix build .#nixosConfigurations.nixos-iso-image.config.system.build.isoImage`
`ls result/iso/`
