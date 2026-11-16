# Quality gates propagated to leaf flakes via `flakeModules.default`: treefmt
# formatting, the statix lint check, pre-commit hooks, and the CI entrypoint.
#
# Curried over core's pinned inputs (like the builders) because the treefmt-nix
# and git-hooks flake modules must resolve to core's inputs, not a leaf's.
# `namaka.nix` is deliberately not imported here: snapshot tests are core-only.
{ inputs }:
{
  imports = [
    (import ./treefmt.nix { inherit inputs; })
    ./statix.nix
    (import ./git-hooks.nix { inherit inputs; })
    ./platforms.nix
    ./ci.nix
  ];
}
