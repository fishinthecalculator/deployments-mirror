(define-module (bitcruncher services ssl)
  #:use-module (bitcruncher services nginx)
  #:use-module (gnu services certbot)
  #:use-module (guix gexp))

(define-public bc-certbot-configuration
  (certbot-configuration (email "goodoldpaul@autistici.org")
                         (certificates (list (certificate-configuration (domains '
                                                                         ("bitcruncher.xyz"
                                                                          "www.bitcruncher.xyz"))
                                                                        (deploy-hook
                                                                         bc-nginx-deploy-hook))
                                             (certificate-configuration (domains '
                                                                         ("drone.bitcruncher.xyz"))
                                                                        (deploy-hook
                                                                         bc-nginx-deploy-hook))))))
