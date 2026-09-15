# Shared recipes for the fleet, imported by each repo's root justfile:
#   import '../core/just/common.just'
#
# Sub-importing justfiles must define `doom_flake` (flake ref exposing
# `doomdirs.<hostname>`) and may override anything else (directories and the
# `allow-duplicate-recipes` setting handle overrides in importers).

# Shorthand imports may rely on (defined unconditionally here so recipes work
# in any repo):
host := `hostname`

fmt:
    treefmt

check: fmt
    nix flake check

update:
    nix flake update

# ---- Doom Emacs store-built DOOMDIR ----

# Build the store DOOMDIR to a test link only (no relink, no doom sync).
doomdir-build doom_flake=doom_flake:
    nix build --out-link /tmp/doomdir-test --print-out-paths "{{ doom_flake }}#doomdirs.{{ host }}"

# Rebuild the store DOOMDIR, relink ~/.config/doom, then doom sync.
doomdir doom_flake=doom_flake:
    #!/usr/bin/env sh
    set -eu
    out=$(nix build --print-out-paths "{{ doom_flake }}#doomdirs.{{ host }}")
    if [ -e "$HOME/.config/doom" ] && [ ! -L "$HOME/.config/doom" ]; then echo "error: $HOME/.config/doom exists and is not a symlink" >&2; exit 1; fi
    ln -sfn "$out" "$HOME/.config/doom"
    "$HOME/.config/emacs/bin/doom" sync --aot -j 16
