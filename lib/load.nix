# import-tree style loader: recursively returns every `.nix` file under `dir`
# as a module path, skipping files and directories whose basename starts with
# `_` (helpers) and non-regular files.
{
  # Basenames starting with `_` are helpers and never auto-loaded.
  skip ? (name: builtins.substring 0 1 name == "_"),
}:
{ dir }:
let
  isNixFile = name: builtins.match ".*\\.nix" name != null;

  walk =
    path:
    let
      entries = builtins.readDir path;
      process =
        name: type:
        if type == "directory" then
          if skip name then [ ] else walk (path + "/${name}")
        else if type == "regular" && isNixFile name && !(skip name) then
          [ (path + "/${name}") ]
        else
          [ ];
    in
    builtins.concatLists (map (name: process name entries.${name}) (builtins.attrNames entries));
in
builtins.sort (a: b: a < b) (walk dir)
