(define-module (services ssh)
  #:use-module (gnu services ssh)
  #:use-module (guix gexp)
  #:use-module (self)
  #:export (%openssh-configuration))

(define authorized-ssh-keys
  ;; List of authorized 'guix archive' keys.
  `(("orang3" ,(file-append %guix-deployments-config-dir
                            "/keys/ssh/id_rsa.pub"))))

(define %openssh-configuration
  (openssh-configuration (authorized-keys authorized-ssh-keys)))
