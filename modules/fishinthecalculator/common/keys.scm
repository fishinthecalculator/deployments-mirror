;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common keys)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (fishinthecalculator common self))

(define-public %common-keys-dir
  (local-file (string-append %deployments-channel-root "/keys")
              "common-keys-dir"
              #:recursive? #t))

(define-public %common-guix-keys-dir
  (file-append %common-keys-dir "/guix"))

(define-public (guix-key basename)
  (file-append %common-guix-keys-dir "/" basename))

(define-public %common-ssh-keys-dir
  (file-append %common-keys-dir "/ssh"))

(define-public (ssh-key basename)
  (file-append %common-ssh-keys-dir "/" basename))

;;;;;;;;;;;;;;;;;;;;
;; Guix Keys
;;;;;;;;;;;;;;;;;;;;

(define-public guix.bordeaux.inria.fr.pub
  (guix-key "guix.bordeaux.inria.fr.pub"))

(define-public substitutes.nonguix.org.pub
  (guix-key "substitutes.nonguix.org.pub"))

(define-public pinebook-guix-key
  (guix-key "pinebook-armbian.key"))

(define-public prematurata-guix-key
  (guix-key "prematurata.pub"))

(define-public frastanato-guix-key
  (guix-key "frastanato.pub"))

;;;;;;;;;;;;;;;;;;;;
;; SSH Keys
;;;;;;;;;;;;;;;;;;;;

(define-public paul-ssh-key
  (ssh-key "id_rsa.pub"))

(define-public paul-ed25519-ssh-key
  (ssh-key "id_ed25519.pub"))

(define-public termux-ssh-key
  (ssh-key "id_termux.pub"))

(define-public gleidi-suse-ssh-key
  (ssh-key "id_ed25519_suse.pub"))
