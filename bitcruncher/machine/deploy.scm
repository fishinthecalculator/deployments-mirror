(define-module (bitcruncher machine deploy)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (bitcruncher system config))

(define %user
  "orang3")
(define %host
  "bitcruncher.xyz")
(define %host-key
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ28/8XvOOPYjuvsdSNqpHmQamtZF+zOf5FG74r7MPiF orang3@bitcruncher.xyz")

(define bitcruncher-hetzner
  (machine (operating-system
             bitcruncher-system)
           (environment managed-host-environment-type)
           (configuration (machine-ssh-configuration (host-name %host)
                                                     (host-key %host-key)
                                                     (system "x86_64-linux")
                                                     (user %user)
                                                     (identity
                                                      "../../keys/ssh/id_rsa.pub")))))

(list bitcruncher-hetzner)
