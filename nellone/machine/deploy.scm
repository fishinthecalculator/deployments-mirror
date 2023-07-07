(define-module (nellone machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (nellone system config))

(define %user
  "paul")
(define %host
  "2001:19f0:6c01:578:5400:4ff:fe7f:ec7f")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLojfSBpWKZo5BwClBnq/B2lqL1eioHv7mK4Y/OzCG9 " %user "@" %host))

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
