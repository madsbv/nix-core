# treefmt-nix propagates to leaf flakes so `nix fmt` and the treefmt check
# work identically in all three repos. The flakeModule is imported from
# core's pinned treefmt-nix input.
{ inputs }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };

      # Override the treefmt-nix formatter to disable the eval cache.
      # Without this, `nix fmt` uses ~/.cache/treefmt and can silently skip files
      # that the sandboxed `nix flake check` (which runs `treefmt --no-cache`)
      # correctly detects as unformatted.
      formatter = lib.mkForce (
        pkgs.writeShellScriptBin "treefmt" ''
          export TREEFMT_NO_CACHE=1
          exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
        ''
      );
    };
}
