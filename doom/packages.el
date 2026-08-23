;;; packages.el -*- lexical-binding: t; -*-
;;
;; Core (shared) Doom packages. Leaf `package!` additions live in
;; packages-extra.el, copied alongside and loaded via the trailer below.

;; (package! some-shared-package)

;; --- Leaf overlay -----------------------------------------------------------

(load! "packages-extra" (doom-user-dir))
