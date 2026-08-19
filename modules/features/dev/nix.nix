_: {
  flake.modules.homeManager.nix-dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      nixfmt
      nil
      deadnix
      statix
    ];
  };
}
