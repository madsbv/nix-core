_: {
  flake.modules.homeManager.emacs =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # The old config built emacs with `withSQLite3`, `withWebP`,
      # `withTreeSitter` and `withNativeCompilation` all enabled. Those are now
      # nixpkgs defaults, so only `withImageMagick` (still default-off) needs an
      # explicit override to preserve the old behaviour.
      emacsBase = pkgs.emacs.override { withImageMagick = true; };

      # On Darwin, apply the homebrew-emacs-plus patches the old config used:
      # `fix-window-role` (yabai window management), `round-undecorated-frame`,
      # and `system-appearance` (OS light/dark mode). Linux needs no patches.
      emacsPkg =
        if pkgs.stdenv.isDarwin then
          emacsBase.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (pkgs.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
                sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
              })
              (pkgs.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/refs/heads/master/patches/emacs-30/round-undecorated-frame.patch";
                sha256 = "uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
              })
              (pkgs.fetchpatch {
                url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/system-appearance.patch";
                sha256 = "3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
              })
            ];
          })
        else
          emacsBase;

      # Emacs wrapped with the nix-managed packages the Doom config depends on
      # (mu4e/vterm/pdf-tools/treesit grammars). Doom's straight prefers
      # built-in packages where requested (e.g. `(package! pdf-tools :built-in
      # 'prefer)`), mirroring the old `programs.emacs.extraPackages` wiring.
      emacs = emacsPkg.pkgs.withPackages (epkgs: [
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
        (pkgs.aspellWithDicts (
          dicts: with dicts; [
            en
            en-computers
            en-science
            da
          ]
        )) # (:checkers spell +aspell) — same dict set as features/documents.nix
        pkgs.symbola # Emacs fallback font
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.xclip # org-download-clipboard
        pkgs.maim # org-download screenshots
      ];
    };
}
