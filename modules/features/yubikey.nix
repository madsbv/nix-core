_: {
  flake.modules.nixos.yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.mine.yubikey.enable = lib.mkEnableOption "Yubikey hardware support (yubikey-agent + CLI tools)";
      config = lib.mkIf config.mine.yubikey.enable {
        services.yubikey-agent.enable = true;
        environment.systemPackages = with pkgs; [
          yubikey-manager
          yubioath-flutter
        ];
      };
    };

  flake.modules.darwin.yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.mine.yubikey.enable = lib.mkEnableOption "Yubikey hardware support (yubikey-agent + CLI tools)";
      config = lib.mkIf config.mine.yubikey.enable {
        services.yubikey-agent.enable = true;
        environment.systemPackages = with pkgs; [
          yubikey-manager
          yubioath-flutter
        ];
      };
    };

  flake.modules.homeManager.yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.mine.yubikey.enable = lib.mkEnableOption "Yubikey CLI tools";
      config = lib.mkIf config.mine.yubikey.enable {
        home.packages = [ pkgs.yubikey-manager ];
      };
    };
}
