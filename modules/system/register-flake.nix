# Register the flake a system was built with in `nix.registry.self`, so the
# running machine can introspect its own configuration. From srvos.
#
# Option declarations live in `modules/options.nix` (see `mine.system.registerFlake`);
# this module only wires the behavior.
{
  config,
  lib,
  ...
}:
let
  cfg = config.mine.system.registerFlake;
in
{
  config = lib.mkIf (cfg.flake != null) {
    nix.registry = lib.optionalAttrs cfg.registerSelf {
      self.to = lib.mkDefault {
        type = "path";
        path = cfg.flake;
      };
    };
  };
}
