# Rust language support
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    rustic = {
      enable = true;
      config = ''
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
    };
  };
}
