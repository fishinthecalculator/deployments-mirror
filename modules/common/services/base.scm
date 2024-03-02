;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common services base)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu services base)
  #:use-module (common services substitute)
  #:export (%common-base-services))

(define %common-base-services
  (modify-services %base-services
    (guix-service-type config =>
                       (guix-configuration (inherit config)
                                           (substitute-urls
                                            %common-substitute-urls)
                                           (authorized-keys
                                            %common-authorized-keys)))))
