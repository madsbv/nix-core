_: {
  flake.modules.homeManager.emacs =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Emacs wrapped with the nix-managed packages the Doom config depends on
      # (mu4e/vterm/pdf-tools/treesit grammars). Doom's straight prefers
      # built-in packages where requested (e.g. `(package! pdf-tools :built-in
      # 'prefer)`), mirroring the old `programs.emacs.extraPackages` wiring.
      emacs = pkgs.emacs.pkgs.withPackages (epkgs: [
        epkgs.mu4e
        epkgs.vterm
        epkgs.multi-vterm
        epkgs.pdf-tools
        epkgs.treesit-grammars.with-all-grammars
      ]);
    in
    {
      services.emacs = {
        enable = true;
        package = emacs;
      };

      # The wrapped emacs goes on PATH so the Doom framework (which launches
      # `emacs`) picks it up, plus the binaries the Doom modules expect.
      home.packages = [
        emacs
        pkgs.gnumake # :term vterm module build
        pkgs.clang-tools # clang-format (java/web formatting)
        pkgs.libxml2.bin # xmllint (:lang data)
        pkgs.html-tidy # tidy (:lang web)
        pkgs.python3Packages.grip # grip (:lang markdown +grip)
        pkgs.python3Packages.cython # cython (:lang python +cython)
        pkgs.aspell # (:checkers spell +aspell)
        pkgs.aspellDicts.en
        pkgs.symbola # Emacs fallback font
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.xclip # org-download-clipboard
        pkgs.maim # org-download screenshots
      ];
    };
}
