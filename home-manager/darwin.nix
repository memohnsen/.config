{ inputs, lib, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePredicate = package:
    builtins.elem (lib.getName package) [ "claude-code" ];

  networking = {
    computerName = "Maddisen’s MacBook Pro";
    hostName = "Macbook";
    localHostName = "Maddisens-MacBook-Pro";
  };

  time.timeZone = "America/Los_Angeles";

  # This is the user nix-darwin applies user-scoped system settings for.
  system.primaryUser = "maddisenmohnsen";
  users.users.maddisenmohnsen = {
    home = "/Users/maddisenmohnsen";
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  environment.shells = [ pkgs.fish ];

  # Preserve the current macOS interaction settings declaratively.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      NSAutomaticCapitalizationEnabled = true;
    };

    dock = {
      autohide = true;
      orientation = "bottom";
      tilesize = 16;
      magnification = false;
      largesize = 16;
      show-recents = false;
      minimize-to-application = true;
    };

    finder.FXPreferredViewStyle = "icnv";

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      Dragging = false;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep native Homebrew tools and applications reachable while their
  # remaining macOS-specific packages are still intentionally installed.
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # Keep the remaining native macOS packages declarative without allowing a
  # rebuild to remove or upgrade anything unexpectedly.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      {
        name = "d12frosted/emacs-plus";
        trusted = true;
      }
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
    ];

    brews = [
      "gcc"
      "gnutls"
      "libgccjit"
      "librsvg"
      "little-cms2"
      "tree-sitter@0.25"
      "watchman"
      "zsh"
      "d12frosted/emacs-plus/emacs-plus@30"
    ];

    casks = [
      "1password-cli"
      {
        name = "nikitabobko/tap/aerospace";
        trusted = true;
      }
      "android-ndk"
      "android-platform-tools"
      "font-symbols-only-nerd-font"
      "ghostty"
      "karabiner-elements"
      "zulu@17"
    ];
  };

  # nix-darwin deliberately does not own existing administrator accounts, so
  # enforce only the login-shell field after the system shell is registered.
  system.activationScripts.postActivation.text = ''
    desiredShell="/run/current-system/sw/bin/fish"
    currentShell=$(/usr/bin/dscl . -read /Users/maddisenmohnsen UserShell | /usr/bin/awk '{ print $2 }')
    if [ "$currentShell" != "$desiredShell" ]; then
      echo "setting maddisenmohnsen login shell to Nix Fish..." >&2
      /usr/bin/dscl . -create /Users/maddisenmohnsen UserShell "$desiredShell"
    fi
  '';

  # macOS 26 protects /etc/pam.d/sudo_local from symlink replacement. Keep
  # authentication under macOS control since no custom PAM behavior is needed.
  security.pam.services.sudo_local.enable = false;

  system.configurationRevision =
    inputs.self.rev or inputs.self.dirtyRev or null;

  # This controls nix-darwin compatibility defaults. It should not be changed
  # during ordinary package or input updates.
  system.stateVersion = 6;
}
