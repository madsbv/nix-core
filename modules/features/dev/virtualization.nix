_: {
  flake.modules.nixos.virtualization = { pkgs, ... }: {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    environment.systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
      swtpm
      virtiofsd
    ];
  };
}
