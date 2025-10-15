;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common home services unload)
  #:use-module (gnu services)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (srfi srfi-1)
  #:export (home-common-unload-service-type))

(define home-common-unload-service-type
  (service-type (name 'home-common-unload)
                (extensions
                 (list
                  (service-extension profile-service-type
                                     common-unload-service-profile)))
                (compose concatenate)
                (extend append)
                (default-value '())
                (description
                 "This service provides a simple script to unload systems by stopping configured Shepherd services.")))
