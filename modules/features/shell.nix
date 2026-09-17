# Shell feature: zsh + starship + the CLI companions (fzf/zoxide/eza/bat/yazi/
# zellij/nix-index). Ported from the old `systemModules/shell` module.
#
# The alias set is defined once, below, and consumed by both classes: the user's
# zsh gets everything (`programs.zsh.shellAliases`, which lands in `.zshrc`),
# and NixOS additionally exports the portable subset system-wide via
# `environment.shellAliases` so root and non-Home-Manager shells get them too.
# Keeping them in `.zshrc` (rather than only in `.zprofile`) is what fixes the
# old nix-darwin/zellij issue where aliases weren't loaded in non-login shells.
let
  # Portable aliases: no XDG paths and no zsh-only integrations, so they are
  # valid for any user and any shell (bash, root, non-login).
  commonAliases =
    { pkgs, flakeRoot }:
    {
      gj = "just ${flakeRoot}";
      j = "just";
      ls = "${pkgs.eza}/bin/eza --binary --header --git --git-repos --all";
      l = "ls -alh";
      less = "${pkgs.less}/bin/less --ignore-case --LINE-NUMBERS";
      cat = "${pkgs.bat}/bin/bat";
      grep = "${pkgs.gnugrep}/bin/grep -i --color=always";
      psgrep = "ps aux | grep -v grep | grep";
      # nixvim has no native `vimdiffAlias`, so provide the equivalent as an
      # alias (nvim `-d` is diff mode).
      vimdiff = "nvim -d";
    };

  # User-only aliases: an XDG cache path and the zoxide wrappers, which only
  # make sense inside the user's interactive zsh.
  userAliases =
    { pkgs, cacheHome }:
    {
      wget = "${pkgs.wget}/bin/wget --hsts-file=${cacheHome}/.wget-hsts";
      f = "z";
      fj = "zi";
    };
in
{
  flake.modules.homeManager.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.sessionVariables = {
        LESSHISTFILE = "${config.xdg.cacheHome}/lesshst";
        WGETRC = "${config.xdg.configHome}/wgetrc";
        ZDOTDIR = "${config.xdg.configHome}/zsh";
        ZSH_CACHE = "${config.xdg.cacheHome}/zsh";
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autocd = false;
        dotDir = "${config.xdg.configHome}/zsh";
        enableVteIntegration = true;
        shellAliases =
          commonAliases {
            inherit pkgs;
            flakeRoot = config.mine.flakeRoot;
          }
          // userAliases {
            inherit pkgs;
            cacheHome = config.xdg.cacheHome;
          };
        history = {
          path = "${config.xdg.dataHome}/zsh/zsh_history";
          ignoreAllDups = true;
        };
        autosuggestion.enable = true;
        syntaxHighlighting = {
          enable = true;
          highlighters = [
            "main"
            "brackets"
          ];
        };
        plugins = [
          {
            name = "vi-mode";
            src = pkgs.zsh-vi-mode;
            file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          }
        ];
        initContent = ''
          source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
        '';
      };

      programs.starship = {
        enable = true;
        settings = {
          add_newline = true;
          format = "$directory$git_branch$git_status$fill$status$cmd_duration$jobs$direnv$python$golang$nodejs$rust$line_break$character";
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };
          directory.style = "blue";
        };
      };

      programs.fzf.enable = true;

      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
      };

      programs.zellij = {
        enable = true;
        # Autostart in zsh is intentionally off on client machines.
        enableZshIntegration = lib.mkDefault false;
        settings = {
          serialize_pane_viewport = true;
          theme = "default";
          scroll_buffer_size = 10000;
        };
      };

      programs.nix-index.enable = true;

      programs.bat = {
        enable = true;
        config.theme = "base16";
        extraPackages = with pkgs.bat-extras; [
          batman
          batgrep
        ];
      };

      home.packages = with pkgs; [
        just
        zsh-autocomplete
      ];
    };

  flake.modules.nixos.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Same aliases for root and for any shell without a Home Manager config.
      environment.shellAliases = commonAliases {
        inherit pkgs;
        flakeRoot = config.mine.flakeRoot;
      };

      programs.zsh = {
        enable = true;
      };
      # For zsh completion of system packages.
      environment.pathsToLink = [ "/share/zsh" ];
      users.defaultUserShell = lib.mkForce pkgs.zsh;
    };
}
