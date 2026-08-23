# nix-core — shared core flake.

default:
    @just --list

fmt:
    treefmt

check: fmt
    nix flake check

update:
    nix flake update

# --- Doom Emacs store-built DOOMDIR ---

leaf := `[[ -d ../personal ]] && echo ../personal || echo ../work`
host := `hostname`

# Rebuild the store DOOMDIR, relink ~/.config/doom, then doom sync.
doomdir:
    set -euo pipefail
    out=$(nix build --print-out-paths "{{leaf}}#doomdirs.{{host}}")
    if [ -e "$HOME/.config/doom" ] && [ ! -L "$HOME/.config/doom" ]; then
        echo "error: $HOME/.config/doom exists and is not a symlink" >&2; exit 1
    fi
    ln -sfn "$out" "$HOME/.config/doom"
    "$HOME/.config/emacs/bin/doom" sync
