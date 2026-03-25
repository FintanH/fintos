# Core editor packages - utilities, file handling, editing fundamentals
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    abbrev = {
      enable = true;
      diminish = ["abbrev-mode"];
      command = ["abbrev-mode"];
    };

    autorevert = {
      enable = true;
      diminish = ["auto-revert-mode"];
      command = ["auto-revert-mode"];
    };

    # Remember where we were in a previously visited file
    saveplace = {
      enable = true;
      config = ''
        (setq-default save-place t)
        (setq save-place-file (locate-user-emacs-file "places"))
      '';
    };

    # More helpful buffer names
    uniquify = {
      enable = true;
      config = ''
        (setq uniquify-buffer-name-style 'post-forward)
      '';
    };

    recentf = {
      enable = true;
      command = ["recentf-mode"];
      config = ''
        (setq recentf-save-file (locate-user-emacs-file "recentf")
              recentf-max-menu-items 20
              recentf-max-saved-items 500
              recentf-exclude '("COMMIT_MSG" "COMMIT_EDITMSG"))
      '';
    };

    dired = {
      enable = true;
      defer = true;
      config = ''
        (put 'dired-find-alternate-file 'disabled nil)
        ;; Use the system trash can.
        (setq delete-by-moving-to-trash t)
      '';
    };

    wdired = {
      enable = true;
      bindLocal = {
        dired-mode-map = {
          "C-c C-w" = "wdired-change-to-wdired-mode";
        };
      };
      config = ''
        ;; Allow editing file permissions in wdired
        (setq wdired-allow-to-change-permissions t)
      '';
    };

    dired-x = {
      enable = true;
      after = ["dired"];
    };

    ediff = {
      enable = true;
      defer = true;
      config = ''
        (setq ediff-window-setup-function 'ediff-setup-windows-plain)
      '';
    };

    eldoc = {
      enable = true;
      diminish = ["eldoc-mode"];
      command = ["eldoc-mode"];
    };

    # Enable Electric Indent mode for automatic indentation
    electric = {
      enable = true;
      command = ["electric-indent-local-mode"];
      hook = [
        "(prog-mode . electric-indent-mode)"
        # Disable for some modes
        "(nix-mode . (lambda () (electric-indent-local-mode -1)))"
      ];
    };

    etags = {
      enable = true;
      defer = true;
      # Avoid spamming reload requests of TAGS files
      config = "(setq tags-revert-without-query t)";
    };

    # Hook up hippie expand
    hippie-exp = {
      enable = true;
      bind = {
        "M-?" = "hippie-expand";
      };
    };

    undo-tree = {
      enable = true;
      demand = true;
      diminish = ["undo-tree-mode"];
      command = ["global-undo-tree-mode"];
      config = ''
        (setq undo-tree-visualizer-relative-timestamps t
              undo-tree-visualizer-timestamps t)
        (global-undo-tree-mode)
      '';
    };

    smartparens = {
      enable = true;
      defer = 1;
      diminish = ["smartparens-mode"];
      command = ["smartparens-global-mode" "show-smartparens-global-mode"];
      bindLocal = {
        smartparens-mode-map = {
          "C-M-f" = "sp-forward-sexp";
          "C-M-b" = "sp-backward-sexp";
        };
      };
      config = ''
        (require 'smartparens-config)
        (smartparens-global-mode t)
        (show-smartparens-global-mode t)
      '';
    };
  };
}
