;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common self)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public %deployments-channel-root
  (string-append (current-source-directory) "/.."))

(define-public %common-scripts-dir
  (local-file (string-append %deployments-channel-root "/bin")
              "common-scripts-dir"
              #:recursive? #t))
