(define-module (fishinthecalculator virtual-nellone machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (fishinthecalculator virtual-nellone system config))

(define %user
  "deploy")
(define %host
  "192.248.184.140")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOno38xEWBPqtAg3tSV0tjo86+JAsATSwKqJbJkgciZ " %user "@" %host))

(define nellone-local
  (machine (operating-system
             virtual-nellone-system)
           (environment managed-host-environment-type)
           (configuration (machine-ssh-configuration (host-name %host)
                                                     (host-key
                                                      %host-key)
                                                     (user %user)
                                                     (system "x86_64-linux")
                                                     (identity
                                                      "../../../keys/ssh/id_rsa.pub")))))

(list nellone-local)
