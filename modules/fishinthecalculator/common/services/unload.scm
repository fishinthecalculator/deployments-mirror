;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common services unload)
  #:use-module (gnu packages bash)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix packages)
  #:use-module (ice-9 format)
  #:use-module (srfi srfi-1)
  #:export (common-unload-service-profile
            common-unload-service-type))

(define (unload-script services-names)
  (program-file "unload-script"
    #~(let ((bash (string-append #$bash-minimal "/bin/bash")))
        (execlp bash bash "-c"
                #$(format #f
                          "set -euo pipefail

status=$(herd status)

test_and_stop () {
    if printf '%s' \"$status\" | grep -q \"+ $1\"; then
        printf '%s' \"Stopping ${1}... \"
        herd stop \"$1\"
        echo \"Done!\"
    else
        echo \"$1 is already stopped.\"
    fi
}

declare -a services=(~a)

for s in \"${services[@]}\"; do
    test_and_stop \"$s\"
done" (string-join (map (lambda (n) (format #f "\"~a\"" n)) services-names) " "))))))

(define (unload-wrapper-package services-names)
  (package
    (name "unload-service-wrapper")
    (version "0.0.0")
    (source (unload-script services-names))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan #~'(("./" "/bin"))))
    (home-page "https://codeberg.org/fishinthecalculator/guix-deployments/src/branch/main/modules/fishinthecalculator/common/services/unload.scm")
    (synopsis
     "Stop heavy Shepherd services")
    (description
     "This package provides a simple script to unload systems by stopping configured Shepherd services.")
    (license license:gpl3+)))

(define common-unload-service-profile
  (lambda (names)
    (if (> (length names) 0)
        (list
         (unload-wrapper-package names))
        '())))

(define common-unload-service-type
  (service-type (name 'common-unload)
                (extensions
                 (list
                  (service-extension profile-service-type
                                     common-unload-service-profile)))
                (compose concatenate)
                (extend append)
                (default-value '())
                (description
                 "This service provides a simple script to unload systems by stopping configured Shepherd services.")))
