{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.media.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # media playback tools
      vlc
      spotify
      playerctl # playback control
    ];

    # use vlc by default for the following mime types
    xdg.mimeApps.defaultApplications = {
      "application/ogg" = [ "vlc.desktop" ];
      "application/x-ogg" = [ "vlc.desktop" ];
      "audio/ogg" = [ "vlc.desktop" ];
      "audio/vorbis" = [ "vlc.desktop" ];
      "audio/x-vorbis" = [ "vlc.desktop" ];
      "audio/x-vorbis+ogg" = [ "vlc.desktop" ];
      "video/ogg" = [ "vlc.desktop" ];
      "video/x-ogm" = [ "vlc.desktop" ];
      "video/x-ogm+ogg" = [ "vlc.desktop" ];
      "video/x-theora+ogg" = [ "vlc.desktop" ];
      "video/x-theora" = [ "vlc.desktop" ];
      "audio/x-speex" = [ "vlc.desktop" ];
      "audio/opus" = [ "vlc.desktop" ];
      "application/x-flac" = [ "vlc.desktop" ];
      "audio/flac" = [ "vlc.desktop" ];
      "audio/x-flac" = [ "vlc.desktop" ];
      "audio/x-ms-asf" = [ "vlc.desktop" ];
      "audio/x-ms-asx" = [ "vlc.desktop" ];
      "audio/x-ms-wax" = [ "vlc.desktop" ];
      "audio/x-ms-wma" = [ "vlc.desktop" ];
      "video/x-ms-asf" = [ "vlc.desktop" ];
      "video/x-ms-asf-plugin" = [ "vlc.desktop" ];
      "video/x-ms-asx" = [ "vlc.desktop" ];
      "video/x-ms-wm" = [ "vlc.desktop" ];
      "video/x-ms-wmv" = [ "vlc.desktop" ];
      "video/x-ms-wmx" = [ "vlc.desktop" ];
      "video/x-ms-wvx" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ];
      "audio/x-pn-windows-acm" = [ "vlc.desktop" ];
      "video/divx" = [ "vlc.desktop" ];
      "video/msvideo" = [ "vlc.desktop" ];
      "video/vnd.divx" = [ "vlc.desktop" ];
      "video/avi" = [ "vlc.desktop" ];
      "video/x-avi" = [ "vlc.desktop" ];
      "application/vnd.rn-realmedia" = [ "vlc.desktop" ];
      "application/vnd.rn-realmedia-vbr" = [ "vlc.desktop" ];
      "audio/vnd.rn-realaudio" = [ "vlc.desktop" ];
      "audio/x-pn-realaudio" = [ "vlc.desktop" ];
      "audio/x-pn-realaudio-plugin" = [ "vlc.desktop" ];
      "audio/x-real-audio" = [ "vlc.desktop" ];
      "audio/x-realaudio" = [ "vlc.desktop" ];
      "video/vnd.rn-realvideo" = [ "vlc.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" ];
      "audio/mpg" = [ "vlc.desktop" ];
      "audio/mp1" = [ "vlc.desktop" ];
      "audio/mp2" = [ "vlc.desktop" ];
      "audio/mp3" = [ "vlc.desktop" ];
      "audio/x-mp1" = [ "vlc.desktop" ];
      "audio/x-mp2" = [ "vlc.desktop" ];
      "audio/x-mp3" = [ "vlc.desktop" ];
      "audio/x-mpeg" = [ "vlc.desktop" ];
      "audio/x-mpg" = [ "vlc.desktop" ];
      "video/mp2t" = [ "vlc.desktop" ];
      "video/mpeg" = [ "vlc.desktop" ];
      "video/mpeg-system" = [ "vlc.desktop" ];
      "video/x-mpeg" = [ "vlc.desktop" ];
      "video/x-mpeg2" = [ "vlc.desktop" ];
      "video/x-mpeg-system" = [ "vlc.desktop" ];
      "application/mpeg4-iod" = [ "vlc.desktop" ];
      "application/mpeg4-muxcodetable" = [ "vlc.desktop" ];
      "application/x-extension-m4a" = [ "vlc.desktop" ];
      "application/x-extension-mp4" = [ "vlc.desktop" ];
      "audio/aac" = [ "vlc.desktop" ];
      "audio/m4a" = [ "vlc.desktop" ];
      "audio/mp4" = [ "vlc.desktop" ];
      "audio/x-m4a" = [ "vlc.desktop" ];
      "audio/x-aac" = [ "vlc.desktop" ];
      "video/mp4" = [ "vlc.desktop" ];
      "video/mp4v-es" = [ "vlc.desktop" ];
      "video/x-m4v" = [ "vlc.desktop" ];
      "application/x-quicktime-media-link" = [ "vlc.desktop" ];
      "application/x-quicktimeplayer" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "application/x-matroska" = [ "vlc.desktop" ];
      "audio/x-matroska" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "audio/webm" = [ "vlc.desktop" ];
      "audio/3gpp" = [ "vlc.desktop" ];
      "audio/3gpp2" = [ "vlc.desktop" ];
      "audio/AMR" = [ "vlc.desktop" ];
      "audio/AMR-WB" = [ "vlc.desktop" ];
      "video/3gp" = [ "vlc.desktop" ];
      "video/3gpp" = [ "vlc.desktop" ];
      "video/3gpp2" = [ "vlc.desktop" ];
      "x-scheme-handler/mms" = [ "vlc.desktop" ];
      "x-scheme-handler/mmsh" = [ "vlc.desktop" ];
      "x-scheme-handler/rtsp" = [ "vlc.desktop" ];
      "x-scheme-handler/rtp" = [ "vlc.desktop" ];
      "x-scheme-handler/rtmp" = [ "vlc.desktop" ];
      "x-scheme-handler/icy" = [ "vlc.desktop" ];
      "x-scheme-handler/icyx" = [ "vlc.desktop" ];
      "application/x-cd-image" = [ "vlc.desktop" ];
      "x-content/video-vcd" = [ "vlc.desktop" ];
      "x-content/video-svcd" = [ "vlc.desktop" ];
      "x-content/video-dvd" = [ "vlc.desktop" ];
      "x-content/audio-cdda" = [ "vlc.desktop" ];
      "x-content/audio-player" = [ "vlc.desktop" ];
      "application/ram" = [ "vlc.desktop" ];
      "application/xspf+xml" = [ "vlc.desktop" ];
      "audio/mpegurl" = [ "vlc.desktop" ];
      "audio/x-mpegurl" = [ "vlc.desktop" ];
      "audio/scpls" = [ "vlc.desktop" ];
      "audio/x-scpls" = [ "vlc.desktop" ];
      "text/google-video-pointer" = [ "vlc.desktop" ];
      "text/x-google-video-pointer" = [ "vlc.desktop" ];
      "video/vnd.mpegurl" = [ "vlc.desktop" ];
      "application/vnd.apple.mpegurl" = [ "vlc.desktop" ];
      "application/vnd.ms-asf" = [ "vlc.desktop" ];
      "application/vnd.ms-wpl" = [ "vlc.desktop" ];
      "application/sdp" = [ "vlc.desktop" ];
      "audio/dv" = [ "vlc.desktop" ];
      "video/dv" = [ "vlc.desktop" ];
      "audio/x-aiff" = [ "vlc.desktop" ];
      "audio/x-pn-aiff" = [ "vlc.desktop" ];
      "video/x-anim" = [ "vlc.desktop" ];
      "video/x-nsv" = [ "vlc.desktop" ];
      "video/fli" = [ "vlc.desktop" ];
      "video/flv" = [ "vlc.desktop" ];
      "video/x-flc" = [ "vlc.desktop" ];
      "video/x-fli" = [ "vlc.desktop" ];
      "video/x-flv" = [ "vlc.desktop" ];
      "audio/wav" = [ "vlc.desktop" ];
      "audio/x-pn-au" = [ "vlc.desktop" ];
      "audio/x-pn-wav" = [ "vlc.desktop" ];
      "audio/x-wav" = [ "vlc.desktop" ];
      "audio/x-adpcm" = [ "vlc.desktop" ];
      "audio/ac3" = [ "vlc.desktop" ];
      "audio/eac3" = [ "vlc.desktop" ];
      "audio/vnd.dts" = [ "vlc.desktop" ];
      "audio/vnd.dts.hd" = [ "vlc.desktop" ];
      "audio/vnd.dolby.heaac.1" = [ "vlc.desktop" ];
      "audio/vnd.dolby.heaac.2" = [ "vlc.desktop" ];
      "audio/vnd.dolby.mlp" = [ "vlc.desktop" ];
      "audio/basic" = [ "vlc.desktop" ];
      "audio/midi" = [ "vlc.desktop" ];
      "audio/x-ape" = [ "vlc.desktop" ];
      "audio/x-gsm" = [ "vlc.desktop" ];
      "audio/x-musepack" = [ "vlc.desktop" ];
      "audio/x-tta" = [ "vlc.desktop" ];
      "audio/x-wavpack" = [ "vlc.desktop" ];
      "audio/x-shorten" = [ "vlc.desktop" ];
      "application/x-shockwave-flash" = [ "vlc.desktop" ];
      "application/x-flash-video" = [ "vlc.desktop" ];
      "misc/ultravox" = [ "vlc.desktop" ];
      "image/vnd.rn-realpix" = [ "vlc.desktop" ];
      "audio/x-it" = [ "vlc.desktop" ];
      "audio/x-mod" = [ "vlc.desktop" ];
      "audio/x-s3m" = [ "vlc.desktop" ];
      "audio/x-xm" = [ "vlc.desktop" ];
      "application/mxf" = [ "vlc.desktop" ];
    };
  };
}
