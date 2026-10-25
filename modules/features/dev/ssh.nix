_: {
  flake.modules.homeManager.ssh =
    {
      config,
      lib,
      osConfig,
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
        # Global IdentityFile pointing at the agenix-deployed per-user SSH key
        # (`/run/agenix/id.<host>.<user>`), matching the old config's
        # `extraOptionOverrides.IdentityFile`. Required for `github.com`'s
        # `identitiesOnly` block and for fleet SSH auth.
        extraOptionOverrides.IdentityFile = lib.mkIf (
          config.mine.agenix.secretsDir != null
        ) osConfig.age.secrets."id.${config.mine.hostName}.${config.mine.user.username}".path;
      };

      programs.git.signing = lib.mkIf (config.mine.ssh.signingKey != null) {
        signByDefault = true;
        key = config.mine.ssh.signingKey;
      };
    };
}
