(define-module (frastanato machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (frastanato system config))

(define %user
  "deploy")
(define %host
  "192.168.1.80")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIt3RXHCdBBstNR36i7VgXfCS4fmiOdqo+wjALebETj " %user "@" %host))

(define frastanato-local
  (machine (operating-system
             frastanato-system)
           (environment managed-host-environment-type)
           (configuration (machine-ssh-configuration (host-name %host)
                                                     (host-key
                                                      %host-key)
                                                     (user %user)
                                                     (system "x86_64-linux")
                                                     (identity
                                                      "../../../keys/ssh/id_rsa.pub")))))

(list frastanato-local)
