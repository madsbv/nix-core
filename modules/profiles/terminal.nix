_: {
  flake.profiles.terminal = {
    nixos = [ ];
    homeManager = [ "terminal" ];
    darwin = [ "terminal" ];
  };
}
