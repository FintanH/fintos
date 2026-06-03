# Rust language support
{pkgs, ...}: {
  programs.emacs.init.usePackage = {
    rustic = {
      enable = true;
      config = ''
        (setq rustic-format-trigger 'on-compile)
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
