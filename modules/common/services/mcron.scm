;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common services mcron)
  #:use-module (gnu packages base)  ;for findutils
  #:use-module (guix gexp)
  #:export (updatedb-job))

;; Thanks to https://guix.gnu.org/en/manual/devel/en/guix.html#Scheduled-Job-Execution
(define-public updatedb-job
  ;; Run 'updatedb' at 23:15 every day.
  #~(job "15 23 * * *"
         (lambda ()
           (system* (string-append #$findutils "/bin/updatedb")
                    "--prunepaths=/tmp /var/tmp /gnu/store /nix/store"))
         "updatedb"))
