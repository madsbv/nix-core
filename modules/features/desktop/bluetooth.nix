_: {
  flake.modules.nixos.bluetooth-desktop =
    _:
    {
      services.blueman.enable = true;
    };
}
