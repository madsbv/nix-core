;;; emacs.el -*- lexical-binding: t; -*-
;;
;; Generic Emacs internals: GC tuning, server, and modifier rebindings.

(setopt gcmh-idle-delay 'auto
        gcmh-low-cons-threshold (* 800 1000)        ;; Default value 800000
        gcmh-high-cons-threshold (* 33 1024 1024))  ;; Default value 33554432

;; From https://www.reddit.com/r/emacs/comments/14c4l8j/way_to_make_emacs_feel_smoother/
(setopt jit-lock-stealth-time 1.25)
(setopt jit-lock-chunk-size 2048)

(server-start)

(map! "s-%" #'query-replace
      "C-s-%" #'query-replace-regexp)
