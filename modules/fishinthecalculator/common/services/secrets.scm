;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common services secrets)
  #:use-module (gnu packages base)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module ((fishinthecalculator common secrets)
                #:select (%common-secrets-dir))
  #:export (common-secrets-configuration
            common-secrets-configuration?
            common-secrets-configuration-fields
            common-secrets-configuration-directory
            common-secrets-configuration-user
            common-secrets-configuration-group

            common-secrets-service-type))

(define-configuration/no-serialization common-secrets-configuration
  (directory
   (string %common-secrets-dir)
   "Whether the secrets are stored.")
  (user
   (string)
   "The name of the user owning the secrets directory and files.")
  (group
   (string "users")
   "The name of the group owning the secrets directory and files."))

(define (common-secrets-service-activation config)
  (define user (common-secrets-configuration-user config))
  (define group (common-secrets-configuration-group config))
  (define directory (common-secrets-configuration-directory config))
  #~(begin
      (use-modules (guix build utils))
      (mkdir-p #$directory)
      (chmod #$directory #o644)
      (invoke
       (string-append #$coreutils-minimal "/bin/chown")
       "-R" #$(string-append user ":" group ) #$directory)))

(define common-secrets-service-type
  (service-type (name 'common-secrets)
                (extensions
                 (list
                  (service-extension activation-service-type
                                     common-secrets-service-activation)))
                (description
                 "This service provides a simple script to unload systems by stopping configured Shepherd services.")))
