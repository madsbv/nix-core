_: {
  flake.modules.homeManager.git =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.mine.user) fullName email;
    in
    {
      programs.git = {
        enable = true;
        ignores = [ (builtins.readFile ./gitignore_global) ];
        settings = {
          user = {
            name = fullName;
          }
          // lib.optionalAttrs (email != null) {
            inherit email;
          };
          init.defaultBranch = "main";
          credential.helper = "store";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase.autoStash = true;
          core.editor = "vim";
        };
      };
    };
}
