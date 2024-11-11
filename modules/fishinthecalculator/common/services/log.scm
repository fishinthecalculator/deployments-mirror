;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common services log)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:export (%common-log-services))

(define system-log-service-type
  (shepherd-service-type
   'shepherd-system-log
   (const (shepherd-service
           (documentation "Shepherd's built-in system log (syslogd).")
           (provision '(system-log syslogd))
           (modules '((shepherd service system-log)))
           (free-form #~(system-log-service))))
   #t
   (description
    "Shepherd's built-in system log (syslogd).")))

(define log-rotation-service
  (simple-service 'shepherd-log-rotation
                  shepherd-root-service-type
                  (list (shepherd-service
                         (provision '(log-rotation))
                         (modules '((shepherd service log-rotation)))
                         (free-form #~(log-rotation-service))))))


(define %common-log-services
  (list log-rotation-service
        (service system-log-service-type)))
