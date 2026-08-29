# StevenBlack /etc/hosts blocklist (ported from the old `hosts.nixosModule`
# wiring). Curried over core's pinned `inputs` so the blocklist source resolves
# to core's `hosts` input even when this flake module is consumed by a leaf.
#
# Import-gated: importing `flake.modules.<class>.hosts` enables the blocklist.
#
# NixOS: StevenBlack ships a `nixosModule` that sets `networking.extraHosts`.
# nix-darwin has no `networking.extraHosts`; there we materialise the full hosts
# file via `environment.etc` (a symlink to the store path — read-only, which is
# fine for a blocklist, but be aware VPN clients that rewrite /etc/hosts would
# conflict with it). Home Manager cannot manage /etc/hosts, so it is not wired.
{ inputs }:
{
  flake.modules.nixos.hosts = {
    imports = [ inputs.hosts.nixosModule ];
    networking.stevenBlackHosts.enable = true;
  };

  flake.modules.darwin.hosts = {
    environment.etc."hosts" = {
      text = builtins.readFile (inputs.hosts + "/hosts");
    };
  };
}
