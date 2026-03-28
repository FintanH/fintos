# Pi extension packages built as Nix derivations.
# Packages with only peerDependencies (provided by pi at runtime) are
# simple tarball unpacks — no npm install needed.
#
# Usage in home-manager:
#   programs.pi.packages = [ pkgs.piPackages.plan-mode ];
#
final: prev: {
  # RustDex CLI binary — required by the pi-rustdex extension.
  # The extension only provides Pi tool wrappers; the actual indexer must be on PATH.
  rustdex = final.stdenv.mkDerivation rec {
    pname = "rustdex";
    version = "0.4.3";

    src = final.fetchzip {
      url = "https://github.com/burggraf/rustdex/releases/download/v${version}/rustdex-v${version}-linux-amd64.zip";
      hash = "sha256-igmT+Q05OG7kfB5iVXJwWzpjIfJPmj2EpJUGADCId8s=";
      stripRoot = false;
    };

    nativeBuildInputs = [final.autoPatchelfHook];
    buildInputs = [final.stdenv.cc.cc.lib final.openssl];

    installPhase = ''
      mkdir -p $out/bin
      cp rustdex $out/bin/
      chmod +x $out/bin/rustdex
    '';
  };

  piPackages = let
    mkSimplePiPackage = {
      pname,
      version,
      hash,
    }:
      final.runCommand "${pname}-${version}" {
        src = final.fetchurl {
          url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
          inherit hash;
        };
      } ''
        mkdir -p $out
        tar xzf $src --strip-components=1 -C $out
      '';
  in {
    plan-mode = mkSimplePiPackage {
      pname = "pi-plan-mode";
      version = "0.3.2";
      hash = "sha512-KEcLc7kjObNMgy/hYTdl4L3zBdo2Mpob7LIwA79RgFJwPyEXgGlvuPj+mMfsPHYVJ8JRNqL1+e4PRxuZvS123Q==";
    };

    superpowers-plus = mkSimplePiPackage {
      pname = "pi-superpowers-plus";
      version = "0.4.1";
      hash = "sha512-1a5e635jqK51a6vhctPAM+9PnVlruutR/CgRtPpSQ2sQF7G27c7ftnaLj/jXEIabZrmd/KXXK27OnvdZPE7eRw==";
    };

    gitnexus = mkSimplePiPackage {
      pname = "pi-gitnexus";
      version = "0.5.1";
      hash = "sha512-B8FaH2Eay2wOSdOVqxq3U6HXClNsF286qp60BUGrgiz2WBa4StM3ewZHAxCTLggjFlIES5/bvq/jSURz/FYHvg==";
    };

    rustdex = mkSimplePiPackage {
      pname = "pi-rustdex";
      version = "0.4.3";
      hash = "sha512-34QwuH8N58f9leu6q9eICnNh2MvICYye18gwKZdLTgfbHy9Wh+0eLMJ5m/uYC4wkXeV/5beQOFIhGiDRmKFcrQ==";
    };
  };
}
