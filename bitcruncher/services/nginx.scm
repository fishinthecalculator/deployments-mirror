(define-module (bitcruncher services nginx)
  #:use-module (gnu services web)
  #:use-module (guix gexp)
  #:export (bc-nginx-deploy-hook bc-nginx-configuration))

(define bc-nginx-deploy-hook
  (program-file "nginx-deploy-hook"
                #~(let ((pid (call-with-input-file "/var/run/nginx/pid"
                               read)))
                    (kill pid SIGHUP))))

(define bc-nginx-configuration
  (nginx-configuration (server-blocks (list (nginx-server-configuration (server-name '
                                                                         ("drone.bitcruncher.xyz"))
                                                                        (listen '
                                                                         ("443 ssl"))
                                                                        (index '
                                                                         ("index.htm"
                                                                          "index.html"))
                                                                        (root
                                                                         "/var/www/drone.bitcruncher.xyz/html")
                                                                        (ssl-certificate
                                                                         "/etc/letsencrypt/live/drone.bitcruncher.xyz/fullchain.pem")
                                                                        (ssl-certificate-key
                                                                         "/etc/letsencrypt/live/drone.bitcruncher.xyz/privkey.pem")
                                                                        (locations
                                                                         (list
                                                                          (nginx-location-configuration
                                                                           (uri
                                                                            "/")
                                                                           (body '
                                                                            ("proxy_pass http://drone;"
                                                                             "proxy_set_header Upgrade $http_upgrade;"
                                                                             "proxy_set_header Connection $connection_upgrade;"
                                                                             "proxy_redirect off;"
                                                                             "proxy_http_version 1.1;"
                                                                             "proxy_buffering off;"
                                                                             "chunked_transfer_encoding off;"
                                                                             "proxy_read_timeout 86400;"))))))))
                       (upstream-blocks (list (nginx-upstream-configuration (name
                                                                             "drone")
                                                                            (servers
                                                                             (list
                                                                              "127.0.0.1:8000")))))

                       (extra-content
                        "# top-level http config for websocket headers\n# If Upgrade is defined, Connection = upgrade\n# If Upgrade is empty, Connection = close\nmap $http_upgrade $connection_upgrade {\n    default upgrade;\n    ''      close;\n}")))
