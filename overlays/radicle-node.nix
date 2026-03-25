final: prev: let
  version = "1.8.0-rc.2";
  prevName = "radicle-node";
  finalName = "${prevName}-overlay";
in {
  ${finalName} = prev.${prevName}.overrideAttrs (finalAttrs: prevAttrs: {
    inherit version;
    pname = finalName;

    src = final.fetchgit {
      inherit (prevAttrs.src) url;
      tag = "releases/${version}";
      hash = "sha256-J+1URp8mzxdKwlNpgYtaEQBDSyDVYqsAMnxwogZWVWM=";
      leaveDotGit = true;
      postFetch = ''
        git -C $out rev-parse HEAD > $out/.git_head
        git -C $out log -1 --pretty=%ct HEAD > $out/.git_time
        rm -rf $out/.git
      '';
    };

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = "sha256-9+mlNQwV2bUyAXkPN7aflGuN/Xd32uT+JEjl48ZDeXY=";
    };

    doCheck = false;
  });
}
