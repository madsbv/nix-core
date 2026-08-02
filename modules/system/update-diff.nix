# Show a package diff between the running system and the incoming one on
# activation. From srvos (MIT, Jörg Thalheim):
#   https://github.com/Mic92/dotfiles/blob/.../upgrade-diff.nix
#   https://github.com/nix-community/srvos/blob/main/shared/common/update-diff.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.srvos.update-diff = {
    enable = lib.mkEnableOption "show package diff when updating" // {
      default = true;
    };
    command = lib.mkOption {
      type = lib.types.singleLineStr;
      # dix < 1.4.2 fails with "attempt to write a readonly database" when
      # reading the Nix sqlite DB as non-root (faukah/dix#47), which broke
      # activation. Fall back to nvd on older nixpkgs that ship those versions.
      default =
        if lib.versionAtLeast (pkgs.dix.version or "0") "1.4.2" then
          "${lib.getExe pkgs.dix} --force-correctness"
        else
          "${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff";
      defaultText = lib.literalExpression ''"''${lib.getExe pkgs.dix} --force-correctness"'';
      description = "diff command";
    };
    text = lib.mkOption {
      type = lib.types.str;
      description = "diff script snippet";
    };
  };

  config = {
    srvos.update-diff = {
      text = ''
        if [[ -e /run/current-system && -e "''${incoming-}" ]]; then
          echo "--- diff to current-system"
          ${config.srvos.update-diff.command} /run/current-system "''${incoming-}"
          echo "---"
        fi
      '';
    };
  };
}
