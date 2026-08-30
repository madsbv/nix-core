# System-wide CLI utilities restored from the old config's common package list.
#
# Installed on every host and in every class: `environment.systemPackages` on
# NixOS / nix-darwin (so root and non-HM users get them) and `home.packages`
# for Home Manager (so standalone HM-only hosts get them too). Installing into
# both the system and the user profile is intentional duplication, not a bug.
_:
let
  pkgList =
    pkgs: with pkgs; [
      bash-completion
      btop
      curlFull
      gdu
      htop
      iftop
      jq
      lsof
      parallel-full
      rage
      ripgrep
      sqlite
      unrar
      unzip
      watchexec
      wget
      yq
      zip
      zstd
    ];
in
{
  flake.modules.nixos.cli-tools = { pkgs, ... }: {
    environment.systemPackages = pkgList pkgs;
  };

  flake.modules.darwin.cli-tools = { pkgs, ... }: {
    environment.systemPackages = pkgList pkgs;
  };

  flake.modules.homeManager.cli-tools = { pkgs, ... }: {
    home.packages = pkgList pkgs;
  };
}
