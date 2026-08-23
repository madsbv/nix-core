;;; config.el -*- lexical-binding: t; -*-
;;
;; Core (shared) Doom Emacs configuration. This tree is composed with a leaf's
;; `doom/` overlay into a read-only store-built `$DOOMDIR` (see PLAN.md:
;; "Doomemacs — Option 3"). The store path is read-only, so anything Emacs would
;; normally write at runtime is redirected below to XDG state.
;;
;; Actual configuration lives in the `config/` fragments below, loaded in order.
;; The leaf's `config-extra.el` is loaded last, so leaf settings override core.

;; --- Runtime writes → XDG (read-only DOOMDIR) -------------------------------

;; Customize writes (M-x customize) must not touch the read-only store path.
(setq custom-file (concat (or (getenv "XDG_STATE_HOME")
                              (concat (getenv "HOME") "/.local/state"))
                          "/doom/custom.el"))
;; Doom already defaults `custom-theme-directory` under XDG; make it explicit so
;; theme installs never write into the store path.
(setq custom-theme-directory (concat (or (getenv "XDG_STATE_HOME")
                                         (concat (getenv "HOME") "/.local/state"))
                                     "/doom/themes/"))

;; --- Core config fragments --------------------------------------------------

(load! "config/ui")
(load! "config/evil")
(load! "config/completion")
(load! "config/editor")
(load! "config/emacs")
(load! "config/tools")
(load! "config/lang-org")
(load! "config/lang-dev")

;; --- Leaf overlay -----------------------------------------------------------

;; The leaf fragment is copied alongside this file by core.lib.mkDoomdir and
;; loaded last, so leaf settings override core's.
(load! "config-extra" (doom-user-dir))
