# Visual and window management configuration
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    base16-theme = {
      enable = true;
      config = "(load-theme 'base16-tomorrow-night t)";
    };

    beacon = {
      enable = true;
      command = ["beacon-mode"];
      diminish = ["beacon-mode"];
      defer = 1;
      config = "(beacon-mode 1)";
    };

    nyan-mode = {
      enable = true;
      command = ["nyan-mode"];
      config = ''
        (setq nyan-wavy-trail t)
      '';
    };

    # Enable winner mode - undo/redo changes to window configuration
    # Uses C-c <left> and C-c <right>
    winner = {
      enable = true;
      config = "(winner-mode 1)";
    };

    writeroom-mode = {
      enable = true;
      command = ["writeroom-mode"];
      bind = {
        "M-[" = "writeroom-decrease-width";
        "M-]" = "writeroom-increase-width";
      };
      hook = ["(writeroom-mode . visual-line-mode)"];
    };

    buffer-move = {
      enable = true;
      bind = {
        "C-S-<up>" = "buf-move-up";
        "C-S-<down>" = "buf-move-down";
        "C-S-<left>" = "buf-move-left";
        "C-S-<right>" = "buf-move-right";
      };
    };

    ace-window = {
      enable = true;
      extraConfig = ''
        :bind* (("C-c w" . ace-window)
                ("M-o" . ace-window))
      '';
    };

    which-key = {
      enable = true;
      command = ["which-key-mode"];
      diminish = ["which-key-mode"];
      defer = 2;
      config = "(which-key-mode)";
    };

    back-button = {
      enable = true;
      defer = 1;
      diminish = ["back-button-mode"];
      command = ["back-button-mode"];
      config = ''
        (back-button-mode 1)

        ;; Make mark ring larger.
        (setq global-mark-ring-max 50)
      '';
    };

    transpose-frame = {
      enable = true;
      bind = {
        "C-c f t" = "transpose-frame";
      };
    };

    fill-column-indicator = {
      enable = true;
      command = ["fci-mode"];
      defer = 1;
    };
  };
}
