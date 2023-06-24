(define-module (nellone machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (nellone system config))

(define %user
  "paul")
(define %host
  "localhost")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOHyT9bXduTo1i0x5oS+fw79VCylT47ZHr4L4xK6jIW " %user "@" %host))

(define nellone-local
  (machine (operating-system
             nellone-system)
           (environment managed-host-environment-type)
           (configuration (machine-ssh-configuration (host-name "guix-latest")
                                                     (user %user)
                                                     (system "x86_64-linux")
                                                     (identity
                                                      "../../keys/ssh/id_rsa.pub")))))

(list nellone-local)
