# deploy-rs integration builder.
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkDeploy` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
#
# Unlike the NixOS/darwin/HM builders, `mkDeploy` does not return a system
# config — it returns a *flake-parts module fragment* that writes the `deploy`
# output and the deploy-rs checks directly. A leaf merges it into its module
# body with `//` (or spreads it), exactly once per flake:
#
#   { config, ... }:
#   (config.flake.lib.mkDeploy { system = "x86_64-linux"; nodes = { ... }; })
#   // { flake.nixosConfigurations.foo = ...; }
#
# This fixes the earlier API where the builder returned a bare merge-set the
# leaf had to split across `config.flake.deploy` and `perSystem.checks` by
# hand, and where the checks transposition couldn't be written at all by a
# plain function.
{ inputs, lib }:
_: {
  flake.lib.mkDeploy =
    {
      system,
      nodes ? { },
    }:
    {
      # deploy-rs `deploy` output: node name → node config (no `nodes` wrapper).
      flake.deploy = nodes;
      # `deployChecks` takes the deploy config (`.nodes`) and returns the
      # per-node activation checks; expose them as flake checks on the deploy
      # system only (no-op on every other declared system).
      perSystem =
        { system', ... }:
        {
          checks = lib.mkIf (system' == system) (
            inputs.deploy-rs.lib.${system}.deployChecks { inherit nodes; }
          );
        };
    };
}
