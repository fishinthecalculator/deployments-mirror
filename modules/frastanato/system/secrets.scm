;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (frastanato system secrets)
  #:use-module (sops secrets)
  #:use-module (common secrets))

(define-public frastanato.yaml
  (secrets-file "frastanato.yaml"))

;; PostgreSQL

(define-public postgres-password-secret
  (sops-secret
   (key '("postgres" "bonfire"))
   (user "postgres")
   (group "postgres")
   (file frastanato.yaml)))

;; Bonfire

(define-public mail-password
  (sops-secret
   (key '("smtp" "password"))
   (file frastanato.yaml)))

(define-public secret-key-base
  (sops-secret
   (key '("bonfire" "secret_key_base"))
   (file frastanato.yaml)))

(define-public signing-salt
  (sops-secret
   (key '("bonfire" "signing_salt"))
   (file frastanato.yaml)))

(define-public encryption-salt
  (sops-secret
   (key '("bonfire" "encryption_salt"))
   (file frastanato.yaml)))
