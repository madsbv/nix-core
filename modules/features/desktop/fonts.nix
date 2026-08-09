_: {
  flake.modules.nixos.fonts =
    { pkgs, lib, ... }:
    {
      fonts = {
        fontDir.enable = true;
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
