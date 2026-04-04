final: prev: {
  ollama = prev.ollama.overrideAttrs (finalAttrs: _prevAttrs: {
    version = "0.20.0";

    src = final.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v${finalAttrs.version}";
      hash = "sha256-QQKPXdXlsT+uMGGIyqkVZqk6OTa7VHrwDVmgDdgdKOY=";
    };

    vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
    proxyVendor = true;

    # TestPiRun_InstallAndWebSearchLifecycle requires npm and network access
    # unavailable in the sandbox; skip it alongside the existing exclusion.
    checkFlags = let
      skippedTests = [
        "TestPushHandler/unauthorized_push"
        "TestPiRun_InstallAndWebSearchLifecycle"
      ];
    in ["-skip=^${final.lib.concatStringsSep "$|^" skippedTests}$"];
  });
}
