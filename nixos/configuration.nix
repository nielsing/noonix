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
  services.tailscale.enable = true;

  # Add documentation 
  documentation = {
    enable = true;
    man.enable = true;
    doc.enable = true;
    dev.enable = true;
    info.enable = true;
    nixos.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Nix specifics
    home-manager

    # GUIs
    (burpsuite.override {proEdition = true;})
    android-studio
    bemoji # Emoji selector using wofi
    chromium
    discord
    firefox
    ghidra
    kitty
    pavucontrol
    postman
    slack
    spotify
    xfce.thunar

    # General basics
    brightnessctl
    libnotify
    man-pages
    man-pages-posix
    networkmanagerapplet
    pamixer
    pinentry-qt
    poppler-utils

    # (Hypr|Way)land basics
    hyprpolkitagent
    waybar
    wl-clipboard
    wofi
    wtype

    # Screenshots & recording in Hyprland
    grim
    hyprpicker
    hyprshot
    slurp

    # CLI Tools
    dig
    evans
    feh
    file
    gnupg
    htop
    hyperfine
    jadx
    jq
    libqalculate
    moreutils
    mprocs
    neovim
    openssl
    ripgrep
    ripgrep-all
    sshuttle
    temporal
    temporal-cli
    tldr
    units
    unixtools.xxd
    unzip
    watchexec
    wget
    whois
    wireguard-tools
    yq
    zip
    zizmor

    # Development tools
    alejandra
    ansible
    basedpyright
    ccls
    gcc
    go
    gopls
    just
    kubectl
    lua
    lua-language-server
    nixd
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    python3
    rustup
    stylua
    terraform
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
