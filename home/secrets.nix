{
  inputs,
  config,
  ...
}: {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  # Point to the age key you generated (see setup steps below)
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../secrets/secrets.yaml;

  sops.secrets.anthropic_api_key = {};
  sops.secrets.gemini_api_key = {};
  sops.secrets.rad_passphrase = {};

  # Generate EnvironmentFile for radicle-node service
  sops.templates."radicle.env" = {
    content = ''
      RAD_PASSPHRASE=${config.sops.placeholder.rad_passphrase}
    '';
  };
}
