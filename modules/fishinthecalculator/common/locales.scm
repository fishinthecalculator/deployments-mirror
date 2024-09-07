;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2022, 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common locales)
  #:use-module (gnu packages base))

(define-public common-glibc-locales
  (make-glibc-utf8-locales glibc
                           #:locales (list "en_US" "en_GB" "it_IT" "fr_FR"
                                           "de_DE")
                           #:name "common-glibc-utf8-locales"))
