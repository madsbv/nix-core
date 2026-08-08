{ inputs }:
_: {
  flake.modules.homeManager.direnv = { ... }: {
    imports = [ inputs.direnv-instant.homeModules.direnv-instant ];
    programs.direnv-instant.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
