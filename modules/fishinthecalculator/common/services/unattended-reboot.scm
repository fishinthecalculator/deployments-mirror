;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common services unattended-reboot)
  #:use-module (guix gexp)
  #:use-module (guix modules)
  #:export (common-unattended-reboot-script))

(define (common-unattended-reboot-script services)
 (with-imported-modules (source-module-closure '((gnu services herd)))
   (program-file "stop-services"
    #~(begin
        (use-modules (gnu services herd)
                     (ice-9 format))
        (let ((services (list #$@services)))
          (for-each
           (lambda (service)
             (format (current-error-port) "Stopping ~a~%" service)
             (stop-service service))
           services))))))
