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
  #:use-module (small-guix services desktop)
  #:use-module (small-guix system desktop)
  #:use-module (small-guix system input)
  #:use-module (sops secrets)
  #:use-module (sops services sops)
  #:use-module (common unattended-upgrades)
  #:use-module (common users)
  #:export (prematurata-system))

(define deployments-root
  (dirname (dirname (current-source-directory))))

(define authorized-guix-keys
  (list
   (local-file
    (string-append deployments-root "/keys/guix/pinebook-armbian.key"))))

(define sops.yaml
  (local-file (string-append deployments-root "/.sops.yaml")
              "sops.yaml"))

(define (secrets-file file-name)
  (local-file (string-append deployments-root "/secrets/" file-name)))

(define common.yaml
  (secrets-file "common.yaml"))

(define prematurata.yaml
  (secrets-file "prematurata.yaml"))

(define-public backup-system-job
  ;; Run 'restic' at 23:00 every day.
  #~(job "0 23 * * *"
         (lambda ()
           (let ((repos '("rclone:onedrive:backup/restic"
                          "rclone:nasa-ftp:backup/restic")))
             (for-each
              (lambda (repo)
                (system* "sh" "-c" (string-append "RESTIC_PASSWORD=\"$(cat /run/secrets/restic)\"; export RESTIC_PASSWORD; "
                                                  #$restic "/bin/restic"
                                                  " -r " repo " --verbose backup /root/.gnupg /root/.config/rclone /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub /etc/guix/signing-key.pub /etc/guix/signing-key.sec")))
              repos)))
         "restic-system-backup"))

(define-public restic-prune-job
  ;; Run 'restic prune' at 21:02 every Sunday.
  #~(job "2 21 * * 7"
         (lambda ()
           (let ((repos '("rclone:onedrive:backup/restic"
                          "rclone:nasa-ftp:backup/restic")))
             (for-each
              (lambda (repo)
                (system* "sh" "-c" (string-append "RESTIC_PASSWORD=\"$(cat /run/secrets/restic)\"; export RESTIC_PASSWORD; "
                                                  #$restic "/bin/restic"
                                                  " -r " repo " --verbose prune")))
              repos)))
         "restic-prune"))

(define prematurata-system
  (operating-system
    (inherit small-guix-desktop-system)

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
                     #:keyboard-layout small-guix-kl
                     #:linux-modules %base-initrd-modules
                     rest)))

    (firmware (cons* realtek-firmware atheros-firmware amdgpu-firmware
                     %base-firmware))

    (host-name "prematurata")

    (users (cons* paul-user %base-user-accounts))

    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout small-guix-kl)))

    (packages (append (list bluez bluez-alsa blueman)
                      (operating-system-packages small-guix-desktop-system)))

    (services
     (append (list (service openssh-service-type
                            (openssh-configuration (x11-forwarding? #f)))

                   (deployments-unattended-upgrades host-name
                                                    #:expiration-days 14)

                   (service sops-secrets-service-type
                            (sops-service-configuration
                             (config sops.yaml)
                             (secrets
                              (list
                               (sops-secret
                                (key '("restic"))
                                (user "paul")
                                (file common.yaml))
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
                                   (list backup-system-job
                                         restic-prune-job))

                   (service qemu-binfmt-service-type
                            (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                                   "arm"
                                                                   "aarch64"))))

                   (service wireguard-service-type
                            (wireguard-configuration
                             (private-key "/run/secrets/wireguard/private")
                             (addresses '("192.168.27.67/32"))
                             (peers
                              (list
                               (wireguard-peer
                                (name "iliadbox")
                                (endpoint "81.56.8.195:10455")
                                (public-key "rLewDD+/AlsVsAMq7ik5WjrBdbJHBMLyM7EZJAr4N1U=")
                                (allowed-ips '("192.168.27.64/27")))))))

                   (service bluetooth-service-type
                            (bluetooth-configuration
                             (auto-enable? #t)))

                   (simple-service 'blueman dbus-root-service-type
                                   (list blueman)))
             (modify-services %small-guix-desktop-services
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
