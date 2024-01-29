;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common secrets)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (common self))

(define-public %common-secrets-dir
  (local-file (string-append %deployments-channel-root "/secrets")
              "common-secrets-dir"
              #:recursive? #t))

(define-public sops.yaml
  (local-file (string-append %deployments-channel-root "/.sops.yaml")
              "sops.yaml"))

(define-public (secrets-file file-name)
  (file-append %common-secrets-dir "/" file-name))

;;;;;;;;;;;;;;;;;;;;
;; Common Secrets
;;;;;;;;;;;;;;;;;;;;

(define-public common.yaml
  (secrets-file "common.yaml"))
