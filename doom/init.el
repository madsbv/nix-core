;;; init.el -*- lexical-binding: t; -*-
;;
;; Core (shared) Doom Emacs module manifest. This file is the base of the
;; store-built `$DOOMDIR`; a leaf's `init-extra.el` is appended to it by
;; core.lib.mkDoomdir (two `doom!` blocks are idempotent — the last declaration
;; of a module wins).
;;
;; Keep this to modules that are generic across every machine. Personal/leaf
;; modules (mu4e, biblio, extra langs like latex/fortran) belong in the leaf's
;; init-extra.el.

;; Must be set before loading evil.
(setopt evil-respect-visual-line-mode t)

(setenv "LSP_USE_PLISTS" "true")

(doom! :input

       :completion
       (company +childframe)        ; the ultimate code completion backend
       (vertico +childframe +icons) ; the search engine of the future

       :ui
       deft                         ; notational velocity for Emacs
       doom                         ; what makes DOOM look the way it does
       dashboard                    ; a nifty splash screen for Emacs
       doom-quit                    ; DOOM quit-message prompts when you quit Emacs
       hl-todo                      ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       indent-guides                ; highlighted indent columns
       modeline                     ; snazzy, Atom-inspired modeline, plus API
       nav-flash                    ; blink cursor line after big motions
       ophints                      ; highlight the region an operation acts on
       (popup +defaults)            ; tame sudden yet inevitable temporary windows
       (treemacs +lsp)              ; a project drawer, like neotree but cooler
       unicode                      ; extended unicode support for various languages
       (vc-gutter +pretty)          ; vcs diff in the fringe
       window-select                ; visually switch windows
       workspaces                   ; tab emulation, persistence & separate workspaces
       zen                          ; distraction-free coding or writing

       :editor
       (evil +everywhere)           ; come to the dark side, we have cookies
       file-templates               ; auto-snippets for empty files
       fold                         ; (nigh) universal code folding
       (format +onsave)             ; automated prettiness
       multiple-cursors             ; editing in many places at once
       snippets                     ; my elves. They type so I don't have to
       word-wrap                    ; soft wrapping with language-aware indent

       :emacs
       (dired +icons)               ; making dired pretty
       electric                     ; smarter, keyword-based electric-indent
       (ibuffer +icons)             ; interactive buffer management
       (undo +tree)                 ; persistent, smarter undo
       vc                           ; version-control and Emacs, sitting in a tree

       :term
       vterm                        ; the best terminal emulation in Emacs

       :checkers
       (syntax +flymake)            ; tasing you for every semicolon you forget
       (spell +aspell +everywhere)  ; tasing you for misspelling mispelling
       grammar                      ; tasing grammar mistake every you make

       :tools
       direnv
       editorconfig                 ; let someone else argue about tabs vs spaces
       (eval +overlay)              ; run code, run (also, repls)
       (lookup +dictionary +docsets) ; navigate your code and its documentation
       (lsp +peek)                  ; M-x vscode
       (magit +forge)               ; a git porcelain for Emacs
       make                         ; run make tasks from Emacs
       pdf                          ; pdf enhancements
       tree-sitter                  ; syntax and parsing, sitting in a tree...

       :os
       (:if IS-MAC macos)           ; improve compatibility with macOS
       tty                          ; improve the terminal Emacs experience

       :lang
       data                         ; config/data formats
       emacs-lisp                   ; drown in parentheses
       (go +lsp +tree-sitter)       ; the hipster dialect
       (java +lsp +tree-sitter)     ; the poster child for carpal tunnel syndrome
       (javascript +tree-sitter +lsp) ; all(hope(abandon(ye(who(enter(here))))))
       (json +lsp +tree-sitter)     ; At least it ain't XML
       (lua +lsp +tree-sitter)      ; one-based indices? one-based indices
       (markdown +grip +tree-sitter) ; writing docs for people to ignore
       (nix +lsp +tree-sitter)      ; I hereby declare "nix geht mehr!"
       (org +dragndrop +noter +roam) ; organize your plain life in plain text
       (python +tree-sitter +lsp +cython +uv +poetry) ; beautiful is better than ugly
       (rest +jq)                   ; Emacs as a REST client
       (rust +lsp +tree-sitter)     ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       (sh +tree-sitter)            ; she sells {ba,z,fi}sh shells on the C xor
       (web +lsp +tree-sitter)      ; the tubes
       (yaml +lsp)                  ; JSON, but readable

       :email

       :app

       :config
       (default +bindings +smartparens))
