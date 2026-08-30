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
            };
          };
        };

        home = {
          sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
          sessionVariables = {
            CARGO_HOME = "${config.home.homeDirectory}/.cargo";
            CARGO_TARGET_DIR = "${config.home.homeDirectory}/.cargo/target";
          };
          packages = with pkgs; [
            rust-bin.nightly.latest.default
            cargo-audit
            cargo-flamegraph
            cargo-generate
            cargo-watch
          ];
        };
      };
    };
}
