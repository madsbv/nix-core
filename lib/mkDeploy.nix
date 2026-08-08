# deploy-rs integration builder.
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkDeploy` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
#
# `mkDeploy` returns a module fragment ({ flake.deploy; perSystem; }) that
# the leaf spreads at the module body level (not via `imports` — the Nix
# module system evaluates `imports` before `config` is available):
#
#   { config, ... }:
#   let
#     host = config.flake.lib.mkNixosHost { ... };
#     deploy = config.flake.lib.mkDeploy { system = "x86_64-linux"; nodes = { ... }; };
#   in {
#     flake.nixosConfigurations.foo = host;
#     inherit (deploy) perSystem;
#     flake.deploy = deploy.flake.deploy;
#   }
#
# flake-parts merges the `perSystem` function and `flake.deploy` values from
# all modules, so the spread integrates cleanly.
{ inputs, lib }:
_: {
  flake.lib.mkDeploy =
    {
      system,
      nodes ? { },
    }:
    {
      flake.deploy = nodes;
      perSystem =
        { system', ... }:
        {
          checks = lib.mkIf (system' == system) (
            inputs.deploy-rs.lib.${system}.deployChecks { inherit nodes; }
          );
        };
    };
}
