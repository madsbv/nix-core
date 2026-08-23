;;; editor.el -*- lexical-binding: t; -*-
;;
;; Generic editing configuration: snippets and workspaces.

;; Nested snippets
(after! yasnippet
  (setopt yas-triggers-in-field t))
(map! :after yasnippet
      "C-s" #'yas-next-field)

;; Control which workspace new frames are initialized with when opened with
;; emacsclient. The default +workspaces-associate-frame-fn creates a new
;; workspace every time; with nil it opens in some existing workspace.
(setq persp-emacsclient-init-frame-behaviour-override nil)
