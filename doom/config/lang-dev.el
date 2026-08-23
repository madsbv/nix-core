;;; lang-dev.el -*- lexical-binding: t; -*-
;;
;; Generic development language configuration: rust, lua, python, yaml, csv.

;; rust
(after! rustic-mode (set-formatter! 'rustfmt '("rustfmt" "--quiet" "--edition" "2024" "--emit" "stdout") :modes '(rustic-mode)))
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rustic-mode))
(setopt lsp-rust-analyzer-cargo-watch-command "clippy"
        lsp-rust-features ["all"]
        lsp-rust-all-features t
        lsp-rust-full-docs t
        lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
        lsp-rust-analyzer-display-chaining-hints t
        lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil
        lsp-rust-analyzer-display-closure-return-type-hints t
        lsp-rust-analyzer-display-parameter-hints nil
        lsp-rust-analyzer-display-reborrow-hints "never")
(appendq! +word-wrap-visual-modes '(rustic-mode))

;; lua — language server location is provided by the nix environment
(setopt lsp-clients-lua-language-server-install-dir (concat (getenv "LUA_LANGUAGE_SERVER_INSTALL_DIR") "/share/lua-language-server")
        lsp-clients-lua-language-server-main-location (concat lsp-clients-lua-language-server-install-dir "/main.lua")
        lsp-clients-lua-language-server-bin (concat lsp-clients-lua-language-server-install-dir "/bin/lua-language-server"))
(setopt lsp-clients-lua-language-server-args `("-E" ,(concat "--logpath=" (temporary-file-directory))))

;; python
(setq lsp-pyright-langserver-command "basedpyright-langserver --stdio")
(after! python
  (set-formatter! 'ruff :modes '(python-mode python-ts-mode)))

;; yaml
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode))

;; csv-mode
(add-hook! csv-mode :append '(csv-align-mode csv-header-line))
