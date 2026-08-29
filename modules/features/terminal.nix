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
      lib,
      ...
    }:
    {
      programs.alacritty = {
        enable = true;
        settings = {
          window.padding = {
            x = 4;
            y = 4;
          };
          font = {
            size = lib.mkDefault 12;
            normal.family = lib.mkDefault "JetBrains Mono";
          };
        };
      };
      home.sessionVariables.TERMINAL = "alacritty";
    };
}
