(define-module (common services unattended-upgrades)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu services admin)
  #:use-module (ice-9 format)
  #:export (deployments-unattended-upgrades))

(define %unattended-upgrades-channels
  #~(cons* (channel
            (name 'deployments)
            (url "https://gitlab.com/orang3/guix-deployments.git")
            (branch "main")
            ;; Enable signature verification:
            (introduction
             (make-channel-introduction
              "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
              (openpgp-fingerprint
               "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
           (channel
            (name 'small-guix)
            (url "https://gitlab.com/orang3/small-guix")
            ;; Enable signature verification:
            (introduction
             (make-channel-introduction
              "f260da13666cd41ae3202270784e61e062a3999c"
              (openpgp-fingerprint
               "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
           (channel
            (name 'nonguix)
            (url "https://gitlab.com/nonguix/nonguix")
            ;; Enable signature verification:
            (introduction
             (make-channel-introduction
              "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
              (openpgp-fingerprint
               "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
           %default-channels))

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
