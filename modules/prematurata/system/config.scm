(define-module (prematurata system config)
  #:use-module (gnu)
  #:use-module (gnu packages audio)          ;for bluez-alsa
  #:use-module (gnu packages backup)         ;for restic
  #:use-module (gnu packages linux)          ;for bluez
  #:use-module (gnu packages networking)     ;for blueman
  #:use-module (gnu services base)           ;for guix-daemon-service-type
  #:use-module (gnu services dbus)           ;for dbus-root-service-type
  #:use-module (gnu services desktop)        ;for gnome-service-type
  #:use-module (gnu services mcron)          ;for mcron-service-type
  #:use-module (gnu services networking)     ;for tor-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (gnu services vpn)            ;for wireguard-service-type
  #:use-module (gnu services xorg)           ;for set-xorg-configuration
  #:use-module (guix utils)                  ;for current-source-directory
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix packages scripts) ;for restic-bin
  #:use-module (small-guix services backup)
  #:use-module (sops secrets)
  #:use-module (sops services sops)
  #:use-module (common keys)
  #:use-module (common secrets)
  #:use-module (common self)
  #:use-module (common services desktop)
  #:use-module (common services unattended-upgrades)
  #:use-module (common system desktop)
  #:use-module (common system input)
  #:use-module (common users)
  #:export (prematurata-system))

(define authorized-guix-keys
  (list
   pinebook-guix-key))

(define prematurata.yaml
  (secrets-file "prematurata.yaml"))

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
          (specification "0 23 * * *")
          (included '("/root/.gnupg"
                      "/root/.config/rclone"
                      "/etc/ssh/ssh_host_rsa_key"
                      "/etc/ssh/ssh_host_rsa_key.pub"
                      "/etc/guix/signing-key.pub"
                      "/etc/guix/signing-key.sec"))
          (verbose? #t)))
       restic-repositories))

