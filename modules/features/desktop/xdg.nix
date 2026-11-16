_: {
  flake.modules.nixos.xdg-desktop =
    { pkgs, ... }:
    {
      services = {
        gnome.gnome-keyring.enable = true;
        tumbler.enable = true;
        gvfs.enable = true;
      };

      xdg.portal = {
        enable = true;
        config.common.default = [ "gtk" ];
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      xdg.mime.defaultApplications = {
        "inode/directory" = "thunar.desktop";
      };

      programs = {
        i3lock.enable = true;
        nm-applet.enable = true;
        thunar = {
          enable = true;
          plugins = with pkgs; [
            thunar-volman
            thunar-dropbox-plugin
            thunar-archive-plugin
            thunar-media-tags-plugin
          ];
        };
        xfconf.enable = true;
        dconf.enable = true;
      };
    };
}
