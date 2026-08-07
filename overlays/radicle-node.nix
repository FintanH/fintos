final: prev: let
  version = "1.10.0";
  prevName = "radicle-node";
  finalName = "${prevName}-overlay";
in {
  ${finalName} = prev.${prevName}.overrideAttrs (finalAttrs: prevAttrs: {
    inherit version;
    pname = finalName;

    src = final.fetchgit {
      inherit (prevAttrs.src) url;
      tag = "releases/${version}";
      hash = "sha256-msKnRL6T9Z+bSxknRvhKSE6rDlGA0e8aWwM1/PhUzZw=";
      leaveDotGit = true;
      postFetch = ''
        git -C $out rev-parse HEAD > $out/.git_head
        git -C $out log -1 --pretty=%ct HEAD > $out/.git_time
        rm -rf $out/.git
      '';
    };

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = "sha256-g23LqCXZt+/JX+1Nb9JCORxI0P/LJL2MZHg3lATKLd8=";
    };

    doCheck = false;
  });
}
