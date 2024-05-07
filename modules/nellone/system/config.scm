;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (nellone system config)
  #:use-module (gnu)
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  ;; #:use-module (sops secrets)
  #:use-module ((sops services databases) #:prefix sops:)
  #:use-module (sops services sops)
  #:use-module (oci services bonfire)
  #:use-module (oci services grafana)
  #:use-module (oci services meilisearch)
  #:use-module (oci services prometheus)
  ;; #:use-module (small-guix packages scripts) ;for restic-bin
  ;; #:use-module (small-guix services backup)
  #:use-module (common keys)
  #:use-module (common scripts)
  ;; #:use-module (common secrets)
  ;; #:use-module (common self)
  #:use-module (common services server)
  #:use-module (common services unattended-upgrades)
  #:use-module (common users)
  #:use-module (nellone system secrets)
  ;; #:use-module (srfi srfi-1)
  #:export (virtual-nellone-system))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

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

                             ;; Network administration
                             "bind"
                             "bind:utils"
                             "tcpdump"

                             ;; Btrfs
                             "btrfs-progs"
                             "compsize"
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

              ;; Monitoring
              (service prometheus-node-exporter-service-type)

              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (image "prom/prometheus:v2.45.0")
                        (network "host")
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

              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (network "host")))

              ;; Bonfire
              ;; (service oci-bonfire-service-type
              ;;          (oci-bonfire-configuration
              ;;           (configuration
              ;;            (bonfire-configuration
              ;;             (hostname "192.168.1.80")
              ;;             (postgres-user "bonfire")
              ;;             (postgres-db "bonfire")
              ;;             (mail-server "smtp.gmail.com")
              ;;             (mail-domain "gmail.com")
              ;;             (mail-from "lalloni@gmail.com")
              ;;             (mail-user "leidigiacomo")))
              ;;           (network "host")
              ;;           (requirement
              ;;            '(sops-secrets-postgres-roles docker-meilisearch))
              ;;           (extra-variables
              ;;            '(("SEARCH_MEILI_INSTANCE" . "http://localhost:7700")))
              ;;           (postgres-password
              ;;            postgres-password-secret)
              ;;           (mail-password
              ;;            (sops-secret
              ;;             (key '("smtp" "password"))
              ;;             (file nellone.yaml)))
              ;;           (secret-key-base
              ;;            (sops-secret
              ;;             (key '("bonfire" "secret_key_base"))
              ;;             (file nellone.yaml)))
              ;;           (signing-salt
              ;;            (sops-secret
              ;;             (key '("bonfire" "signing_salt"))
              ;;             (file nellone.yaml)))
              ;;           (encryption-salt
              ;;            (sops-secret
              ;;             (key '("bonfire" "encryption_salt"))
              ;;             (file nellone.yaml)))))

              (service oci-meilisearch-service-type
                       (oci-meilisearch-configuration
                        (network "host")
                        (master-key
                         meilisearch-key-secret)))

              (service sops:postgresql-role-service-type
                       (sops:postgresql-role-configuration
                        (requirement '(sops-secrets))
                        (roles
                         (list (sops:postgresql-role
                                (name "bonfire")
                                (password-file "/run/secrets/postgres/bonfire")
                                (create-database? #t))))))

              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-13)))


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
                                                            (authorized-keys (append
                                                                              (openssh-configuration-authorized-keys ssh-config)
                                                                              authorized-ssh-keys))))
               (guix-service-type guix-config =>
                                  (guix-configuration (inherit guix-config)
                                                      (authorized-keys (append
                                                                        (guix-configuration-authorized-keys guix-config)
                                                                        authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/vda"))
                 (keyboard-layout keyboard-layout)))
    (mapped-devices (list (mapped-device
                           (source (uuid
                                    "b8482f5a-d64a-4501-a52d-f2439f9f786a"))
                           (target "cryptroot")
                           (type luks-device-mapping))))

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
