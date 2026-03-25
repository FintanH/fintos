{
  lib,
  appimageTools,
  fetchurl,
  libepoxy,
}: let
  pname = "destiny";
  version = "latest";

  src = fetchurl {
    url = "https://github.com/LeastAuthority/destiny/releases/latest/download/destiny_linux_amd64.AppImage";
    sha256 = "sha256-7hUNi+PO35M8dgPJB/iAhD6nB/5Erzt77wboQNAEgVA=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [
      pkgs.libepoxy
    ];

    extraInstallCommands = ''
      # Install desktop file if present
      install -m 444 -D ${appimageContents}/destiny.desktop $out/share/applications/destiny.desktop || true

      # Install icon if present
      install -m 444 -D ${appimageContents}/destiny.png $out/share/icons/hicolor/256x256/apps/destiny.png || true

      # Fix desktop file paths
      substituteInPlace $out/share/applications/destiny.desktop \
        --replace-quiet 'Exec=AppRun' 'Exec=${pname}' || true
    '';

    meta = with lib; {
      description = "Destiny - Secure file transfer application";
      homepage = "https://github.com/LeastAuthority/destiny";
      license = licenses.mit; # Adjust if different
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "destiny";
    };
  }
