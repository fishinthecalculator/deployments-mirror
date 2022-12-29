(define-module (frastanato system substitute)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (small-guix services substitute))

(define-public %frastanato-authorized-keys
  (append %small-guix-authorized-keys
          (list (file-append
                 (local-file "../.." "guix-deployments-root-dir"
                             #:recursive? #t)
                 "/keys/guix/prematurata.pub"))))
