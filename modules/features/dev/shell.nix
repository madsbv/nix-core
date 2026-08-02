_: {
  flake.modules.homeManager.shell-dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      bash-language-server
      shellcheck
      shfmt
    ];
  };
}
