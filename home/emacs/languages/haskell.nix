# Haskell language support
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    haskell-mode = {
      enable = true;
      command = [
        "haskell-decl-scan-mode"
        "haskell-doc-mode"
        "haskell-indentation-mode"
        "interactive-haskell-mode"
      ];
      mode = [
        ''("\\.hs\\'" . haskell-mode)''
        ''("\\.hsc\\'" . haskell-mode)''
        ''("\\.c2hs\\'" . haskell-mode)''
        ''("\\.cpphs\\'" . haskell-mode)''
        ''("\\.lhs\\'" . literate-haskell-mode)''
      ];
      hook = [
        ''
          (haskell-mode
           . (lambda ()
               (subword-mode +1)
               (interactive-haskell-mode +1)
               (haskell-doc-mode +1)
               (haskell-indentation-mode +1)
               (haskell-decl-scan-mode +1)))
        ''
      ];
      bindLocal = {
        haskell-mode-map = {
          "C-c h i" = "haskell-navigate-imports";
          "C-c r o" = "haskell-mode-format-imports";
          "C-<right>" = "haskell-move-nested-right";
          "C-<left>" = "haskell-move-nested-left";
        };
      };
      config = ''
        (require 'haskell)
        (require 'haskell-doc)

        (setq haskell-process-auto-import-loaded-modules t
              haskell-process-suggest-remove-import-lines t
              haskell-process-log t
              haskell-notify-p t)

        (setq haskell-process-args-cabal-repl
              '("--ghc-options=+RTS -M500m -RTS -ferror-spans -fshow-loaded-modules"))
      '';
    };

    haskell-cabal = {
      enable = true;
      mode = [''("\\.cabal\\'" . haskell-cabal-mode)''];
      bindLocal = {
        haskell-cabal-mode-map = {
          "C-c C-c" = "haskell-process-cabal-build";
          "C-c c" = "haskell-process-cabal";
          "C-c C-b" = "haskell-interactive-bring";
        };
      };
    };

    flycheck-haskell = {
      enable = true;
      hook = ["(flycheck-mode . flycheck-haskell-setup)"];
    };
  };
}
