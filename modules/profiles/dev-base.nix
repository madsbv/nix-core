_: {
  flake.profiles.dev-base = {
    nixos = [ ];
    homeManager = [
      "git"
      "lazygit"
      "gitlab"
      "ssh"
      "gh"
      "direnv"
      "dev-tools"
    ];
    darwin = [ ];
  };
}
