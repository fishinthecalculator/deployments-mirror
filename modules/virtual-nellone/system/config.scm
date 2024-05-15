;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (virtual-nellone system config)
  #:use-module (gnu)
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (sops services sops)
  #:use-module (oci services bonfire)
  #:use-module (oci services grafana)
  #:use-module (oci services meilisearch)
  #:use-module (oci services prometheus)
  #:use-module (common keys)
  #:use-module (common scripts)
  #:use-module (common secrets)
  #:use-module (common services server)
  #:use-module (common services unattended-upgrades)
  #:use-module (common users)
  #:use-module (virtual-nellone system secrets)
  #:export (virtual-nellone-system))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %bonfire-port "4000")
(define %bonfire-domain "bonfire.fishinthecalculator.me")
(define %grafana-port "3000")
(define %meilisearch-port "7700")
(define %postgresql-port 5432)
(define %prometheus-port "9000")
(define %prometheus-metrics-port "9090")
(define %node-exporter-port "9100")

(define virtual-nellone-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "virtual-nellone")

    ;; The list of user accounts ('root' is implicit).
    (users (cons* (user-account
                   (inherit paul-user)
                   (comment "Tino il Cotechino")
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))
                  (user-account
                   (name "deploy")
                   (comment "Guix deploy user")
                   (group "users")
                   (supplementary-groups '("tty"))
                   (system? #t))
                  %base-user-accounts))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append
                  (plain-file-content %sudoers-specification)
                  "\n deploy ALL=(ALL) NOPASSWD: ALL\n")))

    ;; Packages installed system-wide.  Users can also install packages
    ;; under their own account: use 'guix search KEYWORD' to search
    ;; for packages and 'guix install PACKAGE' to install a package.
    (packages (append (map specification->package+output
                           '("ncurses"  ;for the search path

                             ;; Standard FreeDesktop directory paths
                             "xdg-user-dirs"
                             "xdg-utils"
                             ;; User mounts
                             "gvfs"

                             ;;OpenGPG
                             "gnupg"
                             ;; Misc
                             "lsof"
                             "jq"
                             "ncdu"
                             "tree"
                             "curl"
                             "fd"
                             "git"
                             "htop"
                             "ripgrep"
                             "tmux"
                             "vim"

                             ;; DB Administration
                             "postgresql@14" ;for psql

                             ;; Network administration
                             "bind"
                             "bind:utils"
                             "tcpdump"
                             "net-tools"

                             "restic"

                             "efibootmgr"

                             "rclone"
                             "emacs"
                             "ripgrep"))
                      (list common-deploy-scripts)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
              (service certbot-service-type
                       (certbot-configuration
                        (email "goodoldpaul@autistici.org")
                        (certificates
                         (list
                          (certificate-configuration
                           (domains (list %bonfire-domain)))))))

              (service nginx-service-type
                       (nginx-configuration
                        (shepherd-requirement
                         '(docker-bonfire))
                        (server-blocks
                         (list (nginx-server-configuration
                                (server-name (list %bonfire-domain))
                                (listen '("443 ssl"))
                                (ssl-certificate (string-append "/etc/certs/" %bonfire-domain "/fullchain.pem"))
                                (ssl-certificate-key (string-append "/etc/certs/" %bonfire-domain "/privkey.pem"))
                                (locations
                                 (list
                                  (nginx-location-configuration
                                   (uri "/")
                                   (body (string-join (list (string-append "proxy_pass http://localhost:" %bonfire-port)
                                                            ;; Taken from https://www.nginx.com/resources/wiki/start/topics/examples/full/
                                                            ;; Those settings are used when proxies are involved
                                                            "proxy_redirect          off"
                                                            "proxy_set_header        Host $host"
                                                            "proxy_set_header        X-Real-IP $remote_addr"
                                                            "proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for"
                                                            "proxy_http_version      1.1"
                                                            "proxy_cache_bypass      $http_upgrade"
                                                            "proxy_set_header        Upgrade $http_upgrade"
                                                            "proxy_set_header        Connection \"upgrade\""
                                                            "proxy_set_header        X-Forwarded-Proto $scheme"
                                                            "proxy_set_header        X-Forwarded-Host  $host;")
                                                      ";\n"))))))))))

              ;; Monitoring
              (service prometheus-node-exporter-service-type
                       (prometheus-node-exporter-configuration
                        (web-listen-address
                         (string-append ":" %node-exporter-port))))

              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (image "prom/prometheus:v2.45.0")
                        (network "host")
                        (port %prometheus-port)
                        (metrics-port %prometheus-metrics-port)
                        (record
                         (prometheus-configuration
                          (global
                           (prometheus-global-configuration
                            (scrape-interval "30s")
                            (scrape-timeout "12s")))
                          (scrape-configs
                           (list
                            (prometheus-scrape-configuration
                             (job-name "prometheus")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets
                                      (list
                                       (string-append "localhost:" %prometheus-metrics-port)))))))
                            (prometheus-scrape-configuration
                             (job-name "node")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets
                                      (list (string-append "localhost:" %node-exporter-port)))))))))))))

              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (network "host")
                        (port %grafana-port)))

              ;; Bonfire
              (service oci-bonfire-service-type
                       (oci-bonfire-configuration
                        (image "bonfirenetworks/bonfire:0.9.10-beta.70-classic-amd64")
                        (log-file "/var/log/bonfire.log")
                        (configuration
                         (bonfire-configuration
                          (hostname %bonfire-domain)
                          (port %bonfire-port)
                          (public-port "443")
                          (postgres-user "bonfire")
                          (postgres-db "bonfire")
                          (mail-domain %bonfire-domain)
                          (mail-from (string-append "friendlyadmin@" %bonfire-domain))))
                        (network "host")
                        (auto-start? #t)
                        (requirement
                         '(sops-secrets postgres-roles docker-meilisearch))
                        (extra-variables
                         `("INVITE_ONLY=true"
                           ("MAIL_BACKEND" . "sendgrid")
                           ("SERVER_PORT" . ,%bonfire-port)
                           ("SEARCH_MEILI_INSTANCE" . ,(string-append "http://localhost:" %meilisearch-port))))
                        (meili-master-key
                         meilisearch-key-secret)
                        (postgres-password
                         postgres-password-secret)
                        (mail-password
                         mail-password-secret)
                        (secret-key-base
                         secret-key-base-secret)
                        (signing-salt
                         signing-salt-secret)
                        (encryption-salt
                         encryption-salt-secret)))

              (service oci-meilisearch-service-type
                       (oci-meilisearch-configuration
                        (network "host")
                        (port %meilisearch-port)
                        (master-key
                         meilisearch-key-secret)))

              (service postgresql-role-service-type
                       (postgresql-role-configuration
                        (roles
                         (list (postgresql-role
                                (name "bonfire")
                                (create-database? #t))))))

              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-14)
                        (extension-packages (list postgis))
                        (port %postgresql-port)))

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)
                        (secrets
                         (list postgres-password-secret
                               mail-password-secret
                               secret-key-base-secret
                               signing-salt-secret
                               encryption-salt-secret))))

              (deployments-unattended-upgrades host-name
                                               #:expiration-days 30))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services %common-server-services
               (openssh-service-type ssh-config =>
                                     (openssh-configuration (inherit ssh-config)
                                                            (authorized-keys
                                                             (append
                                                              (openssh-configuration-authorized-keys ssh-config)
                                                              authorized-ssh-keys))))
               (guix-service-type guix-config =>
                                  (guix-configuration (inherit guix-config)
                                                      (authorized-keys
                                                       (append
                                                        (guix-configuration-authorized-keys guix-config)
                                                        authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/vda"))
                 (keyboard-layout keyboard-layout)
                 ;; guix shell cpio -- sh -c 'echo /crypto.key | cpio -oH newc > /crypto.cpio'
                 ;; chmod 0000 /crypto.cpio
                 ;; Load the initrd with a key file
                 (extra-initrd "/crypto.cpio")))
    (mapped-devices (list (mapped-device
                           (source (uuid
                                    "b8482f5a-d64a-4501-a52d-f2439f9f786a"))
                           (target "cryptroot")
                           (type (luks-device-mapping-with-options
                                  ;; All the following must be run as root
                                  ;; DEST="/crypto.key"
                                  ;; dd bs=512 count=4 if=/dev/random of=$DEST iflag=fullblock
                                  ;; guix shell openssl -- openssl genrsa -out $DEST 4096
                                  ;; chmod -v 0400 $DEST
                                  ;; chown root:root $DEST
                                  #:key-file "/crypto.key")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "ext4")
                           (dependencies mapped-devices)) %base-file-systems))

    (swap-devices
     (list
      (swap-space
       ;; See https://www.cyberciti.biz/faq/linux-add-a-swap-file-howto/
       ;; for swapfile on ext4
       (target "/swapfile")
       (dependencies (filter (file-system-mount-point-predicate "/")
                             file-systems)))))))
