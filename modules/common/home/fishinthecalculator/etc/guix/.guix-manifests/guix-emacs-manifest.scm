(use-modules (guix git-download)
             (guix packages)
             (gnu packages emacs-xyz))

(define-public emacs-extempore-mode-latest
  (let ((version (package-version emacs-extempore-mode))
        (revision "0")
        (commit "eb2dee8860f3d761e949d7c2ee8e2e469ac1cf51"))
    (package
      (inherit emacs-extempore-mode)
      (version (git-version version revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url
                       "https://github.com/extemporelang/extempore-emacs-mode")
                      (commit commit)))
                (file-name (git-file-name (package-name emacs-extempore-mode)
                                          version))
                (sha256
                 (base32
                  "0ivb3c00jlqblzjxw36z3nmqqvv2djyzk69yhlzjw2nl2r2xmhnd")))))))

(use-modules (guix build-system emacs))
(define-public emacs-just-mode
  (package
    (name "emacs-just-mode")
    (version "20230303.2255")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/leon-barrett/just-mode.el.git")
             (commit "d7f52eab8fa3828106f80acb1e2176e5877b7191")))
       (sha256
        (base32 "103jwkmg3dphmr885rpbxjp3x8xw45c0zbcvwarkv4bjhph8y4vh"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/leon-barrett/just-mode.el")
    (synopsis "Justfile editing mode")
    (description
     "This package provides a major mode for editing justfiles, as defined by the tool
\"just\": https://github.com/casey/just")
    (license #f)))

(packages->manifest (append (list emacs-extempore-mode-latest
                                  emacs-just-mode)
                            (map specification->package+output
                                 '("texinfo" "man-db"
                                   "editorconfig-core-c"
                                   "emacs-next-pgtk"
                                   "emacs-debbugs"
                                   "emacs-flycheck-guile"
                                   "emacs-guix"
                                   "emacs-geiser"
                                   "emacs-geiser-guile"
                                   "emacs-irony-mode-server"
                                   "emacs-macrostep"
                                   ;; "emacs-macrostep-geiser"
                                   "emacs-org-ref"
                                   "emacs-projectile"
                                   "emacs-treemacs"
                                   "emacs-undo-tree"
                                   "emacs-wisp-mode"
				   "elixir-credo"
                                   "fd"
                                   "glib"
                                   "jq"
                                   "hunspell"
                                   "markdown"
                                   "parinfer-rust"
                                   ;; Required by magit.
                                   "perl"
                                   "python-black"
                                   "python-isort"
                                   "python-jsbeautifier"
                                   "python-lsp-server"
                                   "python-nose"
                                   "shellcheck"
                                   "texlive-bin"
                                   "texlive-scheme-basic"
                                   "tidy-html"
                                   "wordnet"))))
