{ inputs }:
_: {
  flake.modules.homeManager.direnv = { ... }: {
    imports = [ inputs.direnv-instant.homeModules.direnv-instant ];
    programs.direnv-instant.enable = true;
    programs.direnv = {
      nix-direnv.enable = true;
      silent = true;
      # https://direnv.net/man/direnv.toml.1.html
      config = {
        load_dotenv = true;
        strict_env = true;
        warn_timeout = "15s";
      };
    };
  };
}
