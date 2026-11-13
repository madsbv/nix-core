# C/C++ build toolchain: compiler, build systems and the clang tooling used by
# editors. Ported from the legacy `modules/dev/default.nix`.
_: {
  flake.modules.homeManager.c-cpp =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        # `cc` resolves to gcc; clang stays available by name.
        (lib.hiPrio gcc)
        clang
        clang-tools
        llvm
        cmake
        gnumake
        pkg-config
      ];
    };
}
