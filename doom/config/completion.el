;;; completion.el -*- lexical-binding: t; -*-
;;
;; Company and vertico/consult configuration.

(map! :after company
      :map company-active-map
      "C-l" #'company-complete-common-or-cycle
      "<tab>" nil
      "<backtab>" nil
      "TAB" nil
      "RET" nil
      "<return>" nil
      "C-<return>" #'company-complete-selection)
(setopt company-idle-delay 0.4)

(setopt consult-locate-args "locate -i"
        vertico-posframe-poshandler 'posframe-poshandler-frame-top-center
        vertico-posframe-truncate-lines t
        vertico-posframe-parameters
        '((left-fringe . 8)
          (right-fringe . 8)))

;; Just to make it easier to find by searching
(defun mbv/posframe-cleanup ()
  (interactive)
  (vertico-posframe-cleanup))
