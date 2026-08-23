;;; lang-org.el -*- lexical-binding: t; -*-
;;
;; Generic org-mode configuration: org-noter, org-roam, org-gtd, deft, and
;; org-id. Concrete paths (`org-directory`, `org-roam-directory`,
;; `org-gtd-directory`, `deft-directory`, `org-noter-notes-search-path`) and
;; mu4e-specific org-gtd helpers live in the leaf's config-extra/.

;; org-noter
(after! org-mode
  (setopt org-noter-hide-other nil))
(map! :map org-noter-doc-mode-map
      "M-i" #'org-noter-insert-note
      "C-M-i" #'org-noter-insert-precise-note)

;; org — generic buffer/window behavior
(after! org
  (setopt org-src-window-setup 'split-window-below
          org-refile-allow-creating-parent-nodes 'confirm
          org-return-follows-link t
          org-tags-column -100))

;; org-id — consistent links across headline moves
(after! org
  (require 'org-id)
  ;; Always use ID's, create if doesn't exist
  (setq org-id-link-to-org-use-id t)
  ;; Make the default explicit
  (setq org-id-track-globally t)
  (setq org-id-locations-file (concat user-emacs-directory ".org-id-locations"))
  ;; Update id locations on startup
  (org-id-update-id-locations nil t)
  ;; Completion function for id's when running org-insert-link.
  (defun org-id-complete-link (&optional arg)
    "Create an id: link using completion"
    (concat "id:"
            (org-id-get-with-outline-path-completion)))
  (org-link-set-parameters "id" :complete 'org-id-complete-link))

;; org-roam — generic behavior (directory set in leaf). Deferred so the leaf's
;; org-roam-directory value is applied before autosync runs.
(use-package! org-roam
  :defer t
  :config
  (org-roam-db-autosync-mode)
  (require 'org-roam-protocol))

;; org-gtd — generic setup; mu4e helpers and the gtd directory live in the leaf
(use-package! org-gtd
  :after org
  :init
  (setq org-gtd-update-ack "4.0.0")
  :config
  (setq org-edna-use-inheritance t)
  (org-edna-mode)
  (setopt org-gtd-engage-prefix-width 25
          org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAIT(w)" "|" "DONE(d)" "CNCL(c)")))
  (setopt org-gtd-keyword-mapping
          '((todo . "TODO")
            (next . "NEXT")
            (wait . "WAIT")
            (done . "DONE")
            (canceled . "CNCL")))
  (map! :leader
        (:prefix ("d" . "org-gtd")
         :desc "Add to inbox"   "i"  #'org-gtd-capture
         :desc "Clarify"        "c"  #'org-gtd-clarify-item
         :desc "Engage"         "e"  #'org-gtd-engage
         :desc "Process inbox"  "p"  #'org-gtd-process-inbox
         :desc "Show all next"  "n"  #'org-gtd-show-all-next
         :desc "Stuck projects" "s"  #'org-gtd-review-stuck-projects
         :desc "Organize this item" "o" #'org-gtd-organize)
        (:prefix ("d a" . "org-gtd-agenda")
         :desc "Clarify task from agenda" "c" #'org-gtd-clarify-agenda-item
         :desc "Delegate task from agenda" "d" #'org-gtd-delegate-agenda-item)))

;; deft — generic behavior (directory set in leaf)
(after! deft
  (setopt deft-recursive t
          deft-use-filter-string-for-filename t
          deft-default-extension "org")
  (defun cm/deft-parse-title (file contents)
    "Parse the given FILE and CONTENTS and determine the title.
If `deft-use-filename-as-title' is nil, the title is taken to
be the first non-empty line of the FILE.  Else the base name of the FILE is
used as title."
    (let ((begin (string-match "^#\\+[tT][iI][tT][lL][eE]: .*$" contents)))
      (if begin
          (string-trim (substring contents begin (match-end 0)) "#\\+[tT][iI][tT][lL][eE]: *" "[\n\t ]+")
        (deft-base-filename file))))
  (advice-add 'deft-parse-title :override #'cm/deft-parse-title)
  (setq deft-strip-summary-regexp
        (concat "\\("
                "[\n\t]" ;; blank
                "\\|^#\\+[[:alpha:]_]+:.*$" ;; org-mode metadata
                "\\|^:PROPERTIES:\n\\(.+\n\\)+:END:\n"
                "\\)")))
