;;; ui.el -*- lexical-binding: t; -*-
;;
;; Generic UI configuration (shared across every machine).

;; Fleet color scheme (molokai) is the default in core's color-scheme module.
(setopt doom-molokai-brighter-comments t
        doom-molokai-brighter-modeline t
        doom-theme 'doom-molokai)

;; enable word-wrap (almost) everywhere
(+global-word-wrap-mode +1)

(setq display-line-numbers-type 'visual)

(setopt uniquify-buffer-name-style 'post-forward-angle-brackets)

(menu-bar-mode -1)

(setopt diff-hl-update-async nil)
