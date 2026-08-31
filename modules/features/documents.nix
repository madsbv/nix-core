# Writing / spell-checking / document tooling, restored from the old
# `common-packages` preset. `aspellWithDicts` deliberately uses the same dict
# set as the emacs feature so the two never diverge (Nix dedups the identical
# derivation). The `de` dictionary is dropped per the parity audit.
_: {
  flake.modules.homeManager.documents = { pkgs, ... }: {
    home.packages = with pkgs; [
      pandoc
      multimarkdown
      hunspell
      enchant
      languagetool
      fontconfig
      (aspellWithDicts (
        dicts: with dicts; [
          en
          en-computers
          en-science
          da
        ]
      ))
    ];
  };
}
