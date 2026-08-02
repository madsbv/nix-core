_: {
  flake.modules.homeManager.emacs = { ... }: {
    services.emacs.enable = true;
  };
}
