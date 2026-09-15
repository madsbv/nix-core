# nix-core — shared core flake.

# The leaf flake to operate on (workstations have personal, the work laptop
# has work).
leaf := `[ -d ../personal ] && echo ../personal || echo ../work`
doom_flake := leaf

import 'just/common.just'
