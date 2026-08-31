# Media/graphics CLI tooling, restored from the old `common-packages` preset.
_: {
  flake.modules.homeManager.media = { pkgs, ... }: {
    home.packages = with pkgs; [
      ffmpeg
      imagemagick
      graphviz
    ];
  };
}
