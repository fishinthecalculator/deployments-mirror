;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator bemmezero system config)
  #:use-module (gnu)
  #:use-module (gnu system accounts)
  #:use-module (gnu packages databases)      ;for postgresql-16
  #:use-module (gnu packages geo)            ;for postgis
  #:use-module (gnu services certbot)        ;for certbot-service-type
  #:use-module (gnu services containers)     ;for rootless-podman-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services docker)         ;for docker-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for iptables-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services web)            ;for nginx-service-type
  #:use-module (sops services sops)
  #:use-module (oci services bonfire)
  #:use-module (oci services meilisearch)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common scripts)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common services server)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator bemmezero services nginx)
  #:use-module (fishinthecalculator bemmezero system secrets)
  #:export (bemmezero-system
            bemmezero-common-server-services))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      (,paul ,paul-ed25519-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %bonfire-port "4000")
(define %bonfire-domain "bonfire.municipiozero.it")
(define %bonfire-admin-email "labug.info@gmail.com")
(define %bonfire-upload-data-directory "/var/lib/bonfire/uploads")
(define %meilisearch-port "7700")
(define %postgresql-port 5432)

(define subgids
  (list))
(define subuids
  (list))

(define bemmezero-common-server-services
  (common-server-services subuids subgids))
(define bemmezero-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "bemmezero")

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
                             "btop"
                             "ripgrep"
                             "tmux"
                             "vim"

                             ;; DB Administration
                             "postgresql@15" ;for psql

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
                        (email %bonfire-admin-email)
                        (certificates
                         (list
                          (certificate-configuration
                           (domains (list %bonfire-domain)))))))

              (service containerd-service-type)
              (service docker-service-type)

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)
                        (secrets
                         (list ;; Bonfire
                               meilisearch-key-secret
                               postgres-password-secret
                               mail-key-secret
                               mail-private-key-secret
                               secret-key-base-secret
                               signing-salt-secret
                               encryption-salt-secret))))

              ;; Bonfire
              (service oci-bonfire-service-type
                       (oci-bonfire-configuration
                        (configuration
                         (bonfire-configuration
                          (hostname %bonfire-domain)
                          (flavour "open_science")
                          (port %bonfire-port)
                          (public-port "443")
                          (postgres-user "bonfire")
                          (postgres-db "bonfire")
                          (mail-domain %bonfire-domain)
                          (mail-from (string-append "friendlyadmin@" %bonfire-domain))))
                        (network "host")
                        (upload-data-directory %bonfire-upload-data-directory)
                        (auto-start? #f)
                        (requirement
                         '(sops-secrets postgres-roles user-processes docker-meilisearch))
                        (extra-variables
                         `(("MAIL_BACKEND" . "mailjet")
                           ("SERVER_PORT" . ,%bonfire-port)
                           ("SEARCH_MEILI_INSTANCE" . ,(string-append "http://localhost:" %meilisearch-port))))
                        (meili-master-key
                         (sops-secret->secret-file meilisearch-key-secret))
                        (postgres-password
                         (sops-secret->secret-file postgres-password-secret))
                        (mail-key
                         (sops-secret->secret-file mail-key-secret))
                        (mail-private-key
                         (sops-secret->secret-file mail-private-key-secret))
                        (secret-key-base
                         (sops-secret->secret-file secret-key-base-secret))
                        (signing-salt
                         (sops-secret->secret-file signing-salt-secret))
                        (encryption-salt
                         (sops-secret->secret-file encryption-salt-secret))))

              (service oci-meilisearch-service-type
                       (oci-meilisearch-configuration
                        (network "host")
                        (port %meilisearch-port)
                        (master-key
                         (sops-secret->secret-file meilisearch-key-secret))))

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

              (service nginx-service-type
                       (nginx-configuration
                        ;; Wait for bonfire to start
                        (shepherd-requirement
                         '(docker-bonfire))
                        (server-blocks
                         (list
                          (bonfire-nginx-server %bonfire-domain %bonfire-port %bonfire-upload-data-directory)))))

              ;; Misc
              (service common-unload-service-type
                       '("nginx" "docker-bonfire" "postgres"))

              (deployments-unattended-upgrades host-name
                                               #:expiration-days 30))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services bemmezero-common-server-services
               (delete rootless-podman-service-type)
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
                                   "8b68151e-0686-4e87-b9cb-41b14cc81a69")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "7a0cdc70-047c-446b-9e1a-ff95527c1f9b"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
