_: {
  flake.modules.homeManager.nix-dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      nixfmt
      nil
      deadnix
      statix
      nix-tree
      nix-melt
    ];
  };

  # `nix-tree`/`nix-melt` are also useful as root (inspecting the store / GC
  # roots), so install them system-wide on NixOS in addition to the user profile.
  flake.modules.nixos.nix-dev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      nix-tree
      nix-melt
    ];
  };
}
