# Rust language support
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    rustic = {
      enable = true;
      config = ''
        (setq rustic-analyzer-command
              '("${pkgs.rust-analyzer}/bin/rust-analyzer"))
        (setq rustic-cargo-bin
               "${pkgs.cargo}/bin/cargo")
        (setq rustic-cargo-fmt t)
        (setq rustic-format-on-save t)
      '';
    };

    lsp-rust = {
      enable = true;
      hook = [
        ''
          (rustic . (lambda ()
                         (direnv-update-environment)
                         (lsp)))
        ''
      ];
      config = ''
        (setq lsp-rust-analyzer-server-command
              "${pkgs.rust-analyzer}/bin/rust-analyzer")
      '';
    };
  };
}
