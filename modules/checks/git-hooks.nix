# Pre-commit hooks run the same formatter wrapper and statix check as the
# `nix fmt` / `nix flake check` paths. `check.enable = false` because the
# treefmt and statix checks already run in `nix flake check`. The dev shell
# installs the hooks via `config.pre-commit.devShell` (see `devShell.nix`).
{ inputs }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { config, ... }:
    {
      pre-commit = {
        check.enable = false;
        settings.hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
          statix.enable = true;
        };
      };
    };
}
