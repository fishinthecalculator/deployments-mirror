;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (nellone system secrets)
  #:use-module (sops secrets)
  #:use-module (common secrets))

(define-public nellone.yaml
  (secrets-file "nellone.yaml"))

;; PostgreSQL

(define-public postgres-password-secret
  (sops-secret
   (key '("postgres" "bonfire"))
   (user "postgres")
   (group "postgres")
   (file nellone.yaml)))

;; Meilisearch

(define-public meilisearch-key-secret
  (sops-secret
   (key '("meilisearch" "master"))
   (file nellone.yaml)))

;; Bonfire

(define-public mail-password-secret
  (sops-secret
   (key '("smtp" "password"))
   (file nellone.yaml)))

(define-public secret-key-base-secret
  (sops-secret
   (key '("bonfire" "secret_key_base"))
   (file nellone.yaml)))

(define-public signing-salt-secret
  (sops-secret
   (key '("bonfire" "signing_salt"))
   (file nellone.yaml)))

(define-public encryption-salt-secret
  (sops-secret
   (key '("bonfire" "encryption_salt"))
   (file nellone.yaml)))
