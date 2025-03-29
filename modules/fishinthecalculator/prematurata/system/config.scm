(define-module (fishinthecalculator prematurata system config)
  #:use-module (gnu bootloader)              ;for bootloader-configuration
  #:use-module (gnu bootloader grub)         ;for grub-efi-bootloader
  #:use-module (gnu packages audio)          ;for bluez-alsa
  #:use-module (gnu packages bash)           ;for bash-minimal
  #:use-module (gnu packages backup)         ;for restic
  #:use-module (gnu packages linux)          ;for bluez
  #:use-module (gnu packages networking)     ;for blueman
  #:use-module (gnu packages shells)         ;for oils
  #:use-module ((gnu services)
                #:hide (delete))             ;for modify-services
  #:use-module (gnu services base)           ;for guix-daemon-service-type
  #:use-module ((gnu services backup)        ;for restic-backup-service-type
                #:prefix mainline:)
  #:use-module (gnu services dbus)           ;for dbus-root-service-type
  #:use-module (gnu services desktop)        ;for gnome-service-type
  #:use-module (gnu services guix)           ;for guix-home-service-type
  #:use-module (gnu services networking)     ;for tor-service-type
  #:use-module (gnu services shepherd)       ;for shepherd-root-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (gnu services vpn)            ;for wireguard-service-type
  #:use-module (gnu services xorg)           ;for gdm-service-type
  #:use-module (gnu system)                  ;for operating-system
  #:use-module (gnu system accounts)         ;for user-account
  #:use-module (gnu system file-systems)     ;for file-system
  #:use-module (gnu system linux-initrd)     ;for base-initrd
  #:use-module (gnu system mapped-devices)   ;for mapped-device
  #:use-module (gnu system pam)              ;for pam-limits-entry
  #:use-module (gnu system shadow)           ;for %base-user-accounts
  #:use-module (guix gexp)                   ;for #~ and #$
  #:use-module (guix packages)               ;for package-source
  #:use-module (guix utils)                  ;for current-source-directory
  #:use-module (nongnu packages messaging)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix packages fwupd) ;for fwupd-nonfree
  #:use-module (small-guix packages scripts) ;for restic-bin
  #:use-module (small-guix packages moolticute) ;for my-moolticute
  #:use-module (small-guix home services backup) ;for home-restic-backup-service-type
  #:use-module ((small-guix services backup-timers)) ;for Shepherd timers restic-backup-service-type
  #:use-module (small-guix services fwupd) ;for fwupd-service-type
  #:use-module (sops secrets)
  #:use-module (sops services sops)
  #:use-module (fishinthecalculator common backup)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common home fishinthecalculator home-configuration)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common self)
  #:use-module (fishinthecalculator common services desktop)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common system desktop)
  #:use-module (fishinthecalculator common system input)
  #:use-module (fishinthecalculator common users)
  #:use-module (srfi srfi-1)
  #:export (prematurata-system))

(define paul-user
  (user-account (inherit paul-user)
                ;; Some things still break.
                ;; ;; Use OSH shell by default
                ;; (shell
                ;;  (file-append oils "/bin/osh"))
                (supplementary-groups
                 (cons "cgroup"
                      (delete "docker"
                               (user-account-supplementary-groups
                                paul-user))))))

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))

(define authorized-guix-keys
  (list
   frastanato-guix-key))

(define prematurata.yaml
  (secrets-file "prematurata.yaml"))

