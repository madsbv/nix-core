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
