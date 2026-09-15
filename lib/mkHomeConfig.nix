# Standalone Home Manager builder.
#
# Curried over core's pinned `inputs` and nixpkgs `lib`, then becomes a
# flake-parts module that registers `mkHomeConfig` on `config.flake.lib`
# (auto-discovered from `lib/` by the framework).
{ inputs, lib }:
{ config, ... }:
let
  baseProfile = config.flake.profiles.base;
in
{
  flake.lib.mkHomeConfig =
    {
      system,
      username,
      homeDirectory ? "/home/${username}",
      profiles ? [ baseProfile ],
      modules ? [ ],
      identity ? [ ],
    }:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      profilesHm = lib.concatLists (map (p: p.homeManager) profiles);
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        (
          {
            config,
            lib,
            ...
          }:
          {
            home = {
              inherit username homeDirectory;
              # Resolved from `mine.system.stateVersion` (core default unless the
              # leaf overrides); leaves may still set `home.stateVersion` directly.
              stateVersion = lib.mkDefault config.mine.system.stateVersionHomeFinal;
            };
          }
        )
      ]
      ++ profilesHm
      ++ modules
      ++ identity;
    };
}
