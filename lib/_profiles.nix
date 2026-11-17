# Name-based profile helpers shared by the framework's builders.
#
# A profile lists module *names* per class (`nixos`, `homeManager`, `darwin`).
# `modulesFor` resolves them against the `flake.modules` registry; the names
# are typed as enums of that registry in `modules/flake-module.nix`, so a typo
# fails at evaluation time. `without` produces a profile with some modules
# removed, which is how hosts opt out of part of a profile.
#
# Lives under `lib/` but is `_`-prefixed so the auto-loader skips it.
{ lib }:
let
  memberNames = profile: lib.unique (profile.nixos ++ profile.homeManager ++ profile.darwin);
  classes = [
    "nixos"
    "homeManager"
    "darwin"
  ];
in
{
  modulesFor =
    registry: class: profiles:
    lib.concatMap (p: map (name: registry.${class}.${name}) p.${class}) profiles;

  manifest = profiles: {
    profiles = map (p: p.name) profiles;
    excluded = lib.filterAttrs (_: names: names != [ ]) (
      lib.listToAttrs (map (p: lib.nameValuePair p.name (p.excluded or [ ])) profiles)
    );
    modules = lib.genAttrs classes (class: lib.unique (lib.concatMap (p: p.${class}) profiles));
  };

  without =
    profile: names:
    let
      notMembers = lib.subtractLists (memberNames profile) names;
    in
    assert lib.assertMsg (notMembers == [ ]) ''
      withoutModules: ${lib.concatStringsSep ", " notMembers} not in profile '${profile.name}'
      (members: ${lib.concatStringsSep ", " (memberNames profile)})
    '';
    profile
    // {
      nixos = lib.subtractLists names profile.nixos;
      homeManager = lib.subtractLists names profile.homeManager;
      darwin = lib.subtractLists names profile.darwin;
      excluded = lib.unique ((profile.excluded or [ ]) ++ names);
    };
}
