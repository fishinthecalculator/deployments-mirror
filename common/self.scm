;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2022 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common self)
  #:use-module (guix utils)
  #:use-module (guix gexp))

(define-public %common-scripts-dir
  (local-file (string-append (current-source-directory) "/../bin")
              "common-scripts-dir"
              #:recursive? #t))
