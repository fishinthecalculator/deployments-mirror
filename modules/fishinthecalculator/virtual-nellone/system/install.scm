;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system install)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services ssh)
  #:use-module (gnu system)
  #:use-module (gnu system accounts)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator virtual-nellone system config))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      (,paul ,paul-ed25519-ssh-key))))

(define-public virtual-nellone-stage0
  (operating-system
    (inherit virtual-nellone-system)
    (services
     (modify-services virtual-nellone-common-server-services
       (openssh-service-type ssh-config =>
                             (openssh-configuration (inherit ssh-config)
                                                    (authorized-keys
                                                     (append
                                                      (openssh-configuration-authorized-keys ssh-config)
                                                      authorized-ssh-keys))))))))
