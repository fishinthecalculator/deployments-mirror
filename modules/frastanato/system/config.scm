;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (frastanato system config)
  #:use-module (gnu)
  #:use-module (gnu packages admin) ;for shadow
  #:use-module (gnu packages databases)      ;for postgresql-13
  #:use-module (gnu services cuirass)        ;for transmission-service-type
  #:use-module (gnu services databases)      ;for postgresql-service-type
  #:use-module (gnu services file-sharing)   ;for transmission-service-type
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for network-manager-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (sops secrets)
  #:use-module ((sops services databases) #:prefix sops:)
  #:use-module (sops services sops)
  #:use-module (oci services bonfire)
  #:use-module (oci services grafana)
  #:use-module (oci services meilisearch)
  #:use-module (oci services prometheus)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages nvidia) ;for nvidia-module
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix packages scripts) ;for restic-bin
  #:use-module (small-guix services backup)
  #:use-module (common keys)
  #:use-module (common scripts)
  #:use-module (common secrets)
  #:use-module (common self)
  #:use-module (common services server)
  #:use-module (common services unattended-upgrades)
  #:use-module (common users)
  #:use-module (frastanato system secrets)
  #:export (frastanato-system))

(define restic-repositories
  '("rclone:onedrive:backup/restic"
    "rclone:nasa-ftp:backup/restic"))

