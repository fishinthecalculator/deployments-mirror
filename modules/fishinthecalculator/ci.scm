;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator ci)
  #:use-module (gnu ci)
  #:use-module (gnu system image)
  #:use-module (frastanato system image)
  #:use-module (srfi srfi-1)
  #:export (cuirass-jobs))

(define (cuirass-jobs store arguments)
  (define systems
    (arguments->systems arguments))

  (append-map
   (lambda (system)
     (list
      (image->job store
                  (image-with-os docker-image
                                 frastanato-system)
                  #:name "frastanato-system-tarball"
                  #:system system)))
   systems))
