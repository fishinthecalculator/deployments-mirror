;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system secrets)
  #:use-module (sops secrets)
  #:use-module (fishinthecalculator common secrets))

(define-public virtual_nellone.yaml
  (secrets-file "virtual_nellone.yaml"))

;; PostgreSQL

(define-public bonfire-postgres-password-secret
  (sops-secret
   (key '("postgres" "bonfire"))
   (user "postgres")
   (group "postgres")
   (file virtual_nellone.yaml)))

(define-public tandoor-postgres-password-secret
  (sops-secret
   (key '("postgres" "tandoor"))
   (file virtual_nellone.yaml)
   (user "oci-container")
   (group "postgres")
   (permissions #o440)))

;; Meilisearch

(define-public meilisearch-key-secret
  (sops-secret
   (key '("meilisearch" "master"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))

;; Bonfire

(define-public bonfire-mail-key-secret
  (sops-secret
   (key '("bonfire" "mail" "key"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))
(define-public bonfire-mail-private-key-secret
  (sops-secret
   (key '("bonfire" "mail" "private_key"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))

(define-public bonfire-secret-key-base-secret
  (sops-secret
   (key '("bonfire" "secret_key_base"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))

(define-public bonfire-signing-salt-secret
  (sops-secret
   (key '("bonfire" "signing_salt"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))

(define-public bonfire-encryption-salt-secret
  (sops-secret
   (key '("bonfire" "encryption_salt"))
   (user "oci-container")
   (group "users")
   (file virtual_nellone.yaml)
   (permissions #o400)))

;; tandoor
(define-public tandoor-secret-key-secret
  (sops-secret
   (key '("tandoor" "secret_key"))
   (file virtual_nellone.yaml)
   (user "oci-container")
   (group "postgres")
   (permissions #o440)))
