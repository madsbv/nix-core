# nix-core — shared core flake.

default:
    @just --list

fmt:
    treefmt

check: fmt
    nix flake check

update:
    nix flake update
