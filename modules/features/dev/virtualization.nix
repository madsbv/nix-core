_: {
  flake.modules.nixos.virtualization = { pkgs, ... }: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };
    programs.virt-manager.enable = true;
    environment.systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
    ];
  };
}
