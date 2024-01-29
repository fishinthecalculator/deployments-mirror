(define-module (frastanato machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (frastanato system config))

(define %user
  "paul")
(define %host
  "2001:19f0:6c01:13bc:5400:04ff:febe:a945")
(define %host-key
  (string-append
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1q2bXoOTL5A1Pfnqf5vftQv5D6dqlDx+CMKYpgvJAf " %user "@" %host))

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
