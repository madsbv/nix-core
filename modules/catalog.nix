# Discovery output: every registered module per class, and each profile's
# members. Read by `just modules`; snapshotted by core's namaka tests.
{ config, lib, ... }:
let
  classes = [
    "nixos"
    "homeManager"
    "darwin"
  ];
in
{
  flake.catalog = {
    modules = lib.genAttrs classes (class: lib.attrNames config.flake.modules.${class});
    profiles = lib.mapAttrs (_: p: { inherit (p) nixos homeManager darwin; }) config.flake.profiles;
  };
}
