_: {
  flake.profiles.desktop = {
    nixos = [
      "pipewire"
      "lightdm"
      "fonts"
      "xdg-desktop"
      "bluetooth-desktop"
      "printing"
      "awesomewm"
    ];
    homeManager = [
      "awesomewm"
    ];
    darwin = [ ];
  };
}
