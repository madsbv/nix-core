# Darwin-specific builder properties: the linux-builder VM user gets a fixed
# uid/gid/home and is visible in the login window. This module complements
# `builder.nix` (shared across both platforms) and is only imported by
# `modules/base.nix` in the darwin base composite.
_: {
  users.users.builder = {
    isHidden = false;
    uid = 42;
    gid = 42;
    home = "/var/nix-builder";
  };
}
