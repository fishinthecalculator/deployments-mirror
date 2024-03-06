;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common home fishinthecalculator services seedvault-serve)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (common home fishinthecalculator packages)
  #:export (home-seedvault-serve-service-type
            seedvault-serve-shepherd-service))

(define (seedvault-serve-shepherd-service config)
  (let ((seedvault-serve (file-append fishinthecalculator-scripts "/bin/seedvault-serve")))
    (shepherd-service (provision '(seedvault-serve))
                      (respawn? #t)
                      (auto-start? #t)
                      (start #~(make-forkexec-constructor (list #$seedvault-serve)
                                                          #:log-file (string-append
                                                                      (or (getenv
                                                                           "XDG_LOG_HOME")
                                                                          (format
                                                                           #f
                                                                           "~a/.local/var/log"
                                                                           (getenv
                                                                            "HOME")))
                                                                      "/seedvault-serve.log")))
                      (stop #~(make-kill-destructor)))))

(define home-seedvault-serve-service-type
  (service-type (name 'seedvault-serve)
                (extensions (list (service-extension
                                   home-shepherd-service-type
                                   (compose list seedvault-serve-shepherd-service))))
                (default-value #f)
                (description
                 "Provides @code{seedvault-serve} Shepherd service.")))
