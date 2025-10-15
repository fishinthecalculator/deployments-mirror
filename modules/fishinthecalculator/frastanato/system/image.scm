;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator frastanato system image)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (fishinthecalculator frastanato system config))

(define-public frastanato-system-tarball
  (image-with-os docker-image frastanato-system))

frastanato-system-tarball
