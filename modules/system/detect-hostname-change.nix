# Protection against deploying a system closure to the wrong host: warn (and
# require confirmation) if the machine's actual hostname differs from the
# configured one. From srvos.
#
# Option declaration lives in `modules/options.nix` (see
# `mine.system.detectHostnameChange`); this module only wires the behavior.
{
  config,
  lib,
  ...
}:
{
  config =
    lib.mkIf (config.mine.system.detectHostnameChange.enable && config.networking.hostName != "")
      {
        system.preSwitchChecks.detectHostnameChange = ''
          detectHostnameChange() {
            local actual
            actual=$(< /proc/sys/kernel/hostname)

            # Ignore if the system is getting installed
            if [[ ! -e /run/booted-system || "$actual" == "nixos-installer" ]]; then
              return
            fi

            desired=${config.networking.hostName}

            if [[ "$actual" = "$desired" ]]; then
              return
            fi

            # Useful for automation
            if [[ "''${EXPECTED_HOSTNAME:-}" = "$desired" ]]; then
              return
            fi

            log() {
              echo "$*" >&2
            }

            log "WARNING: machine hostname change detected from '$actual' to '$desired'"
            log
            log "Are you deploying on the right host?"
            log
            log "Type YES to continue:"
            read -r reply
            if [[ $reply != YES ]]; then
              echo "aborting"
              exit 1
            fi
          }
          detectHostnameChange
        '';
      };
}
