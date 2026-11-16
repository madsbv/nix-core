_: {
  flake.profiles.editors = {
    nixos = [ "neovim" ];
    homeManager = [
      "emacs"
      "nixvim"
    ];
    darwin = [ ];
  };
}
