# Normalize a profile/module value into a class-keyed attrset for `systemClass`
# (`"nixos"` or `"darwin"`), plus the always-present `homeManager` key.
#
# Shared by the host builders (`mkNixosHost`/`mkDarwinHost`) to split a list of
# profiles/modules into system-level and Home Manager-level lists. A plain list
# is treated as system-level modules; a class-keyed attrset (i.e. a
# `flake.profiles.*` value) is passed through; a bare module/path is wrapped as
# a single system-level module.
#
# Lives under `lib/` but is `_`-prefixed so the auto-loader skips it (it's a
# helper, not a builder).
systemClass: value:
if builtins.isList value then
  {
    ${systemClass} = value;
    homeManager = [ ];
  }
else if builtins.hasAttr systemClass value then
  value
else
  {
    ${systemClass} = [ value ];
    homeManager = [ ];
  }
