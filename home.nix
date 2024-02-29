{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./home/emacs.nix
    ./home/git.nix
    ./home/starship.nix
    ./home/zsh.nix
  ];

  home.username = "fintohaps";
  home.homeDirectory = "/home/fintohaps";
  services.emacs = {
    enable = true;
    defaultEditor = true;
  };

  # Configure fonts
  fonts.fontconfig.enable = true;

  # User profile packages
  home.packages = with pkgs; [
    # Fonts
    (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono" "DejaVuSansMono" "FantasqueSansMono"];})

    # archives
    unzip
    zip

    # lsp
    python3
    semgrep
    rust-analyzer

    # utils
    btop
    fzf
    jq
    ripgrep
    tree
    wget
    which

    # system tools
    pciutils
    usbutils

    # development
    asciidoctor
    delta # git-delta
    direnv
    niv

    # application
    element-desktop
    obsidian
    zoom-us

    # radicle
    inputs.radicle.packages.x86_64-linux.radicle-remote-helper
    inputs.radicle.packages.x86_64-linux.radicle-cli
    inputs.radicle.packages.x86_64-linux.radicle-node
    inputs.radicle.packages.x86_64-linux.radicle-httpd
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
