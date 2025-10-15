;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common services base)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu services admin)
  #:use-module (gnu services base)
  #:use-module (fishinthecalculator common channels)
  #:use-module (fishinthecalculator common services substitute)
  #:export (%common-base-services))

(define %common-base-services
  (modify-services %base-services
    (guix-service-type config =>
                       (guix-configuration (inherit config)
                                           (channels %deployments-channels)
                                           (substitute-urls
                                            %common-substitute-urls)
                                           (authorized-keys
                                            %common-authorized-keys)))))
