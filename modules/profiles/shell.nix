# Shell profile: class-keyed aggregate of the shell feature.
_: {
  flake.profiles.shell = {
    nixos = [ "shell" ];
    homeManager = [ "shell" ];
    darwin = [ ];
  };
}
