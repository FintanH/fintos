final: prev: let
  version = "1.10.0-rc.2";
  prevName = "radicle-node";
  finalName = "${prevName}-overlay";
in {
  ${finalName} = prev.${prevName}.overrideAttrs (finalAttrs: prevAttrs: {
    inherit version;
    pname = finalName;

    src = final.fetchgit {
      inherit (prevAttrs.src) url;
      tag = "releases/${version}";
      hash = "sha256-8cFYsR5fGiChBduBmNcYp0MLVqlY2KnfieFa+yzbL7E=";
      leaveDotGit = true;
      postFetch = ''
        git -C $out rev-parse HEAD > $out/.git_head
        git -C $out log -1 --pretty=%ct HEAD > $out/.git_time
        rm -rf $out/.git
      '';
    };

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = "sha256-E5CDlHcdFFwRw3S+wLcRLpLzrGVn43z4FznJrYemYP4=";
    };

    doCheck = false;
  });
}
