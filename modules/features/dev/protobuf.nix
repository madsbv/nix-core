_: {
  flake.modules.homeManager.protobuf = { pkgs, ... }: {
    home.packages = [ pkgs.protobuf ];
  };
}
