;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common self)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public %deployments-channel-root
  (dirname (current-source-directory)))

(define-public %common-scripts-dir
  (local-file (string-append %deployments-channel-root "/bin")
              "common-scripts-dir"
              #:recursive? #t))
