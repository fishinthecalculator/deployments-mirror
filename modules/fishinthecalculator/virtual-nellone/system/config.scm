;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024-2026 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator virtual-nellone system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages databases)      ;for postgresql-15
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services backup)         ;for restic-backup-service-type
  #:use-module (gnu services containers)     ;for oci-service-type
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for iptables-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (small-guix packages databases)
  #:use-module (small-guix packages scripts)
  #:use-module (small-guix services databases)
  #:use-module (small-guix services git)
  #:use-module (small-guix services monitoring)
  #:use-module (small-guix services soju)
  #:use-module (small-guix services unattended-reboot)
  #:use-module (sops services sops)
  #:use-module (oci services grafana)
  #:use-module (oci services prometheus)
  #:use-module (oci services meilisearch)
  #:use-module (oci services tandoor)
  #:use-module (bonfire services bonfire)
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

(define paul-name
  (user-account-name paul-user))

(define authorized-ssh-keys
  ;; List of authorized SSH keys.
  `((,paul-name ,paul-ssh-key)
    (,paul-name ,paul-ed25519-ssh-key)
    ("deploy" ,paul-ssh-key)))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %soju-domain "irc.fishinthecalculator.me")
(define %soju-certbot-deploy-hook
  (program-file "soju-certbot-deploy-hook.scm"
    (with-imported-modules '((gnu services herd))
      #~(begin
         (use-modules (gnu services herd)
          (with-shepherd-action 'soju ('reload) result result))))))

(define %tandoor-port "8080")
(define %tandoor-mediadir "/var/lib/tandoor/mediafiles")
(define %tandoor-staticdir "/var/lib/tandoor/staticfiles")
(define %tandoor-domain "tandoor.fishinthecalculator.me")
(define %tandoor-postgres-db "tandoor_db")

(define %bonfire-port "4000")
(define %bonfire-domain "bonfire.fishinthecalculator.me")
(define %bonfire-admin-email "therewasa@fishinthecalculator.me")
(define %bonfire-upload-data-directory "/var/lib/bonfire/uploads")
(define %bonfire-postgres-db "bonfire")

(define %meilisearch-port "7700")

(define %postgresql-port 5432)

(define %grafana-port "3000")

(define %postgresql-backups-directory
  "/var/lib/postgresql-backups")
(define %databases-to-backup
  (list %bonfire-postgres-db
        %tandoor-postgres-db))

(define subgids
  (list (subid-range (name paul-name))))
(define subuids
  (list (subid-range (name paul-name))))

(define unload-allowed
  '("nginx" "podman-bonfire" "podman-tandoor" "postgres" "podman-prometheus"))

(define-public backup-system-jobs
  (list
   (restic-backup-job
    (name "onedrive")
    (restic restic-bin)
    (repository "rclone:onedrive:backup/virtual-nellone")
    (requirement '(user-processes file-systems sops-secrets))
    (password-file (sops-secret->secret-file restic-repository-secret))
    ;; Every day at 5:30.
    (schedule "30 5 * * *")
    (files `("/root/.config/rclone"
             "/root/.config/sops/age/keys.txt"
             "/home/paul/.ssh/"
             "/home/paul/.config/rclone"
             "/home/paul/.config/sops/age/keys.txt"
             "/etc/ssh/ssh_host_ecdsa_key"
             "/etc/ssh/ssh_host_ecdsa_key.pub"
             "/etc/ssh/ssh_host_ed25519_key"
             "/etc/ssh/ssh_host_ed25519_key.pub"
             "/etc/ssh/ssh_host_rsa_key"
             "/etc/ssh/ssh_host_rsa_key.pub"
             "/etc/guix/signing-key.pub"
             "/etc/guix/signing-key.sec"
             ,%postgresql-backups-directory
             ,%bonfire-upload-data-directory
             ,%tandoor-mediadir
             ,%tandoor-staticdir))
    (verbose? #t))))

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
                             "bind"
                             "bind:utils"
                             "ripgrep"
                             "rclone"))
                      (list common-deploy-scripts
                            restic-bin)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
              (service certbot-service-type
                       (certbot-configuration
                        (email "therewasa@fishinthecalculator.me")
                        (certificates
                         (list
                          (certificate-configuration
                           (domains (list %soju-domain))
                           (deploy-hook %soju-certbot-deploy-hook))
                          (certificate-configuration
                           (domains (list %tandoor-domain)))
                          (certificate-configuration
                           (domains (list %bonfire-domain)))))))

              (service git-sync-service-type
                       (git-sync-configuration
                        (user paul-name)))
              (simple-service 'sync-jobs
                              git-sync-service-type
                              (git-sync-extension
                               (jobs
                                (list
                                 (git-sync-job
                                  (provision "gocix")
                                  (schedule "0,15,30,45 * * * *")
                                  (branch "main")
                                  (source
                                   (git-sync-remote
                                    (name "github")
                                    (url "git@github.com:fishinthecalculator/gocix.git")))
                                  (destination
                                   (git-sync-remote
                                    (name "codeberg")
                                    (url "ssh://git@codeberg.org/fishinthecalculator/gocix-mirror.git"))))))))

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)
                        (log-directory "/var/log/sops")
                        (secrets
                         (list ;; Restic backups
                               restic-repository-secret
                               ;; IRC bouncer client certificate
                               irc-certificate-secret
                               ;; Bonfire
                               meilisearch-key-secret
                               bonfire-postgres-password-secret
                               bonfire-mail-key-secret
                               bonfire-mail-private-key-secret
                               bonfire-secret-key-base-secret
                               bonfire-signing-salt-secret
                               bonfire-encryption-salt-secret))))

              ;; Backups
              (service restic-backup-service-type
                       (restic-backup-configuration
                        (jobs backup-system-jobs)))

              ;; Monitoring
              (service prometheus-node-exporter-service-type)
              (service prometheus-postgres-exporter-service-type)

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
                          (retention-time "90d")
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
                                     (targets '("localhost:9100"))))))
                            (prometheus-scrape-configuration
                             (job-name "postgres")
                             (static-configs
                              (list (prometheus-static-configuration
                                     (targets '("localhost:9187"))))))))))))

              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (runtime 'podman)
                        (image "docker.io/bitnami/grafana:12.0.1")
                        (network "host")
                        (port %grafana-port)
                        (grafana.ini
                         (grafana-configuration
                          (smtp
                           (grafana-smtp-configuration
                            (enabled? #t)
                            (host "in-v3.mailjet.com:587")
                            (from-address
                             "monitoring@tandoor.fishinthecalculator.me")
                            (user
                             "5485f1c8cabfd7cbc6d92669f7120275")
                            (password-file
                             grafana-mail-private-key-secret)))))
                        (datadir
                         (oci-volume-configuration
                          (name "grafana")))))

              ;; IRC bouncer
              (service soju-service-type
                       (soju-configuration
                        (hostname %soju-domain)
                        (listen '("ircs://" "unix+admin:///var/lib/soju/soju.sock"))
                        (ssl-certificate (string-append "/etc/certs/" %soju-domain "/fullchain.pem"))
                        (ssl-certificate-key (string-append "/etc/certs/" %soju-domain "/privkey.pem"))
                        (title "virtual-nellone IRC bouncer")))

              ;; Postgres
              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-15)
                        (extension-packages (list (postgis-for-postgres postgresql-15)))
                        (port %postgresql-port)))
              (service postgresql-role-service-type
                       (postgresql-role-configuration
                        (shepherd-requirement
                         (append
                          %default-postgresql-role-shepherd-requirement
                          '(sops-secrets)))))
              (service postgresql-backup-service-type
                       (postgresql-backup-configuration
                        (package
                          (postgresql-backup-scripts/postgres postgresql-15))
                        (schedule "0 5 * * *")
                        (databases
                         %databases-to-backup)
                        (day-of-week-to-keep 6)
                        (days-to-keep 7)
                        (weeks-to-keep 5)))

              ;; Bonfire
              (service oci-bonfire-service-type
                       (oci-bonfire-configuration
                        (configuration
                         (bonfire-configuration
                          (hostname %bonfire-domain)
                          (port %bonfire-port)
                          (public-port "443")
                          (postgres-user "bonfire")
                          (postgres-db %bonfire-postgres-db)
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
                         (sops-secret->secret-file meilisearch-key-secret))
                        (postgres-password
                         (sops-secret->secret-file bonfire-postgres-password-secret))
                        (mail-key
                         (sops-secret->secret-file bonfire-mail-key-secret))
                        (mail-private-key
                         (sops-secret->secret-file bonfire-mail-private-key-secret))
                        (secret-key-base
                         (sops-secret->secret-file bonfire-secret-key-base-secret))
                        (signing-salt
                         (sops-secret->secret-file bonfire-signing-salt-secret))
                        (encryption-salt
                         (sops-secret->secret-file bonfire-encryption-salt-secret))))

              (service oci-meilisearch-service-type
                       (oci-meilisearch-configuration
                        (network "host")
                        (port %meilisearch-port)
                        (shepherd-requirement
                         '(user-processes sops-secrets))
                        (master-key
                         (sops-secret->secret-file meilisearch-key-secret))))

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
                        (email-host-password
                         tandoor-email-host-password)
                        (postgres-password
                         tandoor-postgres-password-secret)
                        (secret-key
                         tandoor-secret-key-secret)
                        (configuration
                         (tandoor-configuration
                          (tandoor-port "8080")
                          (postgres-db %tandoor-postgres-db)
                          (email-host
                           "in-v3.mailjet.com")
                          (email-port "587")
                          (email-host-user
                           "5485f1c8cabfd7cbc6d92669f7120275")
                          (email-use-tls? #t)
                          (default-from-email
                            "friendlyadmin@tandoor.fishinthecalculator.me")))))

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
                        (stop
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
-A INPUT -p tcp --dport 6697 -j ACCEPT
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
-A INPUT -p tcp --dport 6697 -j ACCEPT
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
