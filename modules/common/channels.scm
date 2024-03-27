(define-module (common channels)
  #:use-module (guix channels)
  #:export (%deployments-channels))

(define %deployments-channels
  (cons* (channel
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
