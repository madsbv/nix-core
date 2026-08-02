# Register the flake a system was built with in `nix.registry.self`, so the
# running machine can introspect its own configuration. From srvos.
{
  config,
  lib,
  ...
}:
let
  cfg = config.srvos;
in
{
  options.srvos = {
    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      default = null;
      description = "Flake that contains the nixos configuration (leaf-provided).";
    };

    registerSelf = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add the flake the system was built with to `nix.registry` as `self`.";
    };
  };

  config = lib.mkIf (cfg.flake != null) {
    nix.registry = lib.optionalAttrs cfg.registerSelf {
      self.to = lib.mkDefault {
        type = "path";
        path = cfg.flake;
      };
    };
  };
}
