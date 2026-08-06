# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: let
  user-constants = import ./lib/user.nix;
in {
  imports = [
    # Include AMD configuration
    ./hardware/framework/13-inch/amd-ai-300-series/default.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./modules/nixos
    inputs.sops-nix.nixosModules.sops
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #########################################################################
  # Used for simulation testing in `heartwood`
  #########################################################################
  # Kernel modules for QEMU/talosctl networking
  boot.kernelModules = ["kvm-amd" "tun" "bridge" "veth"]; # or kvm-intel
  # /dev/kvm access
  virtualisation.libvirtd.enable = true; # or just ensure kvm group access
  networking.firewall.trustedInterfaces = ["talos+"];
  #########################################################################

  # Enable `fwupdmgr`: `refresh` to retrieve updates and `update` to apply them.
  services.fwupd.enable = true;

  networking.hostName = "haptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "Europe/Dublin";
  # Allow the time zone to be updated automatically.
  services.automatic-timezoned.enable = true;
  # GeoClue2 can time out on boot before automatic-timezoned connects to it.
  # Restart on failure so the service recovers without manual intervention.
  systemd.services.automatic-timezoned.serviceConfig.Restart = "on-failure";
  systemd.services.automatic-timezoned.serviceConfig.RestartSec = "10s";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "ie";
    xkb.variant = "";
  };

  # Configure console keymap
  console.keyMap = "ie";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [pkgs.cnijfilter2];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Run emacs service making the default EDITOR the custom emacs package with all
  # the bells and whistles
  services.emacs = {
    enable = true;
    defaultEditor = true;
    package = config.home-manager.users.fintohaps.programs.emacs.finalPackage;
  };
  environment.variables.VISUAL = "emacsclient -c -a ''";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fintohaps = {
    linger = true;
    isNormalUser = true;
    description = user-constants.fullName;
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      firefox
      #  thunderbird
    ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;
  nix.settings.trusted-users = ["root" "fintohaps"];

  # Per-VM secret directories
  systemd.tmpfiles.rules = [
    "d /run/vm-secrets 0750 root kvm -"
    "d /run/vm-secrets/pi 0750 root kvm -"
  ];

  # Configure sops secrets `/run/secrets/`
  sops = {
    age.keyFile = "${config.users.users.fintohaps.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/secrets.yaml;

    # Prevent secret removal during rebuild (for virtiofs stability)
    keepGenerations = 0;

    # Base secrets (used by templates and host services)
    secrets = {
      anthropic_api_key = {};
      gemini_api_key = {};
      rad_passphrase = {};
    };

    # Pi VM secrets - scoped to /run/vm-secrets/pi/
    templates = {
      "pi-env" = {
        content = ''
          ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
          GEMINI_API_KEY=${config.sops.placeholder.gemini_api_key}
        '';
        path = "/run/vm-secrets/pi/agent.env";
        group = "kvm";
        mode = "0440";
      };
      "pi-anthropic-key" = {
        content = config.sops.placeholder.anthropic_api_key;
        path = "/run/vm-secrets/pi/anthropic_api_key";
        group = "kvm";
        mode = "0440";
      };
      "pi-gemini-key" = {
        content = config.sops.placeholder.gemini_api_key;
        path = "/run/vm-secrets/pi/gemini_api_key";
        group = "kvm";
        mode = "0440";
      };
    };
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "fintohaps";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Flakes and the new command-line tool
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ── Nix Garbage Collection ─────────────────────────────────────
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;

  nix.extraOptions = ''
    min-free = ${toString (50 * 1024 * 1024 * 1024)}
    max-free = ${toString (100 * 1024 * 1024 * 1024)}
  '';

  # Fonts
  fonts.packages = with pkgs; [
    dejavu_fonts
    fantasque-sans-mono
    fira-code
    fira-code-symbols
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Development
    emacs
    fzf
    git
    glibc
    gnupg
    vim
    wget

    # Linux debugging
    pciutils
    usbutils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.nix-ld.enable = true;

  virtualisation = {
    # Enable common container config files in /etc/containers
    containers.enable = true;
    # Enable podman containers
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [8193];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["fintohaps"];
    };
  };

  # Tor
  services.tor = {
    enable = true; # Enables Tor in general, without it the line below is useless.
    client.enable = true;
  };

  # Mullvad VPN
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # https://github.com/Mic92/envfs
  services.envfs.enable = true;

  # Enable Ollama for AI agent models
  services.ollama = {
    enable = true;
    # Listen on all interfaces so microvms can reach the API.
    # Access is scoped via the firewall rule below (microbr only).
    host = "0.0.0.0";
    loadModels = map (m: m.id) (builtins.attrValues (import ./agent/models.nix));
  };

  # Allow microvms on the bridge to reach the Ollama API.
  networking.firewall.interfaces."microbr".allowedTCPPorts = [11434];

  # Query Ollama on localhost:11434
  services.open-webui.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
