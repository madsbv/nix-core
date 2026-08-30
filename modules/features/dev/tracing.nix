# Tracing / introspection tooling (NixOS only): BPF compiler collection,
# sysdig, strace and perf. `perf` is taken from the boot kernel's package set so
# it matches the running kernel.
_: {
  flake.modules.nixos.tracing =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.bcc.enable = true;
      programs.sysdig.enable = true;
      environment.systemPackages = [
        pkgs.strace
        config.boot.kernelPackages.perf
      ];
    };
}
