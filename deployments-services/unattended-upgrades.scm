(define-module (deployments-services unattended-upgrades)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:use-module (small-guix services unattended-upgrades)
  #:export (deployments-unattended-upgrades))

(define %unattended-upgrades-channels
  #~(cons* (channel
            (name 'deployments)
            (url "https://gitlab.com/orang3/guix-deployments.git")
            (branch "main"))
           (channel
            (name 'small-guix)
            (url "https://gitlab.com/orang3/small-guix")
            ;; Enable signature verification:
            (introduction
             (make-channel-introduction
              "940e21366a8c986d1e10a851c7ce62223b6891ef"
              (openpgp-fingerprint
               "D088 4467 87F7 CBB2 AE08  BE6D D075 F59A 4805 49C3"))))
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

(define* (deployments-unattended-upgrades host-name #:key (channels %unattended-upgrades-channels) (hours 23) (minutes 10))
  (small-guix-unattended-upgrades-service host-name
                                          #:channels channels
                                          #:hours hours
                                          #:minutes minutes))
