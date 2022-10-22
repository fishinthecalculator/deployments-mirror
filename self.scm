(define-module (self)
  #:use-module (guix channels)
  #:use-module (guix gexp))

(define-public %guix-deployments-config-dir
  (local-file "." "deployments-config-dir" #:recursive? #t))

(define-public %guix-deployment-channels
  (append
   %default-channels
   (list (channel
          (name 'guix-deployments)
          (url "https://gitlab.com/orang3/guix-deployments.git")
          (branch "main")))))
