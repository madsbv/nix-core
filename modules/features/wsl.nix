# WSL display and interop for Home Manager on WSL: X clients use the Windows X
# server at the WSL default gateway, GL falls back to software. Opt-in: leaves
# import this only on WSL hosts (core cannot detect WSL).
_: {
  flake.modules.homeManager.wsl =
    { pkgs, ... }:
    {
      home = {
        packages = [ pkgs.wsl-open ];
        sessionVariables = {
          LIBGL_ALWAYS_INDIRECT = 1;
          LIBGL_ALWAYS_SOFTWARE = "true";
        };
      };

      # Evaluated by the shell, so the gateway address is resolved per session.
      # NOTE: only interactive zsh gets DISPLAY. The systemd user unit used by
      # `services.emacs` (features/editors/emacs.nix) does not inherit it, so a
      # daemon started at login may have no display. Emacs started from the shell
      # works. Fix would be a wrapper ExecStart that exports DISPLAY, not done yet.
      programs.zsh = {
        envExtra = "export DISPLAY=$(ip route show default | awk '{ print $3; exit }'):0.0";
        # The Ubuntu ping is used because nixpkgs ping lacks cap_net_raw.
        shellAliases.ping = "${pkgs.grc}/bin/grc /usr/bin/ping";
      };
    };
}
