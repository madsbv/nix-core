# LaTeX / academic-writing toolchain, restored from the old `common-packages`
# preset (texlab LSP, the full TeX Live distribution, and bibutils).
_: {
  flake.modules.homeManager.latex = { pkgs, ... }: {
    home.packages = with pkgs; [
      texlab
      texliveFull
      bibutils
    ];
  };
}
