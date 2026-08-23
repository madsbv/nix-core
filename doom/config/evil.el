;;; evil.el -*- lexical-binding: t; -*-
;;
;; Evil-mode and clipboard configuration.

(setopt evil-cross-lines t
        evil-snipe-scope 'buffer
        evil-want-fine-undo t)
;; Disable default yank to system clipboard.
;; To use system clipboard, use + register, e.g. +dd, +cw, +y.
(setopt select-enable-clipboard nil)

(map! "s-c" #'copy-to-clipboard
      "s-v" #'paste-from-clipboard)

;; From https://emacs.stackexchange.com/questions/12122/how-to-access-os-clipboard-using-emacs-evil
(defun paste-from-clipboard ()
  (interactive)
  (setq x-select-enable-clipboard t)
  (call-interactively #'evil-paste-before-cursor-after)
  (setq x-select-enable-clipboard nil))
(defun copy-to-clipboard ()
  (interactive)
  (setq x-select-enable-clipboard t)
  (call-interactively #'evil-yank)
  (setq x-select-enable-clipboard nil))

(global-evil-matchit-mode 1)
