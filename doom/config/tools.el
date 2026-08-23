;;; tools.el -*- lexical-binding: t; -*-
;;
;; Generic tooling: pdf-tools, format-on-save, magit/forge, and lsp.

;; pdf-tools
(setopt pdf-view-resize-factor 1.1
        pdf-view-continuous nil
        pdf-view-display-size 'fit-page)
(map! :mode pdf-view-mode
      :nv "`" #'pdf-view-jump-to-register)

;; apheleia (format on save)
(setq-hook! 'web-mode-hook +format-with 'lsp)
(setq-hook! 'html-mode +format-with 'lsp)
(setq-hook! 'html-ts-mode +format-with 'lsp)

;; magit/forge
(use-package forge
  :after magit)

;; lsp general configuration
(setopt lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-enable-symbol-numbers t
        lsp-enable-semantic-highlighting t
        lsp-semantic-tokens-enable t
        lsp-ui-peek-always-show t
        lsp-ui-sideline-show-hover t
        lsp-ui-doc-enable t
        lsp-enable-symbol-highlighting t)

;; From https://github.com/emacs-lsp/lsp-mode/issues/2932
;; Attempt at fixing rust-analyzer issue where it starts erroring on every
;; action in Emacs and doesn't restart correctly.
(add-hook 'kill-buffer-hook
          (lambda ()
            (when (bound-and-true-p lsp-mode)
              (setq-default post-command-hook
                            (--filter (not (and (consp it)
                                                (eq (car it) 'closure)
                                                (not (-difference
                                                      '(cancel-callback method buf hook workspaces id)
                                                      (-map #'car (cadr it))))))
                                      (default-value 'post-command-hook))))))
