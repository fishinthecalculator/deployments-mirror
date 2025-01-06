;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator frastanato secrets)
  #:use-module (gnu)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (sops secrets)
  #:use-module (fishinthecalculator common self)
  #:use-module (fishinthecalculator common secrets))

;;;;;;;;;;;;;;;;;;;;
;; frastanato secrets
;;;;;;;;;;;;;;;;;;;;

(define-public frastanato.yaml
  (secrets-file "frastanato.yaml"))

;; wireguard
(define-public wireguard-secret
  (sops-secret
   (key '("wireguard" "private"))
   (file frastanato.yaml)))
