_: {
  flake.modules.nixos.docker =
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
  flake.modules.darwin.docker = _: {
    config = {
      mine.darwin.brew.casks = [ "docker" ];
    };
  };
}
