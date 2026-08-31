_: {
  flake.modules.homeManager.python = { pkgs, ... }: {
    home.packages = with pkgs; [
      python3
      ruff
      uv
      ty
    ];
    programs.uv = {
      enable = true;
      settings = {
        python-downloads = "never";
        python-preference = "only-system";
      };
    };
  };
}
