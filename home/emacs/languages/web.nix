# Web development support (HTML, CSS, JS, Markdown, XML)
{pkgs, ...}: {
  programs.emacs.init.usePackage = {
    js = {
      enable = true;
      mode = [
        ''("\\.js\\'" . js-mode)''
        ''("\\.json\\'" . js-mode)''
      ];
      config = ''
        (setq js-indent-level 2)
      '';
    };

    web-mode = {
      enable = true;
      mode = [
        ''"\\.html\\'"''
        ''"\\.jsx?\\'"''
      ];
      config = ''
        (setq web-mode-attr-indent-offset 4
              web-mode-code-indent-offset 2
              web-mode-markup-indent-offset 2)

        (add-to-list 'web-mode-content-types '("jsx" . "\\.jsx?\\'"))
      '';
    };

    markdown-mode = {
      enable = true;
      mode = [
        ''"\\.mdwn\\'"''
        ''"\\.markdown\\'"''
        ''"\\.md\\'"''
      ];
      config = ''
        (custom-set-variables
            '(markdown-command "${pkgs.pandoc}/bin/pandoc"))
      '';
    };

    pandoc-mode = {
      enable = true;
      after = ["markdown-mode"];
      hook = ["markdown-mode"];
      bindLocal = {
        markdown-mode-map = {
          "C-c C-c" = "pandoc-run-pandoc";
        };
      };
    };

    nxml-mode = {
      enable = true;
      mode = [''"\\.xml\\'"''];
      config = ''
        (setq nxml-child-indent 4
              nxml-attribute-indent 4
              nxml-slash-auto-complete-flag t)
        (add-to-list 'rng-schema-locating-files
                     "~/.emacs.d/nxml-schemas/schemas.xml")
      '';
    };
  };
}
