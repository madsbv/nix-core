# Development shell with tooling for the entire fleet: just, git, formatting
# (nixfmt/statix/deadnix), agenix-rekey (secrets management), and deploy-rs.
# Uses `config.flake.inputs` (core's pinned inputs re-exported by the framework)
# so it works identically when consumed by core itself or by a leaf.
{
  config,
  ...
}:
let
  flakeInputs = config.flake.inputs;
in
{
  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        # Installs the git hooks from `pre-commit.settings` on shell entry.
        inputsFrom = [ config.pre-commit.devShell ];
        packages = with pkgs; [
          git
          just
          age
          age-plugin-yubikey
          dix
          nix-output-monitor
          nixfmt
          statix
          deadnix
          config.treefmt.build.wrapper
          flakeInputs.deploy-rs.packages.${system}.default
          flakeInputs.agenix-rekey.packages.${system}.default
          flakeInputs.nix-auth.packages.${system}.default
          flakeInputs.namaka.packages.${system}.default
        ];
      };
    };
}
