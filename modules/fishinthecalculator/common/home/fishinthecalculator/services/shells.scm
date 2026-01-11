;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2022-2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common home fishinthecalculator services shells)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (small-guix home services shells))

(define %dotfiles-dir
  (local-file (string-append (current-source-directory)
                             "/etc")
              #:recursive? #t))

(define-public fishinthecalculator-bash-configuration
  (home-bash-configuration
   (guix-defaults? #t)
   (aliases '(("la" . "ls -la") ("lr" . "ls -ltr")
              ("g" . "cd ~/code/guix") ("gg" . "cd ~/code/guile")
              ("nix-update" . "nix-channel --update && nix-env -u")))
   (bash-profile
    (list
     (file-append %dotfiles-dir "/bash/bash_profile_git_branch")))
   (bashrc (list (file-append %dotfiles-dir "/bash/bashrc_tmux")
                 (file-append %dotfiles-dir "/bash/bashrc_direnv")))))

(define-public fishinthecalculator-osh-configuration
  (home-osh-configuration
   (guix-defaults? #t)
   (functions '(("la" . "ls -la") ("lr" . "ls -ltr")
                ("g" . "cd ~/code/guix") ("gg" . "cd ~/code/guile")
                ("nix-update" . "nix-channel --update && nix-env -u")))
   (oshrc (list (file-append %dotfiles-dir "/bash/bash_profile_git_branch")
                (file-append %dotfiles-dir "/bash/bashrc_tmux")
                (file-append %dotfiles-dir "/bash/bashrc_direnv")))))

(define-public fishinthecalculator-shell-profile-extensions
  ;; Order DOES matter
  (list (file-append %dotfiles-dir "/bash/bash_functions")
        (file-append %dotfiles-dir "/bash/profile_guix_foreign_distros")
        (file-append %dotfiles-dir "/bash/profile_guix_extra")
        (file-append %dotfiles-dir "/bash/profile_nix")
        (file-append %dotfiles-dir "/bash/profile_nix_foreign_distros")))

(define-public fishinthecalculator-environment
  `(("EDITOR" . "emacs")
    ("VISUAL" . "emacs")
    ("XDG_DATA_DIRS" . "${XDG_DATA_DIRS}:${HOME}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share")
    ("HISTTIMEFORMAT" . "%d/%m/%y %T ")
    ("HISTSIZE" . "100000")
    ("HISTFILESIZE" . "100000")
    ("GUIX_EXTRA_PROFILES" . "$HOME/.guix-extra-profiles")
    ("GUIX_MANIFESTS" . "$HOME/.guix-manifests")
    ("_JAVA_AWT_WM_NONREPARENTING" . "1")
    ("RED" . "\\033[0;31m")
    ("GREEN" . "\\033[1;32m")
    ("BLUE" . "\\033[1;34m")
    ("NC" . "\\033[0m")))
