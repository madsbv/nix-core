_: {
  flake.modules.homeManager.fortran = { pkgs, ... }: {
    home.packages = with pkgs; [
      fortls
      gfortran
      fpm
      fprettify
    ];
  };
}
