;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common system input)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:export (common-kl
            common-hid-apple-config))

(define common-kl
  (keyboard-layout "us"))

(define common-hid-apple-config
  (plain-file "hid_apple.conf"
              "options hid_apple fnmode=2 swap_opt_cmd=1"))
