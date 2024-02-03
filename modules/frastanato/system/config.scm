;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (frastanato system config)
  #:use-module (gnu)
  #:use-module (gnu packages admin) ;for shadow
  #:use-module (gnu packages databases)      ;for postgresql-12
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services file-sharing)   ;for transmission-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for network-manager-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (sops services databases)
  #:use-module (sops services sops)
  #:use-module (oci services bonfire)
  #:use-module (oci services grafana)
  #:use-module (oci services meilisearch)
  #:use-module (oci services prometheus)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages nvidia) ;for nvidia-module
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services server)
  #:use-module (common keys)
  #:use-module (common scripts)
  #:use-module (common secrets)
  #:use-module (common self)
  #:use-module (common unattended-upgrades)
  #:use-module (common users)
  #:use-module (frastanato system secrets)
  #:export (frastanato-system))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      ("deploy" ,paul-ssh-key)
      (,paul ,gleidi-suse-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define frastanato-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "frastanato")

    (kernel linux)
    ;(kernel-loadable-modules (list nvidia-module))
    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd
                     file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list intel-microcode)
                     #:keyboard-layout keyboard-layout
                     #:linux-modules %base-initrd-modules
                     rest)))
    (firmware (cons* realtek-firmware atheros-firmware %base-firmware))

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
                             ;; HTTPS
                             "nss-certs"
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

                             "kodi"

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
              ;; File sharing
              (service transmission-daemon-service-type
                       (transmission-daemon-configuration
                        ;; Restrict access to the RPC ("control") interface

                        ;; Accept requests from this and other hosts on the
                        ;; local network
                        (rpc-whitelist-enabled? #t)
                        (rpc-whitelist '("::1" "127.0.0.1" "192.168.1.*"))

                        ;; Limit bandwidth use during work hours
                        (alt-speed-down (* 1024 2)) ;   2 MB/s
                        (alt-speed-up 512)          ; 512 kB/s

                        (alt-speed-time-enabled? #t)
                        (alt-speed-time-day 'weekdays)
                        (alt-speed-time-begin
                         (+ (* 60 8) 00)) ; 8:00 am
                        (alt-speed-time-end
                         (+ (* 60 (+ 12 5)) 00)))) ; 5:00 pm

              ;; Monitoring
              (service prometheus-node-exporter-service-type)

              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (network "host")))

              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (network "host")))

              ;; ;; Bonfire
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
              ;;             (file frastanato.yaml)))
              ;;           (secret-key-base
              ;;            (sops-secret
              ;;             (key '("bonfire" "secret_key_base"))
              ;;             (file frastanato.yaml)))
              ;;           (signing-salt
              ;;            (sops-secret
              ;;             (key '("bonfire" "signing_salt"))
              ;;             (file frastanato.yaml)))
              ;;           (encryption-salt
              ;;            (sops-secret
              ;;             (key '("bonfire" "encryption_salt"))
              ;;             (file frastanato.yaml)))))

              ;; (service oci-meilisearch-service-type
              ;;          (oci-meilisearch-configuration
              ;;           (network "host")
              ;;           (master-key
              ;;            meilisearch-key-secret)))

              ;; (service postgresql-service-type
              ;;          (postgresql-configuration
              ;;           (postgresql postgresql-13)))

              ;; (simple-service 'bonfire-postgresql-role
              ;;                 sops-secrets-postgresql-role-service-type
              ;;                 (list
              ;;                  (sops-secrets-postgresql-role
              ;;                   (password
              ;;                    postgres-password-secret)
              ;;                   (value
              ;;                    (postgresql-role
              ;;                     (name "bonfire")
              ;;                     (create-database? #t))))))

              ;; Misc

              (service network-manager-service-type)
              (service wpa-supplicant-service-type)

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
                                               #:expiration-days 30)

              (service qemu-binfmt-service-type
                       (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                              "arm"
                                                              "aarch64")))))

             ;; This is the default list of services we
             ;; are appending to.
             (modify-services %small-guix-server-services
               (delete dhcp-client-service-type)
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
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout keyboard-layout)))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "4d3ff686-809a-454d-8744-17f4ecd2adab"
                                    'btrfs))
                           (type "btrfs"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "EB17-1A0F"
                                         'fat32))
                           (type "vfat")) %base-file-systems))

    (swap-devices
     (list
      (swap-space
       ;; See https://wiki.archlinux.org/title/Btrfs#Swap_file
       ;; for swapfile on Btrfs
       (target "/swap/swapfile")
       (dependencies (filter (file-system-mount-point-predicate "/")
                             file-systems)))))))
