(define-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu services admin)
  #:use-module (fishinthecalculator common channels)
  #:use-module (ice-9 format)
  #:export (deployments-unattended-upgrades))

(define* (deployments-unattended-upgrades host-name #:key (expiration-days 7) (channels %unattended-upgrades-channels) (hours 23) (minutes 10))
  (let ((host-name-symbol
         (string->symbol host-name)))
    (service unattended-upgrade-service-type
             (unattended-upgrade-configuration
              (schedule (format #f "~a ~a * * *" minutes hours))
              (system-expiration
               (* expiration-days 24 3600))
              (channels channels)
              (operating-system-expression
               #~(@ (#$host-name-symbol system config)
                    #$(symbol-append host-name-symbol '-system)))))))
