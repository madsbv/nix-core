_:
let
  # Compile fix for `xdg-user-dirs` on Darwin (pulled in by xdg-utils and
  # transitively by alacritty). Ported from the old `overlays/xdg-user-dirs-darwin.nix`.
  # Per the "selective overlays" rule it is defined and applied here, in the
  # feature that needs it, rather than a global overlays dir.
  xdgUserDirsDarwin = _final: prev: {
    xdg-user-dirs = prev.xdg-user-dirs.overrideAttrs (attrs: {
      meta = attrs.meta // {
        platforms = prev.lib.platforms.unix;
      };
      nativeBuildInputs =
        attrs.nativeBuildInputs ++ prev.lib.optionals prev.stdenv.isDarwin [ prev.gettext ];
      buildInputs = attrs.buildInputs ++ prev.lib.optionals prev.stdenv.isDarwin [ prev.libiconv ];
    });
  };
in
{
  flake.modules.darwin.terminal = {
    # alacritty is installed through Home Manager, which uses the system nixpkgs
    # on Darwin (useGlobalPkgs), so the overlay must live on the system nixpkgs,
    # not in the HM evaluation.
    nixpkgs.overlays = [ xdgUserDirsDarwin ];
  };

  flake.modules.homeManager.terminal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.alacritty = {
        enable = true;
        settings = {
          cursor.style = "Block";
          window = {
            opacity = 1.0;
            padding = {
              x = 24;
              y = 24;
            };
          };
          font = {
            normal = {
              family = "MesloLGS NF";
              style = "Regular";
            };
            size = lib.mkMerge [
              (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
              (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
            ];
          };
          colors =
            with config.scheme.withHashtag;
            let
              default = {
                black = base00;
                white = base07;
                inherit
                  red
                  green
                  yellow
                  blue
                  cyan
                  magenta
                  ;
              };
            in
            {
              primary = {
                background = base00;
                foreground = base07;
              };
              cursor = {
                text = base02;
                cursor = base07;
              };
              normal = default;
              bright = default;
              dim = default;
            };
        };
      };
      home.sessionVariables.TERMINAL = "alacritty";
    };
}
