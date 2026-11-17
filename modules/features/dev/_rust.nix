{ inputs }:
_: {
  flake.modules = {
    nixos.rust = _: {
      nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
    };

    darwin.rust = _: {
      nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
    };

    homeManager.rust =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cargoHome = "${config.home.homeDirectory}/.cargo";
        # Parallel rustc frontend (nightly `-Z threads`) plus the other nightly
        # flags the legacy config used. Target-specific `rustflags` replace, not
        # merge with, `[build]`, so the target table repeats this list.
        rustflags = [
          "-Z"
          "threads=8"
          "-C"
          "target-feature=+avx2"
          "-Zshare-generics=y"
          "-Zcache-proc-macros"
        ];
        cargoToml = (pkgs.formats.toml { }).generate "cargo-config" config.mine.rust.cargoConfig;
      in
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

          # Cargo config as an attrset: core sets the defaults below, leaves merge
          # extra keys (e.g. `mine.rust.cargoConfig.build.jobs`) into it.
          mine.rust.cargoConfig = {
            alias = {
              b = "build";
              c = "check";
              t = [
                "nextest"
                "run"
                "--all-features"
              ];
              n = "nextest";
              nr = "nextest run";
              i = "insta test";
              ir = "insta review";
              r = "run";
              rr = "run --release";
            };
            build = {
              target-dir = "${cargoHome}/target";
              incremental = true;
              sbom = true;
              inherit rustflags;
            };
            target.x86_64-unknown-linux-gnu.rustflags = rustflags ++ [
              "-C"
              "link-arg=-fuse-ld=${pkgs.mold}/bin/ld.mold"
            ];
            resolver.feature-unification = "workspace";
            unstable = {
              mtime-on-use = true;
              feature-unification = true;
              sbom = true;
              checksum-freshness = true;
              build-dir-new-layout = true;
              fine-grain-locking = true;
            };
            future-incompat-report.frequency = "always";
            net.git-fetch-with-cli = true;
          };

          home = {
            sessionPath = [ "${cargoHome}/bin" ];
            sessionVariables = {
              CARGO_HOME = cargoHome;
              CARGO_TARGET_DIR = "${cargoHome}/target";
            }
            // lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
              # Fix cargo failing to find libiconv when C-linking on Darwin.
              LIBRARY_PATH = "${pkgs.darwin.libiconv}/lib";
            };
            file.".cargo/config.toml".source = cargoToml;
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
                pkgs.rustPlatform.bindgenHook
                pkgs.cargo-audit
                pkgs.cargo-flamegraph
                pkgs.cargo-generate
                pkgs.cargo-diet
                pkgs.cargo-msrv
                pkgs.cargo-nextest
                pkgs.cargo-watch
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                # 251122: Version 0.45 failing to build on Darwin.
                pkgs.cargo-semver-checks
              ];
          };
        };
      };
  };
}
