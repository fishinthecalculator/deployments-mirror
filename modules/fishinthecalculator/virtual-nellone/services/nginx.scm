;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone services nginx)
  #:use-module (gnu services web))

(define-public (bonfire-nginx-server domain port upload-data-dir)
  (nginx-server-configuration
   (server-name (list domain))
   (listen '("443 ssl" "[::]:443 ssl"))
   (ssl-certificate (string-append "/etc/certs/" domain "/fullchain.pem"))
   (ssl-certificate-key (string-append "/etc/certs/" domain "/privkey.pem"))
   (locations
    (list
     (nginx-location-configuration
      (uri "/")
      (body (list (string-append "proxy_pass http://127.0.0.1:" port ";")
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

(define-public (tandoor-nginx-server domain port mediadir staticdir)
  (nginx-server-configuration
   (server-name (list domain))
   (listen '("443 ssl" "[::]:443 ssl"))
   (ssl-certificate (string-append "/etc/certs/" domain "/fullchain.pem"))
   (ssl-certificate-key (string-append "/etc/certs/" domain "/privkey.pem"))
   (locations
    (list
     (nginx-location-configuration
      (uri "/")
      (body (list (string-append "proxy_pass http://127.0.0.1:" port ";")
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
                  "proxy_set_header        X-Forwarded-Host  $host;")))
     (nginx-location-configuration
      (uri "/media/")
      (body
       (list (string-append "alias  " mediadir "/;")
             "index  index.html index.htm;")))
     (nginx-location-configuration
      (uri "/tmp/")
      (body
       (list "alias /test-serve/;"
             "autoindex on;")))
     (nginx-location-configuration
      (uri "/static/")
      (body
       (list (string-append "alias  " staticdir "/;")
             "index  index.html index.htm;")))))))
