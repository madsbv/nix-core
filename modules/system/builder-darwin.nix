# Darwin-specific builder properties: the linux-builder VM user gets a fixed
# uid/gid/home and is visible in the login window. This module complements
# `builder.nix` (shared across both platforms) and is only imported by
# `modules/base.nix` in the darwin base composite.
{
  config,
  lib,
  ...
}:
let
  cfg = config.mine.remoteBuilder;
in
{
  config = lib.mkIf cfg.enableLocalBuilder {
    users.users.builder = {
      isHidden = false;
      uid = 42;
      gid = 42;
      home = "/var/nix-builder";
    };
  };
}
