''
    export _JAVA_AWT_WM_NONREPARENTING="1"
    export SDL_VIDEODRIVER="wayland"
    export XDG_SESSION_TYPE="wayland"
    # QT needs qt5.qtwayland in systemPackages
    export QT_QPA_PLATFORM="wayland-egl"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    # Elementary/EFL
    export ECORE_EVAS_ENGINE="wayland_egl"
    export ELM_ENGINE="wayland_egl"
    # Fix message: [wlr] [libseat] [libseat/backend/seatd.c:70] Could not connect to socket /run/seatd.sock: no such file or directory
    export LIBSEAT_BACKEND="logind"
    export MOZ_DBUS_REMOTE="1"
    # enable wayland for OZONE applications
    export NIXOS_OZONE_WL="1"
''