(define guix-home-environments
  (list
   `(,(user-account-name paul-user) ,fishinthecalculator-home-environment)))

(define-public backup-system-jobs
  (map (lambda (repo)
         (mainline:restic-backup-job
          (name (list-ref (string-split repo #\:) 1))
          (restic restic-bin)
          (repository repo)
          (password-file "/run/secrets/restic")
          (requirement '(sops-secrets))
          ;; Every day at 23.
          (schedule "0 23 * * *")
          (files '("/crypto.cpio"
                   "/crypto.key"
                   "/root/.gnupg"
                   "/root/.config/rclone"
                   "/etc/ssh/ssh_host_rsa_key"
                   "/etc/ssh/ssh_host_rsa_key.pub"
                   "/etc/guix/signing-key.pub"
                   "/etc/guix/signing-key.sec"))
          (verbose? #t)))
       %restic-repositories))

(define-public restic-prune-jobs
  ;; Run 'restic prune' at 21:02 every Sunday.
  (map
   (lambda (repo)
     (shepherd-service (provision `(,(string->symbol (string-append "restic-prune-" repo))))
                       (requirement '(user-processes file-systems))
                       (documentation
                        (string-append "Run @command{restic prune} on " repo " repo."))
                       (modules '((shepherd service timer)))
                       (start
                        #~(make-timer-constructor
                           (cron-string->calendar-event "2 21 * * 6")
                           (command
                            (list
                             (string-append #+bash-minimal "/bin/bash")
                             "-l" "-c"
                             (string-append
                              "restic-guix prune " #$(list-ref (string-split repo #\:) 1)))
                            #:environment-variables
                            (list "HOME=/root"))))
                       (stop
                        #~(make-timer-destructor))
                       (actions (list (shepherd-action
                                       (name 'trigger)
                                       (documentation
                                        (string-append "Manually trigger a @command{restic prune} on " repo " repo,
without waiting for the scheduled time."))
                                       (procedure #~trigger-timer))))))
   %restic-repositories))

(define %common-desktop-system
  (common-desktop-system subuids subgids))
(define %common-desktop-services
  (common-desktop-services subuids subgids))
(define prematurata-system
  (operating-system
    (inherit %common-desktop-system)

    (kernel linux)
    (kernel-arguments
     (cons* "resume=/dev/nvme0n1p2"     ;device that holds /swapfile
            "resume_offset=76988225"    ;offset of /swapfile on device
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

    ;; Operating system with encrypted boot partition
    ;; see https://guix.gnu.org/en/manual/devel/en/guix.html#index-bootloader_002dconfiguration
    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout common-kl)
                 ;; guix shell cpio -- sh -c 'echo /crypto.key | cpio -oH newc > /crypto.cpio'
                 ;; chmod 0000 /crypto.cpio
                 ;; Load the initrd with a key file
                 (extra-initrd "/crypto.cpio")))

    (packages (append (list bluez bluez-alsa blueman
                            my-moolticute-0.44.19)
                      (operating-system-packages %common-desktop-system)))

    (services
     (append (list (service openssh-service-type
                            (openssh-configuration (x11-forwarding? #f)))

                   (service guix-home-service-type
                            guix-home-environments)

                   (deployments-unattended-upgrades host-name
                                                    #:expiration-days 14)

                   (service restic-backup-service-type
                            (restic-backup-configuration
                             (jobs backup-system-jobs)))

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
                             (port 65535)
                             (host "0.0.0.0")
                             (advertise? #t)))

                   ;; Realtime features. Needed for supercollider.
                   ;; See https://guix.gnu.org/manual/devel/en/guix.html#index-realtime
                   (simple-service 'supercollider-pam-limits
                                   pam-limits-service-type
                                   (list
                                    (pam-limits-entry "@realtime" 'both 'rtprio 99)
                                    (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)))

                   (service tor-service-type)
                   (simple-service 'prematurata-timers
                                   shepherd-root-service-type
                                   restic-prune-jobs)

                   (service qemu-binfmt-service-type
                            (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                                   "arm"
                                                                   "aarch64"))))

                   (service fwupd-service-type
                            (fwupd-configuration
                             (fwupd fwupd-nonfree)))

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

                   (service common-unload-service-type
                            '("cups"
                              "fwupd"
                              "guix-publish"
                              "libvirtd"
                              "nix-daemon"
                              "updatedb"))

                   (simple-service 'blueman-dbus dbus-root-service-type
                                   (list blueman))

                   ;; cache some binary sources
                   (simple-service 'cache-binaries
                                   gc-root-service-type
                                   (map package-source
                                         (list element-desktop signal-desktop zoom))))
             (modify-services %common-desktop-services

               (gdm-service-type config =>
                                  (gdm-configuration (inherit config)
                                                     (debug? #t)))
               (guix-service-type config =>
                                  (guix-configuration (inherit config)
                                                      (discover? #t)
                                                      (authorized-keys
                                                       (append
                                                        authorized-guix-keys
                                                        (guix-configuration-authorized-keys config))))))))

    ;; You can find out UUIDs with sudo lsblk -o +name,mountpoint,uuid .
    (mapped-devices (list (mapped-device
                           (source "/dev/nvme0n1p2")
                           (target "cryptroot")
                           (type (luks-device-mapping-with-options
                                  ;; All the following must be run as root
                                  ;; DEST="/crypto.key"
                                  ;; dd bs=512 count=4 if=/dev/random of=$DEST iflag=fullblock
                                  ;; guix shell openssl -- openssl genrsa -out $DEST 4096
                                  ;; chmod -v 0400 $DEST
                                  ;; chown root:root $DEST
                                  #:key-file "/crypto.key")))))

    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "btrfs")
                           (dependencies mapped-devices))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "C2D8-5F4F"
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
