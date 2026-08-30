# Tracing / introspection tooling (NixOS only): BPF compiler collection,
# sysdig, strace and perf. Ported from the old `presets/nixos/tracing`, with the
# same platform guards (bcc/sysdig are unavailable on some architectures).
_: {
  flake.modules.nixos.tracing =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.bcc.enable = !pkgs.stdenv.hostPlatform.isRiscV;
      programs.sysdig.enable = !pkgs.stdenv.hostPlatform.isAarch64 && !pkgs.stdenv.hostPlatform.isRiscV;

      environment.systemPackages = [
        pkgs.strace
        # Low priority so bcc's `trace` takes precedence over perf's.
        (lib.lowPrio pkgs.perf)
      ];
    };
}
