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
              t = "job:test";
              r = "job:run";
              f = "job:clippy-fix";
              v = "job:semver-checks";
            };
            jobs = {
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
              t = "test"
              r = "run"
              rr = "run --release"

              [build]
              target-dir = "${cargoHome}/target"         # path of where to place all generated artifacts
              incremental = true            # whether or not to enable incremental compilation

              [future-incompat-report]
              frequency = "always" # when to display a notification about a future incompat report

              [net]
              git-fetch-with-cli = true
            '';
            packages =
              with pkgs;
              [
                rust-bin.nightly.latest.default
                cargo-audit
                cargo-flamegraph
                cargo-generate
                cargo-diet
                cargo-msrv
                cargo-watch
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [
                # 251122: Version 0.45 failing to build on Darwin.
                cargo-semver-checks
              ];
          };
      };
    };
}
