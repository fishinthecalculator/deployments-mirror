(define-module (nellone machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (nellone system config))

(define %user
  "paul")
(define %host
  "136.244.87.15")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGMuZG/nZz8oUQQP2g8aBlRH0ahef8oiAyy3ffy9x1VT " %user "@" %host))

(define nellone-local
  (machine (operating-system
             nellone-system)
           (environment managed-host-environment-type)
           (configuration (machine-ssh-configuration (host-name %host)
                                                     (host-key
                                                      %host-key)
                                                     (user %user)
                                                     (system "x86_64-linux")
                                                     (identity
                                                      "../../keys/ssh/id_rsa.pub")))))

(list nellone-local)
