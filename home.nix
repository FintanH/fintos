{
  config,
  lib,
  pkgs,
  inputs,
  unstable,
  ...
}: let
  # Define custom packages
  destiny = pkgs.callPackage ./home/destiny.nix {};
in {
  imports = [
    ./home/emacs
    ./home/git.nix
    ./home/opencode.nix
    ./home/secrets.nix
    ./home/starship.nix
    ./home/zsh.nix
    ./hm/services/radicle.nix
    ./hm/profiles/radicle.nix
    ./hm/profiles/rust.nix
  ];
  home.username = "fintohaps";
  home.homeDirectory = "/home/fintohaps";

  services.emacs = {
    enable = true;
    defaultEditor = true;
  };

  # Enable automatic time zone and location
  dconf.settings = {
    "org/gnome/desktop/datetime" = {automatic-timezone = true;};
    "org/gnome/system/location" = {enabled = true;};
  };

  # Configure fonts
  fonts.fontconfig.enable = true;

  # User profile packages
  home.packages = with pkgs; [
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.dejavu-sans-mono
    pkgs.nerd-fonts.fantasque-sans-mono

    # archives
    unzip
    zip

    # lsp
    nixd
    alejandra
    python3

    # utils
    age
    btop
    fzf
    ghostty
    git-sizer
    jq
    magic-wormhole
    pdftk # PDF editing tool
    ripgrep
    rlwrap
    # Enable use of sshfs
    # See: nixos.org/manual/nixos/stable/#sec-sshfs-file-systems
    sshfs
    tree
    xclip
    wget
    which

    # age & sops
    sops
    ssh-to-age

    # AI
    aider-chat

    # system tools
    pciutils
    usbutils

    # development
    asciidoctor
    delta # git-delta
    difftastic
    direnv
    jujutsu # jj
    jjui
    lazyjj
    just
    mergiraf
    niv
    sequoia-sqop # stateless GPG key generating

    # Nix caching
    attic-client

    # CI/CD
    docker-compose
    podman
    podman-tui
    unstable.woodpecker-cli

    # application
    destiny
    element-desktop
    keet
    obsidian
    zoom-us

    # Screensharing
    xdg-desktop-portal

    # Ed25519 Seed Phrase Backup
    melt
  ];

  # Allow direnv to execute when cd'ing
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    # custom settings
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
