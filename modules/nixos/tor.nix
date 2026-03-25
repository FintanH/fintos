{
  services.tor = {
    enable = true;
    enableGeoIP = false;
    openFirewall = true;
    relay = {
      role = "private-bridge";
      onionServices = {
        "radicle" = {
          map = [
            {port = 8776;}
          ];
          settings = {
            # Add rate limiting to the Radicle Tor onion service
            HiddenServiceEnableIntroDoSDefense = true;
            HiddenServiceEnableIntroDoSRatePerSec = 25;
            HiddenServiceEnableIntroDoSBurstPerSec = 100;
          };
        };
      };
    };
    settings = {
      ORPort = "auto";
      ClientUseIPv6 = true;
    };
    client.enable = true;
  };
}
