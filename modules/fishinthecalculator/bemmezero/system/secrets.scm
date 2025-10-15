;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator bemmezero system secrets)
  #:use-module (sops secrets)
  #:use-module (fishinthecalculator common secrets))

(define-public bemmezero.yaml
  (secrets-file "bemmezero.yaml"))

;; PostgreSQL

(define-public postgres-password-secret
  (sops-secret
   (key '("postgres" "bonfire"))
   (user "postgres")
   (group "postgres")
   (file bemmezero.yaml)))

;; Meilisearch

(define-public meilisearch-key-secret
  (sops-secret
   (key '("meilisearch" "master"))
   (file bemmezero.yaml)))

;; Bonfire

(define-public mail-key-secret
  (sops-secret
   (key '("bonfire" "mail" "key"))
   (file bemmezero.yaml)))
(define-public mail-private-key-secret
  (sops-secret
   (key '("bonfire" "mail" "private_key"))
   (file bemmezero.yaml)))

(define-public secret-key-base-secret
  (sops-secret
   (key '("bonfire" "secret_key_base"))
   (file bemmezero.yaml)))

(define-public signing-salt-secret
  (sops-secret
   (key '("bonfire" "signing_salt"))
   (file bemmezero.yaml)))

(define-public encryption-salt-secret
  (sops-secret
   (key '("bonfire" "encryption_salt"))
   (file bemmezero.yaml)))
