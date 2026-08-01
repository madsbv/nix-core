{ inputs, ... }:
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
          nixfmt-rfc-style
          statix
          deadnix
          inputs.deploy-rs.packages.${system}.default
          inputs.agenix-rekey.packages.${system}.default
        ];
      };
    };
}
