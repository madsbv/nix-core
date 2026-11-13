# GitLab tooling: CLI, local CI runner and their shell shortcuts. Instance- or
# org-specific settings (hosts, push options, identities) belong in the leaf.
_: {
  flake.modules.homeManager.gitlab =
    {
      lib,
      pkgs,
      ...
    }:
    let
      yamlFormat = pkgs.formats.yaml { };
      glab = lib.getExe pkgs.glab;
    in
    {
      home = {
        packages = [
          pkgs.glab
          pkgs.gitlab-ci-local
          pkgs.gitlab-ci-ls
        ];
        shellAliases = {
          gcl = lib.getExe pkgs.gitlab-ci-local;
          mr = "${glab} mr";
          ci = "${glab} ci";
        };
        # https://docs.gitlab.com/cli/#environment-variables
        sessionVariables.GLAB_SEND_TELEMETRY = "false";
      };

      programs.git.ignores = [ "/.gitlab-ci-local/" ];

      xdg.configFile."glab-cli/aliases.yml".source = yamlFormat.generate "glab-cli-aliases" {
        co = "mr checkout";
        cis = "ci status";
        clgen = "changelog generate";
        varls = "variable list";
        mrls = "mr list";
      };
    };
}
