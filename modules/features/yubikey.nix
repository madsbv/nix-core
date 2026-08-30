_: {
  flake.modules.nixos.yubikey =
    {
      pkgs,
      ...
    }:
    {
      config = {
        services.yubikey-agent.enable = true;
        environment.systemPackages = with pkgs; [
          libfido2
          yubikey-manager
          yubioath-flutter
        ];
      };
    };

  flake.modules.darwin.yubikey =
    {
      pkgs,
      ...
    }:
    {
      config = {
        services.yubikey-agent.enable = true;
        environment.systemPackages = with pkgs; [
          libfido2
          yubikey-manager
          yubioath-flutter
        ];
      };
    };

  flake.modules.homeManager.yubikey =
    {
      pkgs,
      ...
    }:
    {
      config = {
        home.packages = [ pkgs.yubikey-manager ];
      };
    };
}
