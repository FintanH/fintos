{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
    desktopManager.gnome = {
      enable = true;
    };
  };

  services.flatpak.enable = false;

  # These two conflict with each other
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs; [
    # Apps
    gnome3.gnome-tweaks
    gnome3.gnome-sound-recorder

    # Extensions
    gnomeExtensions.paperwm
    gnomeExtensions.appindicator
  ];
}
