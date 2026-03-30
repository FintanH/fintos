{
  config,
  pkgs,
  ...
}: {
  services.xserver.enable = true;

  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  services.desktopManager.gnome.enable = true;

  services.flatpak.enable = false;

  # These two conflict with each other
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs; [
    # Apps
    gnome-tweaks
    gnome-sound-recorder

    # Extensions
    gnomeExtensions.paperwm
    gnomeExtensions.appindicator
  ];
}
