_: {
  flake.modules.homeManager.nix-dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      nixfmt-rfc-style
      nil
      deadnix
      statix
    ];
  };
}
