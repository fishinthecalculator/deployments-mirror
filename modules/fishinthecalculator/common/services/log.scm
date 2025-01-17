;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <goodoldpaul@autistici.org>

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

(define %common-log-services
  (list (service system-log-service-type)))
