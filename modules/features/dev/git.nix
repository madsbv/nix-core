_: {
  flake.modules.homeManager.git =
    { config, ... }:
    let
      inherit (config.mine.user) fullName email;
    in
    {
      programs.git = {
        enable = true;
        userName = fullName;
        userEmail = email;
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };
    };
}
