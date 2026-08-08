_: {
  config = {
    services.openssh = {
      enable = true;
      settings = {
        X11Forwarding = false;
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
      };
    };
  };
}
