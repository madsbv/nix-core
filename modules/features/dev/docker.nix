_: {
  flake.modules = {
    nixos.docker =
      {
        config,
        ...
      }:
      {
        config = {
          virtualisation.docker.enable = true;

          # Add the primary user to the `docker` group (the group is created by
          # the docker service). Previously this lived in the host identity's
          # extraGroups; owning it here keeps the group tied to the feature.
          mine.users.${config.mine.primaryUser}.extraGroups = [ "docker" ];
        };
      };

    darwin.docker = _: {
      #    config = {
      #      mine.darwin.brew.casks = [ "docker-desktop" ];
      #    };
    };

    # Client-side tooling for a daemon that runs elsewhere (NixOS service, Docker
    # Desktop, WSL integration). Podman is intentionally not included.
    homeManager.docker =
      { pkgs, lib, ... }:
      let
        docker-color-output = lib.getExe pkgs.docker-color-output;
      in
      {
        home = {
          packages = [
            pkgs.docker-compose
            pkgs.docker-color-output
            pkgs.dive
            pkgs.hadolint
            pkgs.regctl
          ];
          sessionVariables.DOCKER_BUILDKIT = 1;
          shellAliases = {
            d = "docker";
            di = "docker images --format=table | ${docker-color-output} -s";
            dps = "docker ps | ${docker-color-output} -s";
            dpsa = "docker ps --all | ${docker-color-output} -s";
            dcps = "docker compose ps | ${docker-color-output} -s";
            ds = "docker stats --format=table | ${docker-color-output} -s";
            dvls = "docker volume ls";
            dnls = "docker network ls";
          };
        };

        programs.lazydocker.enable = true;
      };
  };
}
