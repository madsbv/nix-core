_: {
  flake.modules.nixos.docker = _: {
    config = {
      virtualisation.docker.enable = true;
    };
  };
  flake.modules.darwin.docker = _: {
    config = {
      mine.darwin.brew.casks = [ "docker" ];
    };
  };
}
