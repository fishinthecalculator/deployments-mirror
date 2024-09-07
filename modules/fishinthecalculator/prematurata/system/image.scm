;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator prematurata system image)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (fishinthecalculator prematurata system config))

(define-public prematurata-system-tarball
  (os->image prematurata-system #:type docker-image-type))

prematurata-system-tarball
