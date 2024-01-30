;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (frastanato system config)
  #:use-module (gnu)
  #:use-module (gnu packages admin) ;for shadow
  #:use-module (gnu services monitoring)     ;for prometheus-node-exporter-service-type
  #:use-module (gnu services networking)     ;for network-manager-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (sops secrets)
  #:use-module (sops services sops)
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

(define frastanato.yaml
  (secrets-file "frastanato.yaml"))

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

                             ;; Network administration
                             "bind"
                             "bind:utils"
                             "tcpdump"

                             ;; Btrfs
                             "btrfs-progs"
                             "compsize"
                             "restic"
                             "rclone"
                             "emacs"
                             "ripgrep"))
                      (list common-deploy-scripts)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list
              (service network-manager-service-type)
              (service wpa-supplicant-service-type)

              (service sops-secrets-service-type
                       (sops-service-configuration
                        (config sops.yaml)))

              ;; Prometheus node exporter
              (service prometheus-node-exporter-service-type)
              ;; Prometheus OCI backed Shepherd service
              (service oci-prometheus-service-type
                       (oci-prometheus-configuration
                        (network "host")))
              ;; Grafana OCI backed Shepherd service
              (service oci-grafana-service-type
                       (oci-grafana-configuration
                        (network "host")))

              ;; (service oci-meilisearch-service-type
              ;;          (oci-meilisearch-configuration
              ;;           (master-key
              ;;            (sops-secret
              ;;             (key '("meilisearch" "master"))
              ;;             (file frastanato.yaml)))))

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
