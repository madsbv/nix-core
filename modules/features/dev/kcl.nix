_: {
  flake.modules.homeManager.kcl =
    { pkgs, lib, ... }:
    {
      home.packages = [
        pkgs.kcl
      ]
      # kcl-language-server is not packaged for Darwin.
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.kcl-language-server ];
    };
}
