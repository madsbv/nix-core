_: {
  flake.modules.homeManager.ssh =
    {
      config,
      lib,
      ...
    }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            ServerAliveInterval = 0;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
          };
          "github.com" = lib.mkDefault {
            hostname = "github.com";
            identitiesOnly = true;
          };
        };
      };

      programs.git.signing = lib.mkIf (config.mine.ssh.signingKey != null) {
        signByDefault = true;
        key = config.mine.ssh.signingKey;
      };
    };
}
