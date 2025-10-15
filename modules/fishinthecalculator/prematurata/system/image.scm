;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator prematurata system image)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (fishinthecalculator prematurata system config))

(define-public prematurata-system-tarball
  (image-with-os docker-image prematurata-system))

prematurata-system-tarball
