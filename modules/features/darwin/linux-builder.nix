_: {
  flake.modules.darwin.linux-builder =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.mine.darwin.linuxBuilder = {
        enable = lib.mkEnableOption "linux-builder VM for cross-compilation";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.darwin.linux-builder-x86_64;
          description = "The linux-builder package (defaults to x86_64 target for aarch64 hosts).";
        };
        speedFactor = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Build priority multiplier for the local linux-builder VM.";
        };
      };
      config = lib.mkIf config.mine.darwin.linuxBuilder.enable {
        nix.linux-builder = {
          enable = true;
          package = config.mine.darwin.linuxBuilder.package;
          inherit (config.mine.darwin.linuxBuilder) speedFactor;
        };
      };
    };
}
