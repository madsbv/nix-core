# Fonts for graphical darwin hosts. Mirrors `features/desktop/fonts.nix`
# (NixOS); `feather-font` is intentionally omitted (PLAN.md: installed-but-unused).
# Note: nix-darwin has no `fonts.fontDir.enable` (NixOS-only option).
_: {
  flake.modules.darwin.fonts =
    { pkgs, lib, ... }:
    {
      fonts = {
        packages =
          with pkgs;
          [
            dejavu_fonts
            emacs-all-the-icons-fonts
            jetbrains-mono
            font-awesome
            hack-font
            meslo-lgs-nf
            noto-fonts
            noto-fonts-color-emoji
          ]
          ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
      };
    };
}
