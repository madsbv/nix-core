_: {
  flake.modules.nixos.prefetch =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.mine.prefetch;
      inputsStr = builtins.concatStringsSep " " cfg.inputs;
    in
    {
      config = lib.mkIf cfg.enable {
        systemd.services.nix-prefetch = {
          description = "Nix flake prefetch";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          environment = {
            GIT_AUTHOR_NAME = "nix-prefetch";
            GIT_AUTHOR_EMAIL = "nix-prefetch@localhost";
            GIT_COMMITTER_NAME = "nix-prefetch";
            GIT_COMMITTER_EMAIL = "nix-prefetch@localhost";
          };
          script = ''
            cd ${cfg.flake}
            nix flake update ${inputsStr} --commit-lock-file
            nix build .#${cfg.target} --no-link
          '';
        };
        systemd.timers.nix-prefetch = {
          description = "Nix flake prefetch timer";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.schedule;
            Persistent = true;
          };
        };
      };
    };

  flake.modules.homeManager.prefetch =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.prefetch;
      inputsStr = builtins.concatStringsSep " " cfg.inputs;
    in
    {
      config = lib.mkIf cfg.enable {
        systemd.user.services.nix-prefetch = {
          Unit.Description = "Nix flake prefetch";
          Service = {
            Type = "oneshot";
            Environment = [
              "GIT_AUTHOR_NAME=nix-prefetch"
              "GIT_AUTHOR_EMAIL=nix-prefetch@localhost"
              "GIT_COMMITTER_NAME=nix-prefetch"
              "GIT_COMMITTER_EMAIL=nix-prefetch@localhost"
            ];
            ExecStart = toString (
              pkgs.writeShellScript "nix-prefetch" ''
                cd ${cfg.flake}
                nix flake update ${inputsStr} --commit-lock-file
                nix build .#${cfg.target} --no-link
              ''
            );
          };
        };
        systemd.user.timers.nix-prefetch = {
          Unit.Description = "Nix flake prefetch timer";
          Install.WantedBy = [ "timers.target" ];
          Timer = {
            OnCalendar = cfg.schedule;
            Persistent = true;
          };
        };
      };
    };

  flake.modules.darwin.prefetch =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.prefetch;
      inputsStr = builtins.concatStringsSep " " cfg.inputs;
      prefetchScript = pkgs.writeShellScript "nix-prefetch" ''
        export GIT_AUTHOR_NAME=nix-prefetch
        export GIT_AUTHOR_EMAIL=nix-prefetch@localhost
        export GIT_COMMITTER_NAME=nix-prefetch
        export GIT_COMMITTER_EMAIL=nix-prefetch@localhost
        cd ${cfg.flake}
        nix flake update ${inputsStr} --commit-lock-file
        nix build .#${cfg.target} --no-link
      '';
    in
    {
      config = lib.mkIf cfg.enable {
        launchd.daemons.nix-prefetch = {
          serviceConfig = {
            ProgramArguments = [ "${prefetchScript}" ];
            StartCalendarInterval = [
              {
                Hour = 3;
                Minute = 0;
              }
            ];
            RunAtLoad = false;
          };
        };
      };
    };
}
