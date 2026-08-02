{ inputs }:
_: {
  flake.modules.homeManager.nixvim =
    {
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
      };
    };
}
