# Profile opt-out builder.
#
# Registers `flake.lib.withoutModules profile [ "name" ... ]`, which returns the
# profile with the named modules removed from every class. Hosts call it where
# they list their profiles, e.g.
#   profiles = [ base (config.flake.lib.withoutModules config.flake.profiles.dev [ "kubernetes" ]) ];
{ lib, ... }:
let
  profileLib = import ./_profiles.nix { inherit lib; };
in
_: {
  flake.lib.withoutModules = profileLib.without;
}
