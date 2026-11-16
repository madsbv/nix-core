_: {
  flake.profiles.base = {
    nixos = [
      "base"
      "cli-tools"
    ];
    homeManager = [
      "base"
      "cli-tools"
      "media"
      "documents"
    ];
    darwin = [
      "base"
      "cli-tools"
    ];
  };
}
