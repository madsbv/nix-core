# Namaka snapshot-test wiring.
#
# `namaka.lib.load` evaluates each `tests/*/expr.nix`, serializes the result,
# and compares it against the committed `tests/_snapshots/` files; it returns
# `{ }` on success and throws on mismatch, so wiring it as the flake `checks`
# output makes `nix flake check` fail on any drift.
#
# The tests are pure evaluation (no builds), so they produce byte-identical
# snapshots on every machine — provided the evaluated expressions don't depend
# on `builtins.currentSystem` or other impure builtins. Core's builders pin
# `system` explicitly, so cross-machine (NixOS on a Mac, darwin on Linux) is
# safe; see PLAN.md Milestone 6 for the analysis.
{
  self,
  lib,
  config,
  ...
}:
{
  flake.checks = config.flake.inputs.namaka.lib.load {
    src = ../tests;
    inputs = {
      inherit lib;
      # `self` (and `super`/`root`) are reserved input names in haumea/namaka,
      # so the flake's own outputs are exposed as `flake` for host snapshot
      # tests (e.g. `flake.nixosConfigurations.<host>...`).
      flake = self;
    };
  };
}
