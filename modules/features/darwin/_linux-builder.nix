# Linux-builder VM for nix-darwin hosts (builds x86_64-linux on Apple Silicon).
#
# Curried over core's pinned `inputs` so the package can be sourced from
# nixpkgs-multiverse (below) rather than `pkgs`, which is the leaf's darwin
# package set.
#
# Nixpkgs dropped `x86_64-linux` guest support on `aarch64-darwin` in
# NixOS/nixpkgs#535511 (commit 77b50cc, `nixos/lib/qemu-common.nix`). Upstream
# restoration is tracked in NixOS/nixpkgs#545991; once that lands, this
# workaround can be dropped and the default can return to
# `pkgs.darwin.linux-builder-x86_64`.
#
# In the meantime `darwin.linux-builder-x86_64` is sourced from a pre-drop
# nixpkgs revision via nixpkgs-multiverse, which exposes every nixpkgs revision
# as a package set: `multiverse.multiverse.<system>.at "<date-or-rev>"`.
{ inputs }:
{
  flake.modules.darwin.linux-builder =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      multiverse = inputs.multiverse.multiverse.${pkgs.system};
    in
    {
      options.mine.darwin.linuxBuilder = {
        package = lib.mkOption {
          type = lib.types.package;
          # 2026-06-15 is the last revision before x86_64-linux guest support
          # was dropped on aarch64-darwin (NixOS/nixpkgs#535511).
          default = (multiverse.at "2026-06-15").darwin.linux-builder-x86_64;
          description = "The linux-builder package (x86_64-linux guest for aarch64 hosts).";
        };
        speedFactor = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Build priority multiplier for the local linux-builder VM.";
        };
      };
      config = {
        nix.linux-builder = {
          enable = true;
          package = config.mine.darwin.linuxBuilder.package;
          inherit (config.mine.darwin.linuxBuilder) speedFactor;
        };
      };
    };
}
