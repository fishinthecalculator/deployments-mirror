(define-module (nellone machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (nellone system config))

(define %user "orang3")
(define %host "192.168.1.56")
(define %host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOHyT9bXduTo1i0x5oS+fw79VCylT47ZHr4L4xK6jIW orang3@192.168.1.56")

(define nellone-local
  (machine
   (operating-system nellone-system)
   (environment managed-host-environment-type)
   (configuration (machine-ssh-configuration
                   (host-name %host)
                   (host-key %host-key)
                   (system "x86_64-linux")
                   (user %user)
                   (identity "../../keys/ssh/id_rsa.pub")))))

(list nellone-local)
