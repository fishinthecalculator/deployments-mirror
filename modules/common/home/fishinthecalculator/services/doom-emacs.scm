;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common home fishinthecalculator services doom-emacs)
  #:use-module (gnu packages version-control)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (home-doom-emacs-service-type
            home-doom-emacs-activation
            home-doom-emacs-shepherd-service))

;; Strongly inspired from
;; https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix

(define (home-doom-emacs-shepherd-service config)
  (let ((entrypoint (string-append (getenv "HOME") "/.guix-extra-profiles/emacs/bin/emacs")))
    (shepherd-service (provision '(doom-emacs))
                      (respawn? #t)
                      (auto-start? #t)
                      (start #~(make-forkexec-constructor (list #$entrypoint "--daemon")
                                                          #:log-file (string-append
                                                                      (or (getenv
                                                                           "XDG_LOG_HOME")
                                                                          (format
                                                                           #f
                                                                           "~a/.local/var/log"
                                                                           (getenv
                                                                            "HOME")))
                                                                      "/doom-emacs-daemon.log")))
                      (stop
                       #~(lambda _
                           (invoke (string-append (getenv "HOME") "/.guix-extra-profiles/emacs/bin/emacsclient")
                                   "--eval" "\"(kill-emacs)\""))))))

(define home-doom-emacs-activation
  (lambda args
    #~(let ((config-home
             (string-append (or (getenv "XDG_CONFIG_HOME")
                                (string-append (getenv "HOME") "/.config"))
                            "/emacs"))
            (git #$(file-append git-minimal "/bin/git")))
        (unless (file-exists? config-home)
          (system* git "clone" "--depth=1" "--single-branch" "https://github.com/doomemacs/doomemacs" config-home)))))

(define home-doom-emacs-service-type
  (service-type (name 'doom-emacs)
                (extensions (list (service-extension
                                   home-activation-service-type
                                   home-doom-emacs-activation)
                                  (service-extension
                                   home-shepherd-service-type
                                   (compose list home-doom-emacs-shepherd-service))))
                (default-value #f)
                (description
                 "Provides @code{doom-emacs} Shepherd service.")))
