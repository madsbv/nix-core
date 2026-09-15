{ inputs }:
_: {
  flake.modules.homeManager.nixvim =
    {
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];
      programs.nixvim = {
        # Explicitly pin nixvim's nixpkgs to core's nixpkgs (which `nixvim.inputs
        # .nixpkgs.follows` already aliases), so the "affected by `follows`"
        # warning is suppressed without introducing a second nixpkgs.
        nixpkgs.source = inputs.nixpkgs;
        enable = true;
        opts = {
          number = true;
          relativenumber = true;
          shiftwidth = 2;
          tabstop = 2;
          expandtab = true;
          clipboard = "unnamedplus";
          mouse = "a";
        };
        # GCC lets nvim compile treesitter grammars and other plugins at runtime.
        extraPackages = [ pkgs.gcc ];
        # Treesitter via nixvim's native plugin module. `grammarPackages` defaults
        # to `plugins.treesitter.package.allGrammars`, matching the old
        # `nvim-treesitter.withAllGrammars`.
        plugins.treesitter.enable = true;
      };
    };
}
