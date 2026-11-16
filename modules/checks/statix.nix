# treefmt's statix formatter only applies fixes and never reports what it
# cannot fix, so the lint is enforced here as a check instead. `self` is the
# consuming flake, so leaves lint their own sources.
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.statix = pkgs.runCommandLocal "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${self}
        statix check .
        touch $out
      '';
    };
}
