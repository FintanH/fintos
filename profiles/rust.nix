{
  pkgs,
  config,
  lib,
  ...
}: {
  home = {
    sessionPath = ["$HOME/.cargo/bin"];
    packages = with pkgs; [rustup];
  };

  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "${lib.getExe pkgs.clang}"
    rustflags = ["-C", "link-arg=-fuse-ld=${lib.getExe pkgs.mold}"]
  '';
}
