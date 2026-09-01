# `nox` (nix-options-search) — CLI for searching Nix options. Curried over
# core's pinned `inputs` so the package resolves to core's `nox` input even when
# this flake module is consumed by a leaf. Installed for the primary user on
# every host via the Home Manager base composite (import-gated: importing this
# module installs it).
{ inputs }:
{
  flake.modules.homeManager.nox =
    { pkgs, ... }:
    {
      home.packages = [ inputs.nox.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
