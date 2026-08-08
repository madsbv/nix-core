# NixOS-specific base content. Minimal — this is a feature, not a profile.
# Larger NixOS feature groupings that were split from here live in
# `profiles/system.nix` and `profiles/shell.nix`/`profiles/editors.nix`.
_:
{
  config,
  lib,
  ...
}:
{
  config = {
    time.timeZone = lib.mkDefault config.mine.location.timezone;

    system.stateVersion = lib.mkDefault config.mine.system.stateVersionFinal;

    system.autoUpgrade = lib.mkIf config.mine.system.autoUpgrade.enable {
      flake = config.mine.system.autoUpgrade.flake;
      persistent = true;
      allowReboot = true;
      randomizedDelaySec = "45min";
    };
  };
}
