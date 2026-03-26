# Nix language support
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    nix-mode = {
      enable = true;
      mode = [''"\\.nix\\'"''];
      hook = [
        "(nix-mode . subword-mode)"
        ''
          (nix-mode . (lambda ()
                        (direnv-update-environment)
                        (lsp-deferred)))
        ''
      ];
      config = ''
        ;; Configure nixd as the Nix language server
        (with-eval-after-load 'lsp-mode
          ;; Default to alejandra for projects without .nixd.json
          (setq lsp-nix-nixd-formatting-command ["${pkgs.alejandra}/bin/alejandra"])

          (lsp-register-client
            (make-lsp-client
              :new-connection (lsp-stdio-connection "${pkgs.nixd}/bin/nixd")
              :major-modes '(nix-mode)
              :priority 0
              :server-id 'nixd)))

        ;; Format on save via LSP
        (add-hook 'before-save-hook
          (lambda ()
            (when (eq major-mode 'nix-mode)
              (lsp-format-buffer))))
      '';
    };

    nix-sandbox = {
      enable = true;
      command = ["nix-current-sandbox" "nix-shell-command"];
    };
  };
}
