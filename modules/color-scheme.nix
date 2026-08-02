# Color scheme: base16 wiring for NixOS, Home Manager and nix-darwin, with the
# `molokai` scheme (ported from the old repo's flake.nix) as the default. The
# base16 modules expose `config.scheme`, which feature modules (terminal, etc.)
# read for app theming.
{ inputs }:
_:
let
  molokai = {
    slug = "molokai";
    scheme = "Port of the Doomemacs port of Tomas Restrepo's Molokai";
    author = "madsbv";
    base00 = "#1c1e1f";
    base01 = "#222323";
    base02 = "#4e4e4e";
    base03 = "#555556";
    base04 = "#767679";
    base05 = "#d6d6d4";
    base06 = "#f5f4f1";
    base07 = "#ffffff";
    base08 = "#fb2874";
    base09 = "#fd971f";
    base0A = "#e2c770";
    base0B = "#b6e63e";
    base0C = "#66d9ef";
    base0D = "#268bd2";
    base0E = "#9c91e4";
    base0F = "#cc6633";
  };
in
{
  flake.modules = {
    nixos.base.imports = [
      inputs.base16.nixosModule
      {
        scheme = molokai;
      }
    ];

    homeManager.base.imports = [
      inputs.base16.homeManagerModule
      {
        scheme = molokai;
      }
    ];

    # base16 ships a single nixosModule that nix-darwin can also consume.
    darwin.base.imports = [
      inputs.base16.nixosModule
      {
        scheme = molokai;
      }
    ];
  };
}
