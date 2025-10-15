;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator bemmezero system install)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services ssh)
  #:use-module (gnu system)
  #:use-module (gnu system accounts)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator bemmezero system config))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      (,paul ,paul-ed25519-ssh-key))))

(define-public bemmezero-stage0
  (operating-system
    (inherit bemmezero-system)
    (groups (cons* (user-group (name "docker") (system? #t))
                   %base-groups))
    (services
     (modify-services bemmezero-common-server-services
       (openssh-service-type ssh-config =>
                             (openssh-configuration (inherit ssh-config)
                                                    (authorized-keys
                                                     (append
                                                      (openssh-configuration-authorized-keys ssh-config)
                                                      authorized-ssh-keys))))))))
