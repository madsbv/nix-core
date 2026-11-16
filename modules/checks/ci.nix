# CI entrypoint (`nix run .#ci`): the single command the thin GitHub Actions
# wrapper invokes. All CI logic lives here in Nix — `nix flake check` already
# runs the treefmt check derivation (formatting), the namaka snapshot tests,
# and any host checks, so this is the whole job.
#
# Leaves set `CORE_PATH` to the checked-out core so the check evaluates against
# the PR's core rather than the locked (narHash-pinned) one; core itself leaves
# it unset and just runs `nix flake check`.
_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      apps.ci = {
        type = "app";
        meta.description = "Run the fleet CI checks (`nix flake check`).";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "ci";
            text = ''
              args=(flake check)
              if [ -n "''${CORE_PATH:-}" ]; then
                args+=(--override-input core "$CORE_PATH")
              fi
              nix "''${args[@]}"
            '';
          }
        );
      };
    };
}
