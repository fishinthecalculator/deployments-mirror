(define-module (common channels)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:export (%deployments-channels
            %unattended-upgrades-channels))

(define %deployments-channels
  (cons*
   (channel
    (name 'deployments)
    (url "https://gitlab.com/orang3/guix-deployments.git")
    (branch "main")
    ;; Enable signature verification:
    (introduction
     (make-channel-introduction
      "9d101a2b1f38571e75e7d256bbc8d754177d11f3"
      (openpgp-fingerprint
       "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))
   %default-channels))

(define %unattended-upgrades-channels
  #~(list #$@(map channel->code %deployments-channels)))
