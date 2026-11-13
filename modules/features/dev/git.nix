_: {
  flake.modules.homeManager.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.user) fullName email;
    in
    {
      programs = {
        git = {
          enable = true;
          lfs.enable = true;
          ignores = [
            (builtins.readFile ./gitignore_global)
            "/.direnv/"
            "/.devenv/"
          ];
          settings = {
            user = {
              name = fullName;
            }
            // lib.optionalAttrs (email != null) {
              inherit email;
            };
            init.defaultBranch = "main";
            credential.helper = "store";
            core.editor = "vim";
            pull.rebase = true;
            push = {
              autoSetupRemote = true;
              followTags = true;
              negotiate = true;
            };
            rebase.autoStash = true;
            blame = {
              date = "relative";
              showEmail = false;
              coloring = "highlightRecent";
              blankBoundary = true;
            };
            status = {
              relativePaths = false;
              aheadBehind = true;
              showStash = true;
            };
            rerere = {
              enabled = true;
              autoUpdate = true;
            };
            # Git-native shorthands. Shell aliases for the same commands are
            # deliberately not duplicated.
            alias = {
              aliases = "!git config --get-regexp ^alias\\. | cut -d . -f 2 | column -t -s \" \" --table-columns-limit 2";
              b = "branch -vv";
              ba = "branch -vv --all";
              be = "branch --edit-description";
              cfg = "config --list";
              co = "checkout";
              d = "diff";
              ds = "diff --staged";
              l = "log --oneline --graph --decorate --all";
              lnm = "log --oneline --decorate --no-merges";
              p = "pull";
              P = "push";
              s = "status";
              ss = "status --short";
              sh = "show";
              sw = "switch";
              last = "log -1 HEAD";
              first-commit = "log --reverse --max-parents=0 HEAD";
              amend = "commit --amend --no-edit";
              unstage = "reset HEAD --";
              wip = "commit -a --message 'WIP' --no-verify --no-gpg-sign";
            };
          };
        };

        delta = {
          enable = true;
          options = {
            features = "decorations";
            hyperlinks = true;
          };
        };

        difftastic = {
          enable = true;
          git = {
            enable = true;
            mode = "both";
          };
        };

        mergiraf = {
          enable = true;
          enableGitIntegration = true;
        };

        git-cliff.enable = true;
      };

      home = {
        packages = [ pkgs.git-absorb ];
        shellAliases.gwip = "git wip";
      };
    };
}
