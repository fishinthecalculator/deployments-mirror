;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2026 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common secrets)
  #:use-module (gnu)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (sops secrets)
  #:use-module (fishinthecalculator common self)
  #:use-module (fishinthecalculator common users))

(define paul-name (user-account-name paul-user))

(define-public %common-secrets-dir
  (string-append "/home/" paul-name "/.secrets"))

(define-public (secrets-file file-name)
  (file-append
   (local-file %common-secrets-dir
               "common-secrets-dir"
               #:recursive? #t)
   "/" file-name))

;;;;;;;;;;;;;;;;;;;;
;; Common Secrets
;;;;;;;;;;;;;;;;;;;;

(define-public common.yaml
  (secrets-file "common.yaml"))

;; Restic
(define-public restic-secret
  (sops-secret
   (key '("restic"))
   (user paul-name)
   (file common.yaml)))
