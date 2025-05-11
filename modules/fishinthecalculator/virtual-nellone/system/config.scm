;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator virtual-nellone system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages databases)      ;for postgresql-15
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for iptables-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (small-guix services unattended-reboot)
  #:use-module (sops services sops)
  #:use-module (oci services containers)
  #:use-module (oci services bonfire)
  #:use-module (oci services prometheus)
  #:use-module (oci services meilisearch)
  #:use-module (oci services tandoor)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common scripts)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common services server)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator virtual-nellone services nginx)
  #:use-module (fishinthecalculator virtual-nellone system secrets)
  #:export (virtual-nellone-system
            virtual-nellone-common-server-services))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %tandoor-port "8080")
(define %tandoor-mediadir "/var/lib/tandoor/mediafiles")
(define %tandoor-staticdir "/var/lib/tandoor/staticfiles")
(define %tandoor-domain "tandoor.fishinthecalculator.me")

(define %bonfire-port "4000")
(define %bonfire-domain "bonfire.fishinthecalculator.me")
(define %bonfire-admin-email "goodoldpaul@autistici.org")
(define %bonfire-upload-data-directory "/var/lib/bonfire/uploads")
(define %meilisearch-port "7700")
(define %postgresql-port 5432)

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))

(define unload-allowed
  '("nginx" "podman-bonfire" "podman-tandoor" "postgres" "podman-prometheus"))

(define virtual-nellone-common-server-services
  (common-server-services subuids subgids))
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
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "cgroup")))
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
                           '("ncurses"
                             "gnupg"
                             "lsof"
                             "jq"
                             "ncdu"
                             "tree"
                             "curl"
                             "git"
                             "tmux"
                             "vim"
                             "tcpdump"
                             "net-tools"
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
                           (domains (list %bonfire-domain %tandoor-domain)))))))

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)))

              ;; Monitoring
              (service prometheus-node-exporter-service-type)

              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (image "prom/prometheus:v3.2.1")
                        (runtime 'podman)
                        (network "host")
                        (datadir
                         (oci-volume-configuration
                          (name "prometheus")))
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
                                     (targets '("localhost:9090"))))))
                            (prometheus-scrape-configuration
                             (job-name "node")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets '("localhost:9100"))))))))))))

              ;; Postgres
              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-15)
                        (extension-packages (list postgis))
                        (port %postgresql-port)))
              (service postgresql-role-service-type
                       (postgresql-role-configuration
                        (shepherd-requirement
                         (append
                          %default-postgresql-role-shepherd-requirement
                          '(sops-secrets)))))

              ;; Bonfire
              (service oci-bonfire-service-type
                       (oci-bonfire-configuration
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
                        (upload-data-directory %bonfire-upload-data-directory)
                        (auto-start? #t)
                        (requirement
                         '(user-processes postgresql postgres-roles sops-secrets podman-meilisearch))
                        (extra-variables
                         `(("MAIL_BACKEND" . "mailjet")
                           ("SERVER_PORT" . ,%bonfire-port)
                           ("SEARCH_MEILI_INSTANCE" . ,(string-append "http://localhost:" %meilisearch-port))))
                        (meili-master-key
                         meilisearch-key-secret)
                        (postgres-password
                         bonfire-postgres-password-secret)
                        (mail-key
                         bonfire-mail-key-secret)
                        (mail-private-key
                         bonfire-mail-private-key-secret)
                        (secret-key-base
                         bonfire-secret-key-base-secret)
                        (signing-salt
                         bonfire-signing-salt-secret)
                        (encryption-salt
                         bonfire-encryption-salt-secret)))

              (service oci-meilisearch-service-type
                       (oci-meilisearch-configuration
                        (network "host")
                        (port %meilisearch-port)
                        (master-key
                         meilisearch-key-secret)))

              ;; Tandoor
              (service oci-tandoor-service-type
                       (oci-tandoor-configuration
                        (runtime 'podman)
                        (port %tandoor-port)
                        (network "host")
                        (mediadir
                         %tandoor-mediadir)
                        (staticdir
                         %tandoor-staticdir)
                        (postgres-password
                         tandoor-postgres-password-secret)
                        (secret-key
                         tandoor-secret-key-secret)))

              (service oci-service-type
                       (oci-configuration
                        (runtime 'podman)
                        (verbose? #t)))

              (service nginx-service-type
                       (nginx-configuration
                        ;; Wait for tandoor to start
                        (shepherd-requirement
                         '(podman-bonfire
                           podman-tandoor))
                        (server-blocks
                         (list
                          (bonfire-nginx-server %bonfire-domain %bonfire-port %bonfire-upload-data-directory)
                          (tandoor-nginx-server %tandoor-domain %tandoor-port %tandoor-mediadir %tandoor-staticdir)))))

              ;; Misc
              (service common-unload-service-type
                       unload-allowed)
              (service unattended-reboot-service-type
                       (unattended-reboot-configuration
                        (schedule "0 6 * * *")
                        (unload
                         (map string->symbol unload-allowed))))

              (deployments-unattended-upgrades host-name
                                               #:expiration-days 30))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services virtual-nellone-common-server-services
               (iptables-service-type iptables-config =>
                                     (iptables-configuration
                                      (ipv4-rules (plain-file "iptables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
"))
                                      (ipv6-rules (plain-file "ip6tables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -j REJECT --reject-with icmp6-port-unreachable
COMMIT
"))))

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
                 (targets (list "/dev/sda"))
                 (keyboard-layout keyboard-layout)))
    (initrd-modules (append '("virtio_scsi") %base-initrd-modules))
    (swap-devices (list (swap-space
                          (target (uuid
                                   "ffa36e3c-b576-43fc-a9cf-90f0dfd1d4d9")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "e4a319f6-6552-4d6b-afe8-9988df65173c"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
