;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Giacomo Leidi"
      user-mail-address "goodoldpaul@autistici.org")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Fira Code" :size 14 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 15))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! org
 (with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes '("letter" "\\documentclass{letter}"))))

(setq
 projectile-project-search-path '("~/code/"))

(add-load-path! "~/.guix-extra-profiles/emacs/share/emacs/site-lisp/")

(add-hook 'scheme-mode-hook 'guix-devel-mode)

;; Delete files by moving them to trash.
(setq-default delete-by-moving-to-trash t
              trash-directory nil) ;; Use freedesktop.org trashcan

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Split Defaults ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Split horizontally to right, vertically below the current window.
(setq evil-vsplit-window-right t
      evil-split-window-below t)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Editing ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Stretch cursor to the glyph width
(setq-default x-stretch-cursor t)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Save recent files ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; When editing files with Emacs client, the files does not get stored by
;; recentf, making Emacs forgets about recently opened files. A quick fix
;; is to hook the recentf-save-list command to the delete-frame-functions
;; and delete-terminal-functions which gets executed each time a
;; frame/terminal is deleted.

(when (daemonp)
  (add-hook! '(delete-frame-functions delete-terminal-functions)
    (let ((inhibit-message t))
      (recentf-save-list)
      (savehist-save))))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Modeline ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Display time and set the format to 24h.
(after! doom-modeline
  (setq display-time-string-forms
        '((propertize (concat " 🕘 " 24-hours ":" minutes))))
  (display-time-mode 1) ; Enable time in the mode-line

  ;; Add padding to the right
  (doom-modeline-def-modeline 'main
   '(bar workspace-name window-number modals matches follow buffer-info remote-host buffer-position word-count parrot selection-info)
   '(objed-state misc-info persp-name battery grip irc mu4e gnus github debug repl lsp minor-modes input-method indent-info buffer-encoding major-mode process vcs checker "   ")))

;; Assuming the Guix checkout is in ~/code/guix.
;; Yasnippet configuration
(with-eval-after-load 'yasnippet
  (add-to-list 'yas-snippet-dirs (format "%s/etc/snippet/yas" (getenv "GUIX_CHECKOUT"))))
;; Copyright configuration
(load-file (format "%s/etc/copyright.el" (getenv "GUIX_CHECKOUT")))
(setq copyright-names-regexp
      (format "%s <%s>" user-full-name user-mail-address))
;;; Bug references.
(add-hook 'prog-mode-hook #'bug-reference-prog-mode)
(add-hook 'gnus-mode-hook #'bug-reference-mode)
(add-hook 'erc-mode-hook #'bug-reference-mode)
(add-hook 'bug-reference-mode-hook 'debbugs-browse-mode)
(add-hook 'bug-reference-prog-mode-hook 'debbugs-browse-mode)
(add-hook 'gnus-summary-mode-hook 'bug-reference-mode)
(add-hook 'gnus-article-mode-hook 'bug-reference-mode)

;;; This extends the default expression (the top-most, first expression
;;; provided to 'or') to also match URLs such as
;;; <https://issues.guix.gnu.org/58697> or <https://bugs.gnu.org/58697>.
;;; It is also extended to detect "Fixes: #NNNNN" git trailers.
(setq bug-reference-bug-regexp
      (rx (group (or (seq word-boundary
                          (or (seq (char "Bb") "ug"
                                   (zero-or-one " ")
                                   (zero-or-one "#"))
                              (seq (char "Pp") "atch"
                                   (zero-or-one " ")
                                   "#")
                              (seq (char "Ff") "ixes"
                                   (zero-or-one ":")
                                   (zero-or-one " ") "#")
                              (seq "RFE"
                                   (zero-or-one " ") "#")
                              (seq "PR "
                                   (one-or-more (char "a-z+-")) "/"))
                          (group (one-or-more (char "0-9"))
                                 (zero-or-one
                                  (seq "#" (one-or-more
                                            (char "0-9"))))))
                     (seq "<https://bugs.gnu.org/"
                          (group-n 2 (one-or-more (char "0-9")))
                          ">")))))

;; The following allows Emacs Debbugs user to open the issue directly within
;; Emacs.
(setq debbugs-browse-url-regexp
      (rx line-start
          "http" (zero-or-one "s") "://"
          (or "debbugs" "issues.guix" "bugs")
          ".gnu.org" (one-or-more "/")
          (group (zero-or-one "cgi/bugreport.cgi?bug="))
          (group-n 3 (one-or-more digit))
          line-end))
