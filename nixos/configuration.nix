{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./docker.nix
    ./fonts.nix
    ./greeter.nix
    ./hyprland.nix
    ./networking.nix
    ./nix.nix
    ./timezone.nix
    ./users.nix

    # No touchy
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-b09fb35e-5c8a-423b-a855-76f0898d1190".device = "/dev/disk/by-uuid/b09fb35e-5c8a-423b-a855-76f0898d1190";

  # Configure keymap in X11, I don't think this is needed
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = with pkgs; [
    # Nix specifics
    home-manager

    # The Basics & Hyprland Basics
    ## GUIs
    android-studio
    bemoji # Emoji selector using wofi
    (burpsuite.override {proEdition = true;})
    chromium
    discord
    firefox
    ghidra
    kitty
    pavucontrol
    slack
    spotify
    xfce.thunar

    ## General basics
    brightnessctl
    libnotify
    networkmanagerapplet
    pamixer
    pinentry-qt
    poppler-utils

    ## (Hypr|Way)land basics
    inputs.hyprpolkitagent.packages."${pkgs.system}".hyprpolkitagent
    waybar
    wl-clipboard
    wofi
    wtype

    ## Screenshots & recording in Hyprland
    grim
    hyprpicker
    hyprshot
    slurp

    # CLI Tools
    dig
    feh
    file
    gnupg
    htop
    jadx
    jq
    libqalculate
    neovim
    openssl
    ripgrep
    sshuttle
    tldr
    unixtools.xxd
    unzip
    wget
    wireguard-tools
    zip

    # Development tools
    alejandra
    basedpyright
    ccls
    gcc
    go
    gopls
    kubectl
    lua
    lua-language-server
    nixd
    python3Full
    rustup
    stylua
    terraform-ls
    tinymist
    typst
    typstyle
    uv
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
