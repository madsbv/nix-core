{ inputs }:
# Curried over core's pinned inputs (applied in `flake.nix`): `inputs` in a
# flake-parts module function would be the *leaf's* inputs when core is consumed
# as a flake module, which don't include deploy-rs / agenix-rekey. Same closure
# pattern as `modules/agenix.nix`.
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
          nixfmt
          statix
          deadnix
          inputs.deploy-rs.packages.${system}.default
          inputs.agenix-rekey.packages.${system}.default
        ];
      };
    };
}
