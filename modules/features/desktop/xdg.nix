_: {
  flake.modules.nixos.xdg-desktop =
    { pkgs, ... }:
    {
      services.gnome.gnome-keyring.enable = true;
      services.tumbler.enable = true;
      services.gvfs.enable = true;

      xdg.portal = {
        enable = true;
        config.common.default = [ "gtk" ];
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      programs.i3lock.enable = true;
      programs.nm-applet.enable = true;
      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-volman
          thunar-dropbox-plugin
          thunar-archive-plugin
          thunar-media-tags-plugin
        ];
      };
      programs.xfconf.enable = true;
      programs.dconf.enable = true;
    };
}
