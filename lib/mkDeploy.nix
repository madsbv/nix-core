# deploy-rs integration builder.
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkDeploy` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
#
# `mkDeploy` returns `{ flake.deploy = nodes; }` — the deploy node map that
# the leaf exposes as a top-level flake output. Leaves wire it at the module
# body level (not via `imports` — the Nix module system evaluates `imports`
# before `config` is available):
#
#   { config, ... }:
#   let
#     host = config.flake.lib.mkNixosHost { ... };
#     deploy = config.flake.lib.mkDeploy { system = "x86_64-linux"; nodes = { ... }; };
#   in {
#     flake.nixosConfigurations.foo = host;
#     flake.deploy = deploy.flake.deploy;
#   }
#
# deploy-rs activation checks are not wired here — they currently cause
# infinite recursion when evaluated inside a flake-parts `perSystem` block
# (the checks force the NixOS config derivation, which forces `config.flake.*`
# referenced by the profile modules, which triggers re-evaluation of the
# module body that holds `mkDeploy`). Wire checks explicitly in the leaf if
# needed.
_: _: {
  flake.lib.mkDeploy =
    {
      nodes ? { },
    }:
    {
      flake.deploy = nodes;
    };
}
