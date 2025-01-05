;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common services timers)
  #:use-module (gnu packages base)  ;for findutils
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:export (updatedb-job))

;; Thanks to https://guix.gnu.org/en/manual/devel/en/guix.html#Scheduled-Job-Execution
(define-public updatedb-job
  ;; Run 'updatedb' at 23:15 every day.
  (shepherd-service (provision '(updatedb))
                    (requirement '(user-processes file-systems))
                    (documentation
                     "Run @code{updatedb} on a regular basis.")
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event "15 23 * * *")
                        (command
                         (list
                          (string-append #$findutils "/bin/updatedb")
                          "--prunepaths=/tmp /var/tmp /gnu/store /nix/store"))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation "Manually trigger a updatedb run,
without waiting for the scheduled time.")
                                    (procedure #~trigger-timer))))))
