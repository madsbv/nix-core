_: {
  flake.modules.nixos.pipewire =
    { lib, ... }:
    {
      security.rtkit.enable = lib.mkDefault true;
      services.pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
      };
    };
}
