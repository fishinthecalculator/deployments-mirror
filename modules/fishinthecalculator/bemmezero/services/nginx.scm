;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator bemmezero services nginx)
  #:use-module (gnu services web))

(define-public (bonfire-nginx-server domain port upload-data-dir)
  (nginx-server-configuration
   (server-name (list domain))
   (listen '("443 ssl"))
   (ssl-certificate (string-append "/etc/certs/" domain "/fullchain.pem"))
   (ssl-certificate-key (string-append "/etc/certs/" domain "/privkey.pem"))
   (locations
    (list
     (nginx-location-configuration
      (uri "/c4675f4d88b774d8f032d4c763e00631.txt")
      (body
       (list (string-append "alias /tmp/c4675f4d88b774d8f032d4c763e00631.txt;")
             "c4675f4d88b774d8f032d4c763e00631.txt;")))
     (nginx-location-configuration
      (uri "/")
      (body (list (string-append "proxy_pass http://localhost:" port ";")
                  ;; Taken from https://www.nginx.com/resources/wiki/start/topics/examples/full/
                  ;; Those settings are used when proxies are involved
                  "proxy_redirect          off;"
                  "proxy_set_header        Host $host;"
                  "proxy_set_header        X-Real-IP $remote_addr;"
                  "proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;"
                  "proxy_http_version      1.1;"
                  "proxy_cache_bypass      $http_upgrade;"
                  "proxy_set_header        Upgrade $http_upgrade;"
                  "proxy_set_header        Connection \"upgrade\";"
                  "proxy_set_header        X-Forwarded-Proto $scheme;"
                  "proxy_set_header        X-Forwarded-Host  $host;")))))))
