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
        # nix-darwin has no `services.yubikey-agent`; the agent runs as a
        # launchd agent via Home Manager (`homeManager.yubikey`).
        # `yubioath-flutter` is unavailable on Darwin (the OATH GUI comes from
        # homebrew's `yubico-authenticator` cask), so it is left out here.
        environment.systemPackages = with pkgs; [
          libfido2
          yubikey-manager
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
        # The agent service is provided by Home Manager (systemd user service on
        # Linux, launchd agent on Darwin) so the same wiring works on the Mac.
        services.yubikey-agent.enable = true;
        home.packages = [ pkgs.yubikey-manager ];
      };
    };
}
