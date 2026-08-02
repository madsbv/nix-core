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
        settings = {
          user = {
            name = fullName;
          }
          // lib.optionalAttrs (email != null) {
            inherit email;
          };
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };
    };
}
