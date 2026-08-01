{
  inputs,
  lib,
  baseProfile,
}:
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
    {
      home = {
        inherit username homeDirectory;
        stateVersion = lib.mkDefault "25.05";
      };
    }
  ]
  ++ profilesHm
  ++ modules
  ++ identity;
}