(define-public backup-home-jobs
  (map (lambda (repo)
         (restic-backup-job
          (restic restic-bin)
          (repository repo)
          (user (user-account-name paul-user))
          (password-file "/run/secrets/restic")
          ;; Every day at 21.
          (specification "0 21 * * *")
          (included (map (lambda (p) (string-append (user-account-home-directory paul-user) "/" p))
                         '(".age"
                           ".cert"
                           ".config/aerc/accounts.conf"
                           ".config/libvirt/qemu"
                           ".config/rclone"
                           ".config/guix/channels.scm"
                           ".guix-manifests"
                           ".gnupg"
                           ".icedove"
                           ".local/bin"
                           ".local/share/gnome-boxes/images"
                           ".local/share/JetBrains/Toolbox/.storage.json"
                           ".local/share/JetBrains/Toolbox/.securestorage"
                           ".mozilla"
                           ".thunderbird"
                           ".ssh"
                           "Biblioteca di calibre"
                           "Calibre Library"
                           "code"
                           "Android"
                           "AndroidStudioProjects"
                           "Documents"
                           "Downloads"
                           "Games"
                           "IdeaProjects"
                           "Music"
                           "nix-manifest.txt"
                           "Pictures"
                           "PycharmProjects"
                           "Sync"
                           "Uni")))
          (verbose? #t)))
       restic-repositories))

(define-public restic-prune-job
  ;; Run 'restic prune' at 21:02 every Sunday.
  #~(job "2 21 * * 7"
         (lambda ()
           (for-each
            (lambda (repo)
              (system* "sh" "-c" (string-append "RESTIC_PASSWORD=\"$(cat /run/secrets/restic)\"; export RESTIC_PASSWORD; "
                                                #$restic "/bin/restic"
                                                " -r " repo " --verbose prune")))
            restic-repositories))
         "restic-prune"))

(use-modules (oci services prometheus))
(define prematurata-system
  (operating-system
    (inherit common-desktop-system)

    (kernel linux)
    (kernel-arguments
     (cons* "resume=/dev/nvme0n1p2"        ;device that holds /swapfile
            "resume_offset=76988225"       ;offset of /swapfile on device
            %default-kernel-arguments))
    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd
                     file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list amd-microcode)
                     #:keyboard-layout common-kl
                     #:linux-modules %base-initrd-modules
                     rest)))

    (firmware (cons* realtek-firmware atheros-firmware amdgpu-firmware
                     %base-firmware))

    (host-name "prematurata")

    (users (cons* paul-user %base-user-accounts))

    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout common-kl)))

    (packages (append (list bluez bluez-alsa blueman)
                      (operating-system-packages common-desktop-system)))

    (services
     (append (list (service openssh-service-type
                            (openssh-configuration (x11-forwarding? #f)))

                   (deployments-unattended-upgrades host-name
                                                    #:expiration-days 14)

                   (service oci-blackbox-exporter-service-type
                            (oci-blackbox-exporter-configuration
                             (network "host")
                             (file
                              (plain-file "be.yml"
                                          "
scrape_configs:
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - http://prometheus.io    # Target to probe with http.
        - https://prometheus.io   # Target to probe with https.
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115  # The blackbox exporter's real hostname:port.\n"))))

                   (service oci-prometheus-service-type
                            (oci-prometheus-configuration
                             (network "host")
                             (prometheus-configuration
                              (global
                               (prometheus-global-configuration
                                (scrape-interval "30s")
                                (scrape-timeout "12s")))
                              (scrape-configs
                               (list
                                (prometheus-scrape-configuration
                                 (job-name "prometheus")
                                 (metrics-path "/metrics")
                                 (static-configs
                                  (list (prometheus-static-config
                                         (targets '("localhost:9090" "localhost:9115")))))))))))

                   (service restic-backup-service-type
                            (restic-backup-configuration
                             (jobs
                              (append backup-system-jobs
                                      backup-home-jobs))))

                   (service sops-secrets-service-type
                            (sops-service-configuration
                             (config sops.yaml)
                             (secrets
                              (list
                               restic-secret
                               (sops-secret
                                (key '("wireguard" "private"))
                                (file prematurata.yaml))))))

                   (service guix-publish-service-type
                            (guix-publish-configuration
                             (port 90798)
                             (host "0.0.0.0")
                             (advertise? #t)))

                   ;; Realtime features. Needed for supercollider.
                   ;; See https://guix.gnu.org/manual/devel/en/guix.html#index-realtime
                   (service pam-limits-service-type
                            (list
                             (pam-limits-entry "@realtime" 'both 'rtprio 99)
                             (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)))

                   (service tor-service-type)
                   (simple-service 'prematurata-cron-jobs
                                   mcron-service-type
                                   (list restic-prune-job))

                   (service qemu-binfmt-service-type
                            (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                                   "arm"
                                                                   "aarch64"))))

                                        ;(service tailscaled-service-type)

                   ;; (service wireguard-service-type
                   ;;          (wireguard-configuration
                   ;;           (private-key "/run/secrets/wireguard/private")
                   ;;           (addresses '("192.168.27.67/32"))
                   ;;           (peers
                   ;;            (list
                   ;;             (wireguard-peer
                   ;;              (name "iliadbox")
                   ;;              (endpoint "81.56.8.195:10455")
                   ;;              (public-key "rLewDD+/AlsVsAMq7ik5WjrBdbJHBMLyM7EZJAr4N1U=")
                   ;;              (allowed-ips '("192.168.27.64/27")))))))

                   (service bluetooth-service-type
                            (bluetooth-configuration
                             (auto-enable? #t)))

                   (simple-service 'blueman dbus-root-service-type
                                   (list blueman)))
             (modify-services %common-desktop-services
               (guix-service-type config =>
                                  (guix-configuration (inherit config)
                                                      (authorized-keys
                                                       (append
                                                        authorized-guix-keys
                                                        (guix-configuration-authorized-keys config))))))))

    ;; You can find out UUIDs with sudo lsblk -o +name,mountpoint,uuid .
    (mapped-devices (list (mapped-device
                           (source "/dev/nvme0n1p2")
                           (target "cryptroot")
                           (type (luks-device-mapping-with-options
                                  #:key-file "/crypto.key")))))

    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "btrfs")
                           (dependencies mapped-devices))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "16CE-D943"
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
