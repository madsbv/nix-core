_: {
  flake.modules.homeManager.nixvim =
    {
      config,
      ...
    }:
    {
      imports = [ config.flake.inputs.nixvim.homeManagerModules.nixvim ];
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
