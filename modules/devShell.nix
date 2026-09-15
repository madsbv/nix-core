# Development shell with tooling for the entire fleet: just, git, formatting
# (nixfmt/statix/deadnix), agenix-rekey (secrets management), and deploy-rs.
# Uses `config.flake.inputs` (core's pinned inputs re-exported by the framework)
# so it works identically when consumed by core itself or by a leaf.
{
  config,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShell {
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
          config.flake.inputs.deploy-rs.packages.${system}.default
          config.flake.inputs.agenix-rekey.packages.${system}.default
          config.flake.inputs.nix-auth.packages.${system}.default
          config.flake.inputs.namaka.packages.${system}.default
        ];
      };
    };
}
