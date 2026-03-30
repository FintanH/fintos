# Heavily borrowed from https://gitlab.com/rycee/configurations/blob/d6dcf6480e29588fd473bd5906cd226b49944019/user/emacs.nix
{
  pkgs,
  config,
  lib,
  nurNoPkgs,
  ...
}: let
  models = import ../../agent/models.nix;
in {
  imports = [
    nurNoPkgs.repos.rycee.hmModules.emacs-init
    ./base.nix
    ./ui.nix
    ./org.nix
    ./languages
  ];

  programs.emacs = {
    enable = true;
    package = pkgs.emacs30;
    extraPackages = epkgs: [
    ];
  };
  programs.emacs.init = {
    enable = true;
    recommendedGcSettings = true;

    prelude = ''
      ;; Disable startup message.
      (setq inhibit-startup-message t
            inhibit-startup-echo-area-message (user-login-name))

      (setq initial-major-mode 'fundamental-mode
            initial-scratch-message nil)

      ;; Disable some GUI distractions.
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      (menu-bar-mode -1)
      (blink-cursor-mode 0)

      (defvar my/monitor-font-sizes
        '(("eDP-1" . 8.0)          ; laptop screen (adjust name to match yours)
          ("DP-3" . 6.0))          ; Lenovo desktop screen
        "Alist mapping monitor names to font sizes.")

      (defvar my/default-font-size 8.0
        "Default font size when monitor isn't in the list.")

      (defun my/get-current-monitor-name (&optional frame)
        "Get the name of the monitor FRAME is currently on."
        (let ((attrs (frame-monitor-attributes frame)))
          (cdr (assq 'name attrs))))

      (defun my/adjust-font-for-monitor (&optional frame)
        "Adjust font size based on which monitor FRAME is on."
        (interactive)
        (let* ((frame (or frame (selected-frame)))
               (monitor-name (my/get-current-monitor-name frame))
               (size (or (cdr (assoc monitor-name my/monitor-font-sizes))
                         my/default-font-size)))
          (set-frame-font
           (font-spec :family "FiraCode Nerd Font"
                      :size size
                      :weight 'normal
                      :width 'normal)
           nil (list frame))
          (message "Monitor: %s, Font size: %s" monitor-name size)))

      ;; Hook into frame movement
      (add-hook 'move-frame-functions #'my/adjust-font-for-monitor)

      ;; Also adjust on focus change (catches some edge cases)
      (add-function :after after-focus-change-function
                    (lambda ()
                      (when (frame-focus-state)
                        (my/adjust-font-for-monitor))))

      ;; Set initial font on startup
      (add-hook 'after-init-hook #'my/adjust-font-for-monitor)

      ;; Set frame title.
      (setq frame-title-format
            '("" invocation-name ": "(:eval
                                      (if (buffer-file-name)
                                          (abbreviate-file-name (buffer-file-name))
                                        "%b"))))

      ;; Add line numbers
      (global-display-line-numbers-mode t)

      ;; Shortcut for goto-line
      (global-set-key (kbd "C-c g") 'goto-line)

      ;; Shortcut for window split mnemonics
      (global-set-key (kbd "C-c h") 'split-window-horizontally)
      (global-set-key (kbd "C-c v") 'split-window-vertically)

      ;; Accept 'y' and 'n' rather than 'yes' and 'no'.
      (defalias 'yes-or-no-p 'y-or-n-p)

      ;; Don't want to move based on visual line.
      (setq line-move-visual nil)

      ;; Stop creating backup and autosave files.
      (setq make-backup-files nil
            auto-save-default nil)

      ;; Always show line and column number in the mode line.
      (line-number-mode)
      (column-number-mode)

      ;; Enable some features that are disabled by default.
      (put 'narrow-to-region 'disabled nil)

      ;; Typically, I only want spaces when pressing the TAB key. I also
      ;; want 4 of them.
      (setq-default indent-tabs-mode nil
                    tab-width 4
                    c-basic-offset 4)

      ;; Trailing white space are banned!
      (setq-default show-trailing-whitespace t)

      ;; Make a reasonable attempt at using one space sentence separation.
      (setq sentence-end "[.?!][]\"')}]*\\($\\|[ \t]\\)[ \t\n]*"
            sentence-end-double-space nil)

      ;; I typically want to use UTF-8.
      (prefer-coding-system 'utf-8)

      ;; Nicer handling of regions.
      (transient-mark-mode 1)

      ;; Make moving cursor past bottom only scroll a single line rather
      ;; than half a page.
      (setq scroll-step 1
            scroll-conservatively 5)

      ;; Enable highlighting of current line.
      (global-hl-line-mode 1)

      ;; Improved handling of clipboard in GNU/Linux and otherwise.
      (setq select-enable-clipboard t
            select-enable-primary t
            save-interprogram-paste-before-kill t)

      ;; Pasting with middle click should insert at point, not where the
      ;; click happened.
      (setq mouse-yank-at-point t)

      ;; Enable a few useful commands that are initially disabled.
      (put 'upcase-region 'disabled nil)
      (put 'downcase-region 'disabled nil)

      (setq custom-file (locate-user-emacs-file "custom.el"))
      (load custom-file)

      ;; When finding file in non-existing directory, offer to create the
      ;; parent directory.
      (defun with-buffer-name-prompt-and-make-subdirs ()
        (let ((parent-directory (file-name-directory buffer-file-name)))
          (when (and (not (file-exists-p parent-directory))
                     (y-or-n-p (format "Directory `%s' does not exist! Create it? " parent-directory)))
            (make-directory parent-directory t))))

      (add-to-list 'find-file-not-found-functions #'with-buffer-name-prompt-and-make-subdirs)

      ;; Don't want to complete .hi files.
      (add-to-list 'completion-ignored-extensions ".hi")

      ;; Shouldn't highlight trailing spaces in terminal mode.
      (add-hook 'term-mode (lambda () (setq show-trailing-whitespace nil)))
      (add-hook 'term-mode-hook (lambda () (setq show-trailing-whitespace nil)))

      ;; Ensure that column width is 80 when using fill-paragraph (M-q)
      (setq-default fill-column 80)
    '';

    usePackage = {
      ansi-color = {
        enable = true;
        command = ["ansi-color-apply-on-region"];
      };

      # From https://github.com/mlb-/emacs.d/blob/a818e80f7790dffa4f6a775987c88691c4113d11/init.el#L472-L482
      compile = {
        enable = true;
        defer = true;
        after = ["ansi-color"];
        hook = [
          ''
            (compilation-filter . (lambda ()
                                    (when (eq major-mode 'compilation-mode)
                                      (ansi-color-apply-on-region compilation-filter-start (point-max)))))
          ''
        ];
      };

      deadgrep = {
        enable = true;
        bind = {
          "C-x f" = "deadgrep";
        };
      };

      direnv = {
        enable = true;
        command = ["direnv-mode" "direnv-update-environment"];
      };

      drag-stuff = {
        enable = true;
        bind = {
          "M-<up>" = "drag-stuff-up";
          "M-<down>" = "drag-stuff-down";
        };
      };

      ggtags = {
        enable = true;
        defer = true;
        diminish = ["ggtags-mode"];
        command = ["ggtags-mode"];
      };

      ispell = {
        enable = true;
        defer = 1;
      };

      notifications = {
        enable = true;
        command = ["notifications-notify"];
      };

      flyspell = {
        enable = true;
        diminish = ["flyspell-mode"];
        command = ["flyspell-mode" "flyspell-prog-mode"];
        hook = [
          # Spell check in text and programming mode.
          "(text-mode . flyspell-mode)"
          "(prog-mode . flyspell-prog-mode)"
        ];
        config = ''
          ;; In flyspell I typically do not want meta-tab expansion
          ;; since it often conflicts with the major mode. Also,
          ;; make it a bit less verbose.
          (setq flyspell-issue-message-flag nil
                flyspell-issue-welcome-flag nil
                flyspell-use-meta-tab nil)
          (setq ispell-program-name "${pkgs.ispell}/bin/ispell")
        '';
      };

      ivy = {
        enable = true;
        demand = true;
        diminish = ["ivy-mode"];
        command = ["ivy-mode"];
        config = ''
          (setq ivy-use-virtual-buffers t
                ivy-count-format "%d/%d "
                ivy-virtual-abbreviate 'full)

          (ivy-mode 1)
        '';
      };

      ivy-xref = {
        enable = true;
        after = ["ivy" "xref"];
        command = ["ivy-xref-show-xrefs"];
        config = ''
          (setq xref-show-xrefs-function #'ivy-xref-show-xrefs)
        '';
      };

      swiper = {
        enable = true;
        command = ["swiper" "swiper-all" "swiper-isearch"];
        bind = {
          "C-s" = "swiper-isearch";
        };
      };

      # Lets counsel do prioritization. A fork of smex.
      amx = {
        enable = true;
        command = ["amx-initialize"];
      };

      counsel = {
        enable = true;
        bind = {
          "C-x C-d" = "counsel-dired-jump";
          "C-x C-f" = "counsel-find-file";
          "C-x C-r" = "counsel-recentf";
          "C-x C-y" = "counsel-yank-pop";
          "M-x" = "counsel-M-x";
        };
        diminish = ["counsel-mode"];
      };

      string-inflection = {
        enable = true;
        bind = {
          "C-c C-u" = "string-inflection-all-cycle";
        };
      };

      # Configure magit, a nice mode for the git SCM.
      magit = {
        enable = true;
        bind = {
          "C-x g" = "magit-status";
        };
        config = ''
          (setq magit-completing-read-function 'ivy-completing-read)
          (add-to-list 'git-commit-style-convention-checks
                       'overlong-summary-line)
        '';
      };

      magit-delta = {
        enable = true;
        hook = [
          "(magit-mode . magit-delta-mode)"
        ];
      };

      git-messenger = {
        enable = true;
        bind = {
          "C-x v p" = "git-messenger:popup-message";
        };
      };

      multiple-cursors = {
        enable = true;
        bind = {
          "C-S-c C-S-c" = "mc/edit-lines";
          "C-c m" = "mc/mark-all-like-this";
          "C->" = "mc/mark-next-like-this";
          "C-<" = "mc/mark-previous-like-this";
        };
      };

      avy = {
        enable = true;
        extraConfig = ''
          :bind* ("C-c SPC" . avy-goto-word-or-subword-1)
        '';
      };

      # company-lsp is deprecated - lsp-mode now uses company-capf
      company-lsp = {
        enable = false;
      };

      lsp-ui = {
        enable = true;
        command = ["lsp-ui-mode"];
        bind = {
          "C-c r d" = "lsp-ui-doc-show";
          "C-c f s" = "lsp-ui-find-workspace-symbol";
        };
        config = ''
          (setq lsp-ui-sideline-enable t
                lsp-ui-sideline-show-symbol nil
                lsp-ui-sideline-show-hover nil
                lsp-ui-sideline-show-code-actions nil
                lsp-ui-sideline-update-mode 'point
                lsp-ui-doc-enable nil)
        '';
      };

      lsp-ui-flycheck = {
        enable = true;
        command = ["lsp-ui-flycheck-enable"];
        after = ["flycheck" "lsp-ui"];
      };

      lsp-mode = {
        enable = true;
        command = ["lsp"];
        bind = {
          "C-c l r" = "lsp-rename";
          "C-c f b" = "lsp-format-buffer";
          "C-c f g" = "lsp-format-region";
          "C-c c a" = "lsp-execute-code-action";
          "C-c f r" = "lsp-find-references";
        };
        config = ''
          (setq lsp-eldoc-render-all nil
                lsp-prefer-flymake nil
                lsp-completion-provider :capf)
        '';
      };

      lsp-treemacs = {
        enable = true;
        after = ["lsp-mode" "treemacs"];
        config = ''
          (setq treemacs-python-executable
              "${pkgs.python3}/bin/python3")
        '';
      };

      dap-mode = {
        enable = true;
        after = ["lsp-mode"];
        command = ["dap-mode" "dap-ui-mode"];
        config = ''
          (dap-mode t)
          (dap-ui-mode t)
        '';
      };

      # Use ripgrep for fast text search in projects. I usually use
      # this through Projectile.
      ripgrep = {
        enable = true;
        command = ["ripgrep-regexp"];
        bind = {
          "C-c r" = "ripgrep-regexp";
        };
      };

      # Set up yasnippet. Defer it for a while since I don't generally
      # need it immediately.
      yasnippet = {
        enable = true;
        defer = 1;
        diminish = ["yas-minor-mode"];
        command = ["yas-global-mode" "yas-minor-mode"];
        hook = [
          # Yasnippet interferes with tab completion in ansi-term.
          "(term-mode . (lambda () (yas-minor-mode -1)))"
        ];
        config = "(yas-global-mode 1)";
      };

      # Doesn't seem to work, complains about # in go snippets.
      yasnippet-snippets = {
        enable = false;
        after = ["yasnippet"];
      };

      flycheck = {
        enable = true;
        diminish = ["flycheck-mode"];
        command = ["global-flycheck-mode"];
        defer = 1;
        config = ''
          ;; Only check buffer when mode is enabled or buffer is saved.
          (setq flycheck-check-syntax-automatically '(mode-enabled save))

          ;; Enable flycheck in all eligible buffers.
          (global-flycheck-mode)
        '';
      };

      flycheck-plantuml = {
        enable = true;
        hook = ["(flycheck-mode . flycheck-plantuml-setup)"];
      };

      projectile = {
        enable = true;
        diminish = ["projectile-mode"];
        command = ["projectile-mode"];
        bindKeyMap = {
          "C-c p" = "projectile-command-map";
        };
        config = ''
          (setq projectile-enable-caching t
                projectile-completion-system 'ivy)
          (projectile-mode 1)
        '';
      };

      plantuml-mode = {
        enable = true;
        mode = [''"\\.puml\\'"''];
      };

      company = {
        enable = true;
        diminish = ["company-mode"];
        hook = ["(after-init . global-company-mode)"];
        extraConfig = ''
          :bind (:map company-mode-map
                      ([remap completion-at-point] . company-complete-common)
                      ([remap complete-symbol] . company-complete-common))
        '';
        config = ''
          (setq company-idle-delay 0.3
                company-show-numbers t)
        '';
      };

      company-yasnippet = {
        enable = true;
        bind = {
          "M-/" = "company-yasnippet";
        };
      };

      company-dabbrev = {
        enable = true;
        after = ["company"];
        command = ["company-dabbrev"];
        config = ''
          (setq company-dabbrev-downcase nil
                company-dabbrev-ignore-case t)
        '';
      };

      company-quickhelp = {
        enable = true;
        after = ["company"];
        command = ["company-quickhelp-mode"];
        config = ''
          (company-quickhelp-mode 1)
        '';
      };

      company-cabal = {
        enable = true;
        after = ["company"];
        command = ["company-cabal"];
        config = ''
          (add-to-list 'company-backends 'company-cabal)
        '';
      };

      company-restclient = {
        enable = true;
        after = ["company" "restclient"];
        command = ["company-restclient"];
        config = ''
          (add-to-list 'company-backends 'company-restclient)
        '';
      };

      restclient = {
        enable = true;
        mode = [''("\\.http\\'" . restclient-mode)''];
      };

      sendmail = {
        enable = false;
        mode = [
          ''("mutt-" . mail-mode)''
          ''("\\.article" . mail-mode))''
        ];
        hook = [
          ''
            (lambda ()
                  (auto-fill-mode)     ; Avoid having to M-q all the time.
                  (rah-mail-flyspell)  ; I spel funily soemtijms.
                  (rah-mail-reftex)    ; Make it easy to include references.
                  (mail-text))         ; Jump to the actual text.
          ''
        ];
      };

      treemacs = {
        enable = true;
        bind = {
          "C-c t f" = "treemacs-find-file";
          "C-c t t" = "treemacs";
        };
      };

      treemacs-projectile = {
        enable = true;
        after = ["treemacs" "projectile"];
      };

      gptel = {
        enable = true;
        config = let
          defaultModel = models.qwen3-coder-30b.id;
          allModels = builtins.concatStringsSep " " (map (m: m.id) (builtins.attrValues models));
        in ''
          (setq gptel-model '${defaultModel}
            gptel-backend (gptel-make-ollama "Ollama"
             :host "localhost:11434"
             :stream t
             :models '(${allModels})))
        '';
      };
    };
  };
}
