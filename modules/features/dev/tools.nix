_: {
  flake.modules.homeManager.dev-tools = { pkgs, ... }: {
    programs.fd = {
      enable = true;
      hidden = true;
      ignores = [ ".git/" ];
    };
    home.packages = with pkgs; [
      devenv
      hyperfine
      yaml-language-server
      sqls
      vscode-langservers-extracted
    ];
  };
}
