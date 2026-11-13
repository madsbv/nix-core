_: {
  flake.modules.homeManager.python = { pkgs, ... }: {
    home.packages = with pkgs; [
      python3
      python3Packages.pytest
      basedpyright
      marimo
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
