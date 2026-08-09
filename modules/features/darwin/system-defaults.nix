_: {
  flake.modules.darwin.system-defaults = { lib, ... }: {
    system = {
      defaults = {
        NSGlobalDomain = {
          ApplePressAndHoldEnabled = lib.mkDefault false;
          AppleShowAllExtensions = lib.mkDefault true;
          AppleEnableMouseSwipeNavigateWithScrolls = lib.mkDefault true;
          AppleEnableSwipeNavigateWithScrolls = lib.mkDefault true;
          AppleICUForce24HourTime = lib.mkDefault true;
          AppleMeasurementUnits = lib.mkDefault "Centimeters";
          AppleTemperatureUnit = lib.mkDefault "Celsius";
          AppleMetricUnits = lib.mkDefault 1;
          AppleInterfaceStyleSwitchesAutomatically = lib.mkDefault true;
          KeyRepeat = lib.mkDefault 2;
          InitialKeyRepeat = lib.mkDefault 15;
          "com.apple.trackpad.scaling" = lib.mkDefault 1.0;
          "com.apple.mouse.tapBehavior" = lib.mkDefault 1;
          "com.apple.sound.beep.volume" = lib.mkDefault 0.0;
          "com.apple.sound.beep.feedback" = lib.mkDefault 0;
          NSAutomaticSpellingCorrectionEnabled = lib.mkDefault false;
          NSAutomaticWindowAnimationsEnabled = lib.mkDefault false;
          NSScrollAnimationEnabled = lib.mkDefault true;
          _HIHideMenuBar = lib.mkDefault true;
        };
        dock = {
          autohide = lib.mkDefault true;
          autohide-delay = lib.mkDefault 0.0;
          autohide-time-modifier = lib.mkDefault 0.0;
          show-recents = lib.mkDefault true;
          launchanim = lib.mkDefault false;
          orientation = lib.mkDefault "bottom";
          tilesize = lib.mkDefault 48;
          mru-spaces = lib.mkDefault false;
        };
        finder = {
          _FXShowPosixPathInTitle = lib.mkDefault true;
          CreateDesktop = lib.mkDefault false;
          ShowPathbar = lib.mkDefault true;
          ShowStatusBar = lib.mkDefault true;
          AppleShowAllExtensions = lib.mkDefault true;
          AppleShowAllFiles = lib.mkDefault true;
        };
        trackpad = {
          Clicking = lib.mkDefault true;
          TrackpadThreeFingerDrag = lib.mkDefault false;
          ActuationStrength = lib.mkDefault 0;
        };
        universalaccess = {
          reduceMotion = lib.mkDefault false;
        };
      };
      keyboard = {
        enableKeyMapping = lib.mkDefault true;
        remapCapsLockToControl = lib.mkDefault true;
      };
    };
  };
}
