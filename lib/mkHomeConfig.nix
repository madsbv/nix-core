{
  inputs,
  lib,
  optionsModule,
  agenixHomeManagerModule,
}:
{
  system,
  username,
  homeDirectory ? "/home/${username}",
  profiles ? [ ],
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
    optionsModule
    agenixHomeManagerModule
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
