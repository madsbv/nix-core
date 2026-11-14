# Show a package diff between the running system and the incoming one on
# activation. From srvos (MIT, Jörg Thalheim):
#   https://github.com/Mic92/dotfiles/blob/.../upgrade-diff.nix
#   https://github.com/nix-community/srvos/blob/main/shared/common/update-diff.nix
#
# Option declarations live in `modules/options.nix` (see `mine.system.updateDiff`);
# this module wires the behavior and resolves the pkgs-dependent `command` default.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    mine.system.updateDiff = {
      command = lib.mkDefault "${lib.getExe pkgs.dix} diff";
      text = lib.mkDefault ''
        if [[ -e /run/current-system && -e "''${incoming-}" ]]; then
          echo "--- diff to current-system"
          ${config.mine.system.updateDiff.command} /run/current-system "''${incoming-}"
          echo "---"
        fi
      '';
    };

    system.activationScripts.preActivation.text = ''
      incoming="''${systemConfig-}"
      ${config.mine.system.updateDiff.text}
    '';
  };
}
