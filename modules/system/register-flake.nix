# Register the flake a system was built with in `nix.registry.self`, so the
# running machine can introspect its own configuration. From srvos.
#
# Additionally register every flake input and materialise them under
# /etc/nix/path, which `nix.nixPath` points at — that keeps nix3 commands and
# legacy `nix-shell -p '<nixpkgs>'` consistent with the flake. Ported from the
# old `presets/system/common`; nix-darwin manages its own registry, so the
# /etc/nix/path part is Linux-only there too.
#
# Curried over core's pinned `inputs` (see `modules/flake-module.nix`): when a
# leaf consumes this module, the module-system `inputs` argument would be the
# *leaf's* inputs instead.
#
# Option declarations live in `modules/options.nix` (see `mine.system.registerFlake`);
# this module only wires the behavior.
{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mine.system.registerFlake;
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  config = lib.mkMerge [
    {
      nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    }
    (lib.mkIf pkgs.stdenv.isLinux {
      environment.etc = lib.mapAttrs' (
        name: flake: lib.nameValuePair "nix/path/${name}" { source = flake; }
      ) flakeInputs;
      nix.nixPath = [ "/etc/nix/path" ];
    })
    (lib.mkIf (cfg.flake != null) {
      nix.registry = lib.optionalAttrs cfg.registerSelf {
        self.to = lib.mkDefault {
          type = "path";
          path = cfg.flake;
        };
      };
    })
  ];
}
