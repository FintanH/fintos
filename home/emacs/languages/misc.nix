# Miscellaneous language support
{pkgs, ...}: {
  programs.emacs.init.usePackage = {
    adoc-mode = {
      enable = true;
      mode = [
        ''"\\.txt\\'"''
        ''"\\.adoc\\'"''
      ];
    };

    cc-mode = {
      enable = true;
      defer = true;
      hook = [
        ''
          (c-mode-common . (lambda ()
                             (subword-mode)

                             (c-set-offset 'arglist-intro '++)))
        ''
      ];
    };

    dhall-mode = {
      enable = true;
      mode = [''"\\.dhall\\'"''];
    };

    dockerfile-mode = {
      enable = true;
      mode = [''"Dockerfile\\'"''];
    };

    # Configure AUCTeX
    latex = {
      enable = true;
      package = epkgs: epkgs.auctex;
      mode = [''("\\.tex\\'" . latex-mode)''];
      hook = [
        ''
          (LaTeX-mode
           . (lambda ()
               (turn-on-reftex)       ; Hook up AUCTeX with RefTeX.
               (auto-fill-mode)
               (define-key LaTeX-mode-map [adiaeresis] "\\\"a")))
        ''
      ];
      config = ''
        (setq TeX-PDF-mode t
              TeX-auto-save t
              TeX-parse-self t
              TeX-output-view-style '(("^pdf$" "." "evince %o")
                                      ( "^ps$" "." "evince %o")
                                      ("^dvi$" "." "evince %o")))

        ;; Add Glossaries command. See
        ;; http://tex.stackexchange.com/a/36914
        (eval-after-load "tex"
          '(add-to-list
            'TeX-command-list
            '("Glossaries"
              "makeglossaries %s"
              TeX-run-command
              nil
              t
              :help "Create glossaries file")))
      '';
    };

    # Setup RefTeX
    reftex = {
      enable = true;
      defer = true;
      config = ''
        (setq reftex-default-bibliography '("~/research/bibliographies/main.bib")
              reftex-cite-format 'natbib
              reftex-plug-into-AUCTeX t)
      '';
    };

    # Setup cperl-mode (preferred over default perl-mode)
    cperl-mode = {
      enable = true;
      defer = true;
      hook = ["ggtags-mode"];
      command = ["cperl-set-style"];
      config = ''
        ;; Avoid deep indentation when putting function across several
        ;; lines.
        (setq cperl-indent-parens-as-block t)

        ;; Use cperl-mode instead of the default perl-mode
        (defalias 'perl-mode 'cperl-mode)
        (cperl-set-style "PerlStyle")
      '';
    };

    # Setup ebib bibliography manager
    ebib = {
      enable = true;
      command = ["ebib"];
      hook = [
        # Highlighting of trailing whitespace is a bit annoying in ebib
        ''
          (ebib-index-mode-hook
           . (lambda ()
               (setq show-trailing-whitespace nil)))
        ''

        ''
          (ebib-entry-mode-hook
           . (lambda ()
               (setq show-trailing-whitespace nil)))
        ''
      ];
      config = ''
        (setq ebib-latex-preamble '("\\usepackage{a4}"
                                    "\\bibliographystyle{amsplain}")
              ebib-print-preamble '("\\usepackage{a4}")
              ebib-print-tempfile "/tmp/ebib.tex"
              ebib-extra-fields '(crossref
                                  url
                                  annote
                                  abstract
                                  keywords
                                  file
                                  timestamp
                                  doi))
      '';
    };

    octave = {
      enable = true;
      mode = [
        ''("\\.m\\'" . octave-mode)''
      ];
    };

    yaml-mode = {
      enable = true;
      mode = [''"\\.yaml\\'"''];
    };

    systemd = {
      enable = true;
      defer = true;
    };

    tt-mode = {
      enable = true;
      mode = [''"\\.tt\\'"''];
    };

    smart-tabs-mode = {
      enable = false;
      config = ''
        (smart-tabs-insinuate 'c 'c++ 'cperl 'java)
      '';
    };

    wc-mode = {
      enable = true;
      command = ["wc-mode"];
    };
  };
}
