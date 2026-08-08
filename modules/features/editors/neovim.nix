_: {
  flake.modules.nixos.neovim =
    { lib, ... }:
    {
      programs.neovim = {
        enable = lib.mkDefault true;
        vimAlias = lib.mkDefault true;
        viAlias = lib.mkDefault true;
        defaultEditor = lib.mkDefault true;
      };
    };
}
