;;; packages.el -*- lexical-binding: t; -*-
;;
;; Core (shared) Doom packages. Leaf `package!` additions live in
;; packages-extra.el, copied alongside and loaded via the trailer below.

(package! just-mode)
;; Use existing pdf-tools if available, otherwise install.
;; Needed to make pdf-tools from nixpkgs work.
(package! pdf-tools :built-in 'prefer)
(package! evil-matchit)
(package! org-gtd)
(package! powershell)

;; --- Leaf overlay -----------------------------------------------------------

(load! "packages-extra" (doom-user-dir))
