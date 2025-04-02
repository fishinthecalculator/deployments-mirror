;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system secrets)
  #:use-module (sops secrets)
  #:use-module (fishinthecalculator common secrets))

(define-public virtual_nellone.yaml
  (secrets-file "virtual_nellone.yaml"))

;; PostgreSQL

(define-public postgres-password-secret
  (sops-secret
   (key '("postgres" "bonfire"))
   (user "postgres")
   (group "postgres")
   (file virtual_nellone.yaml)))

;; Meilisearch

(define-public meilisearch-key-secret
  (sops-secret
   (key '("meilisearch" "master"))
   (file virtual_nellone.yaml)))

;; Bonfire

(define-public mail-password-secret
  (sops-secret
   (key '("mail" "password"))
   (file virtual_nellone.yaml)))

(define-public secret-key-base-secret
  (sops-secret
   (key '("bonfire" "secret_key_base"))
   (file virtual_nellone.yaml)))

(define-public signing-salt-secret
  (sops-secret
   (key '("bonfire" "signing_salt"))
   (file virtual_nellone.yaml)))

(define-public encryption-salt-secret
  (sops-secret
   (key '("bonfire" "encryption_salt"))
   (file virtual_nellone.yaml)))

;; tandoor
(define-public tandoor-postgres-password-secret
  (sops-secret
   (key '("tandoor" "postgres_password"))
   (file virtual_nellone.yaml)))

(define-public tandoor-secret-key-secret
  (sops-secret
   (key '("tandoor" "secret_key"))
   (file virtual_nellone.yaml)))
