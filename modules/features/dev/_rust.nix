{ inputs }:
_: {
  flake.modules.nixos.rust = _: {
    nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
  };

  flake.modules.darwin.rust = _: {
    nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
  };

  flake.modules.homeManager.rust =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        # Standalone Home Manager (the work laptop) owns its own nixpkgs, so the
        # rust-overlay must be applied here too; integrated hosts get it from the
        # OS-level `nixos.rust` / `darwin.rust` modules via `useGlobalPkgs`.
        nixpkgs.overlays = lib.mkIf (!config.submoduleSupport.enable) [
          inputs.rust-overlay.overlays.default
        ];

        programs.bacon = {
          enable = true;
          settings = {
            keybindings = {
              s = "toggle-summary";
              w = "toggle-wrap";
              b = "toggle-backtrace";
              esc = "back";
              g = "scroll-to-top";
              shift-g = "scroll-to-bottom";
              k = "scroll-lines(-1)";
              j = "scroll-lines(1)";
              ctrl-u = "scroll-page(-1)";
              ctrl-d = "scroll-page(1)";
              a = "job:check-all";
              i = "job:initial";
              c = "job:clippy-all";
              d = "job:doc-open";
              t = "job:nextest";
              r = "job:run";
              f = "job:clippy-fix";
              v = "job:semver-checks";
            };
            jobs = {
              # Default-coverage jobs: as wide a check range as possible.
              check-all = {
                command = [
                  "cargo"
                  "check"
                  "--all-targets"
                  "--all-features"
                ];
                need_stdout = false;
              };
              clippy-all = {
                command = [
                  "cargo"
                  "clippy"
                  "--all-targets"
                  "--all-features"
                ];
                need_stdout = false;
              };
              nextest = {
                command = [
                  "cargo"
                  "nextest"
                  "run"
                  "--all-features"
                  "--hide-progress-bar"
                  "--failure-output"
                  "final"
                ];
                need_stdout = true;
                analyzer = "nextest";
              };
              semver-checks = {
                command = [
                  "cargo"
                  "semver-checks"
                ];
                need_stdout = true;
              };
              clippy-fix = {
                command = [
                  "cargo"
                  "clippy"
                  "--fix"
                  "--allow-staged"
                  "--color"
                  "always"
                ];
                need_stdout = false;
              };
            };
          };
        };

        home =
          let
            cargoHome = "${config.home.homeDirectory}/.cargo";
            # Parallel rustc frontend (`-Z threads`, nightly);
            # 0 = auto-detect the CPU count.
            parallel = [
              "-Z"
              "threads=0"
            ];
          in
          {
            sessionPath = [ "${cargoHome}/bin" ];
            sessionVariables = {
              CARGO_HOME = cargoHome;
              CARGO_TARGET_DIR = "${cargoHome}/target";
            }
            // lib.mkIf pkgs.stdenv.isDarwin {
              # Fix cargo failing to find libiconv when C-linking on Darwin.
              LIBRARY_PATH = "${pkgs.darwin.libiconv}/lib";
            };
            file.".cargo/config.toml".text = ''
              [alias]     # command aliases
              b = "build"
              c = "check"
              t = ["nextest", "run", "--all-features"]
              r = "run"
              rr = "run --release"

              [build]
              target-dir = "${cargoHome}/target"         # path of where to place all generated artifacts
              incremental = true            # whether or not to enable incremental compilation
              rustflags = [${lib.concatStringsSep ", " (map (f: "\"${f}\"") parallel)}]

              [target.x86_64-unknown-linux-gnu]
              # Same rustflags as [build], plus the mold linker.
              rustflags = [${
                lib.concatStringsSep ", " (map (f: "\"${f}\"") parallel)
              }, "-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/ld.mold"]

              [future-incompat-report]
              frequency = "always" # when to display a notification about a future incompat report

              [net]
              git-fetch-with-cli = true
            '';
            packages =
              let
                # Equivalent of rust-overlay's
                # `selectLatestNightlyWith (toolchain: toolchain.default.override {...})`,
                # inlined because selectLatestNightlyWith misbehaves (returns a
                # bare lambda) inside a module-scoped pkgs. The overlay README
                # itself warns against `nightly.latest` since some days miss a
                # component; walking manifests downwards skips those days.
                pickNightly =
                  idx:
                  let
                    dates = builtins.attrNames (builtins.removeAttrs pkgs.rust-bin.nightly [ "latest" ]);
                    pkg = pkgs.rust-bin.nightly.${lib.elemAt dates idx}.default.override {
                      extensions = [
                        "rust-src"
                        "rust-analyzer"
                      ];
                    };
                  in
                  if idx == 0 || (builtins.tryEval pkg.drvPath).success then pkg else pickNightly (idx - 1);
                toolchain = pickNightly (
                  lib.length (builtins.attrNames (builtins.removeAttrs pkgs.rust-bin.nightly [ "latest" ])) - 1
                );
              in
              [
                toolchain
                pkgs.cargo-audit
                pkgs.cargo-flamegraph
                pkgs.cargo-generate
                pkgs.cargo-diet
                pkgs.cargo-msrv
                pkgs.cargo-nextest
                pkgs.cargo-watch
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [
                # 251122: Version 0.45 failing to build on Darwin.
                pkgs.cargo-semver-checks
              ];
          };
      };
    };
}
