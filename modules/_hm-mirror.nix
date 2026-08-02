# Home Manager identity mirror.
#
# Helper module, imported into a per-user `home-manager.users.<name>.imports`
# (from `modules/system/users.nix` for NixOS and `lib/mkDarwinHost.nix` for
# nix-darwin). It copies the *system-side* `mine.*` values into the nested Home
# Manager evaluation, pruning to only the options that evaluation actually
# declares.
#
# The alternative — copying `config.mine` wholesale with `{ inherit (config)
# mine; }` — carries every `mine.*` option into the HM eval. Any option that is
# declared only in a system module (and not in `modules/options.nix`, which
# every class shares) then breaks HM evals. Pruning against the HM
# evaluation's own `options.mine` makes the mirror self-maintaining: new
# `mine.*` subtrees flow through automatically, and system-only options are
# silently excluded instead of erroring.
#
# Takes the system-side `mine` tree as `osMine`; used as the `mine` value in
# the HM evaluation. The per-user resolution of `mine.user` (to the *current*
# user, not the host's primary) is handled by `modules/options.nix`, not here.
{ osMine }:
{
  lib,
  options,
  ...
}:
let
  # Walks the system-side `mine` tree against the HM evaluation's option tree,
  # keeping only values whose option the HM eval actually declares. Plain option
  # groups (attrsets of options) are recursed into; individual options and
  # submodule options (which carry `_type = "option"` on the group itself) are
  # treated as leaves and copied whole — submodule values like `mine.users` /
  # `mine.user` don't nest their sub-options under the option object, so
  # recursing into them would drop everything.
  prune =
    mineTree: optTree:
    lib.filterAttrs (
      name: value:
      let
        child = optTree.${name} or null;
      in
      if child == null then
        false
      else if child ? _type && child._type == "option" then
        true
      else if lib.isAttrs value && lib.isAttrs child then
        prune value child != { }
      else
        true
    ) mineTree;
in
{
  mine = prune osMine (options.mine or { });
}
