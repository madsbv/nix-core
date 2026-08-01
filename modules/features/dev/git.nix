_: {
  flake.modules.homeManager.git =
    { config, ... }:
    let
      inherit (config.mine.user) fullName email;
    in
    {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = fullName;
            inherit email;
          };
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };
    };
}