(define-public backup-system-jobs
  (map (lambda (repo)
         (restic-backup-job
          (restic restic-bin)
          (repository repo)
          (password-file "/run/secrets/restic")
          ;; Every day at 23.
          (schedule "0 23 * * *")
          (files '("/root/.gnupg"
                   "/root/.config/rclone"
                   "/etc/ssh/ssh_host_rsa_key"
                   "/etc/ssh/ssh_host_rsa_key.pub"
                   "/etc/guix/signing-key.pub"
                   "/etc/guix/signing-key.sec"))
          (verbose? #t)))
       restic-repositories))

(define authorized-ssh-keys
  (let ((paul (user-account-name paul-user)))
    ;; List of authorized SSH keys.
    `((,paul ,paul-ssh-key)
      (,paul ,termux-ssh-key)
      ("deploy" ,paul-ssh-key)
      (,paul ,gleidi-suse-ssh-key))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define %cuirass-period
  (* 24 (* 60 60)))

(define %cuirass-specs
  #~(list
     (specification
      (name "mobilizon-reshare_core-updates")
      (period #$%cuirass-period)
      (build '(packages
               "mobilizon-reshare@0.3.6"
               "mobilizon-reshare@0.3.5"
               "mobilizon-reshare@0.3.2"
               "mobilizon-reshare@0.3.1"
               "mobilizon-reshare@0.3.0"
               "mobilizon-reshare@0.1.0"))
      (channels
       (list (channel
              (name 'mobilizon-reshare)
              (url "https://git.sr.ht/~fishinthecalculator/mobilizon-reshare-guix")
              (branch "main"))
             (channel
              (name 'guix)
              (url "https://git.savannah.gnu.org/git/guix.git")
              (branch
               "core-updates")
              (introduction
               (make-channel-introduction
                "afb9f2752315f131e4ddd44eba02eed403365085"
                (openpgp-fingerprint
                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))))
     (specification
      (name "ocui_core-updates")
      (period #$%cuirass-period)
      (build '(packages "ocui.git"))
      (channels
       (list (channel
              (name 'ocui)
              (url "https://github.com/fishinthecalculator/ocui.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "10ed759852825149eb4b08c9b75777111a92048e"
                (openpgp-fingerprint
                 "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
             (channel
              (name 'guix)
              (url "https://git.savannah.gnu.org/git/guix.git")
              (branch
               "core-updates")
              (introduction
               (make-channel-introduction
                "afb9f2752315f131e4ddd44eba02eed403365085"
                (openpgp-fingerprint
                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))))
     (specification
      (name "mobilizon-reshare_python-team")
      (period #$%cuirass-period)
      (build '(packages
               "mobilizon-reshare@0.3.6"
               "mobilizon-reshare@0.3.5"
               "mobilizon-reshare@0.3.2"
               "mobilizon-reshare@0.3.1"
               "mobilizon-reshare@0.3.0"
               "mobilizon-reshare@0.1.0"))
      (channels
       (list (channel
              (name 'mobilizon-reshare)
              (url "https://git.sr.ht/~fishinthecalculator/mobilizon-reshare-guix")
              (branch "main"))
             (channel
              (name 'guix)
              (url "https://git.savannah.gnu.org/git/guix.git")
              (branch
               "python-team")
              (introduction
               (make-channel-introduction
                "afb9f2752315f131e4ddd44eba02eed403365085"
                (openpgp-fingerprint
                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))))
     (specification
      (name "ocui_python-team")
      (period #$%cuirass-period)
      (build '(packages "ocui.git"))
      (channels
       (list (channel
              (name 'ocui)
              (url "https://github.com/fishinthecalculator/ocui.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "10ed759852825149eb4b08c9b75777111a92048e"
                (openpgp-fingerprint
                 "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
             (channel
              (name 'guix)
              (url "https://git.savannah.gnu.org/git/guix.git")
              (branch
               "python-team")
              (introduction
               (make-channel-introduction
                "afb9f2752315f131e4ddd44eba02eed403365085"
                (openpgp-fingerprint
                 "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))))
     (specification
      (name "mobilizon-reshare")
      (period #$%cuirass-period)
      (build '(packages
               "mobilizon-reshare@0.3.6"
               "mobilizon-reshare@0.3.5"
               "mobilizon-reshare@0.3.2"
               "mobilizon-reshare@0.3.1"
               "mobilizon-reshare@0.3.0"
               "mobilizon-reshare@0.1.0"))
      (channels
       (cons (channel
              (name 'mobilizon-reshare)
              (url "https://git.sr.ht/~fishinthecalculator/mobilizon-reshare-guix")
              (branch "main"))
             %default-channels)))
     (specification
      (name "ocui")
      (period #$%cuirass-period)
      (build '(packages "ocui.git"))
      (channels
       (cons (channel
              (name 'ocui)
              (url "https://github.com/fishinthecalculator/ocui.git")
              (branch "main")
              ;; Enable signature verification:
              (introduction
               (make-channel-introduction
                "10ed759852825149eb4b08c9b75777111a92048e"
                (openpgp-fingerprint
                 "97A2 CB8F B066 F894 9928  CF80 DE9B E0AC E824 6F08"))))
             %default-channels)))))

(define frastanato-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "frastanato")

    (kernel linux)
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
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "docker" "transmission")))
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
              ;; Cuirass
              (service cuirass-service-type
                       (cuirass-configuration
                        (host "0.0.0.0")
                        (port 8081)
                        (use-substitutes? #t)
                        (specifications %cuirass-specs)))

              ;; Backups
              (service restic-backup-service-type
                       (restic-backup-configuration
                        (jobs
                         (append backup-system-jobs))))

              ;; File sharing
              (service transmission-daemon-service-type
                       (transmission-daemon-configuration
                        ;; mkdir -pv /torrents-watchdir
                        ;; chown -Rv paul:users /torrents-watchdir
                        ;; chmod -v o+r /torrents-watchdir
                        (watch-dir-enabled? #t)
                        (watch-dir "/torrents-watchdir")
                        (peer-port 16383)

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

              ;; (service sops:postgresql-role-service-type
              ;;          (sops:postgresql-role-configuration
              ;;           (requirement '(sops-secrets))
              ;;           (roles
              ;;            (list (sops:postgresql-role
              ;;                   (name "bonfire")
              ;;                   (password-file "/run/secrets/postgres/bonfire")
              ;;                   (create-database? #t))))))

              (service postgresql-service-type
                       (postgresql-configuration
                        (postgresql postgresql-13)))

              ;; Misc

              (service network-manager-service-type)
              (service wpa-supplicant-service-type)

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)
                        (secrets
                         (list restic-secret
                               postgres-password-secret
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
             (modify-services %common-server-services
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
