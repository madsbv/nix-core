# Terminal UI for git. Generic settings only: company-specific branch naming and
# GitLab commands live in the GitLab feature and the work leaf.
_: {
  flake.modules.homeManager.lazygit =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      git = lib.getExe config.programs.git.package;
      lazygit = lib.getExe config.programs.lazygit.package;
    in
    {
      programs.lazygit = {
        enable = true;
        settings = {
          promptToReturnFromSubprocess = false;
          confirmOnQuit = false;
          # OSC 52 clipboard, so copies work through tmux/zellij.
          os.copyToClipboardCmd = ''printf "\033Ptmux;\033\033]52;c;$(printf {{text}} | base64 -w 0)\a\033\\" > /dev/tty'';
          git = {
            commit = {
              signOff = true;
              autoWrapCommitMessage = false;
            };
            pagers = [
              {
                pager = "${config.programs.delta.package}/bin/delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
              }
              {
                externalDiffCommand = "${config.programs.difftastic.package}/bin/difft --color=always";
              }
            ];
          };
          gui = {
            nerdFontsVersion = "3";
            showBottomLine = true;
            border = "single";
            showDivergenceFromBaseBranch = "arrowAndNumber";
            showBranchCommitHash = true;
            showNumstatInFilesView = true;
            sidePanelWidth = 0.5;
            mainBranches = [
              "main"
              "master"
            ];
            branchColorPatterns = {
              "^(main|master)$" = "magenta";
              "^docs/" = "blue";
              "^(feature|feat|enhancement)/" = "green";
              "^(bugfix|fix|hotfix)/" = "red";
              "^(release|rel|rc)/" = "yellow";
            };
            skipDiscardChangeWarning = true;
          };
          customCommands =
            let
              glab = lib.getExe pkgs.glab;
            in
            [
              {
                key = "G";
                command = "${glab} mr view -w {{.SelectedLocalBranch.UpstreamBranch}}";
                context = "localBranches";
                description = "Go to MR in gitlab";
                output = "log";
              }
              {
                key = "n";
                context = "commits";
                output = "terminal";
                command = "${git} notes edit --allow-empty {{.SelectedLocalCommit.Hash}}";
              }
              {
                key = "e";
                context = "localBranches";
                output = "terminal";
                command = "${git} branch --edit-description {{.SelectedLocalBranch.Name | quote}}";
              }
              {
                key = "b";
                context = "files";
                output = "logWithPty";
                command = "${lib.getExe pkgs.git-absorb} --one-fixup-per-commit";
              }
              {
                # stage modified files ('m' and 'M' are taken)
                key = "O";
                context = "files";
                output = "log";
                command = "${git} add $(${git} ls-files --modified)";
              }
            ];
          keybinding.universal = {
            nextBlock = "n";
            prevBlock = "N";
          };
        };
      };

      home.shellAliases = {
        lg = lazygit;
        lgb = "${lazygit} branch --screen-mode half";
        lgl = "${lazygit} log --screen-mode half";
        lgs = "${lazygit} status --screen-mode half";
      };
    };
}
