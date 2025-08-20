(define-module (fishinthecalculator skibidi system config)
  #:use-module (gnu)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages ssh)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop)
  #:use-module (gnu services guix)
  #:use-module (gnu services virtualization)
  #:use-module (gnu services xorg)
  #:use-module (gnu system accounts)
  #:use-module (nongnu packages firmware)    ;for fwupd-nonfree
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services fwupd) ;for fwupd-service-type
  #:use-module (fishinthecalculator common home fishinthecalculator home-configuration)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common self)
  #:use-module (fishinthecalculator common services desktop)
  #:use-module (fishinthecalculator common services unattended-upgrades)
  #:use-module (fishinthecalculator common services unload)
  #:use-module (fishinthecalculator common system desktop)
  #:use-module (fishinthecalculator common users)
  #:export (skibidi-system))

(define authorized-guix-keys
  (list
   prematurata-guix-key))

(define paul-user
  (user-account (inherit paul-user)
                ;; Some things still break.
                ;; ;; Use OSH shell by default
                ;; (shell
                ;;  (file-append oils "/bin/osh"))
                (supplementary-groups
                 (cons "cgroup"
                       (delete "realtime"
                               (delete "i2c"
                                       (delete "docker"
                                               (user-account-supplementary-groups
                                                paul-user))))))))

(define guix-home-environments
  (list
   `(,(user-account-name paul-user) ,framework-13-home-environment)))

(define subgids
  (list (subid-range (name (user-account-name paul-user)))))
(define subuids
  (list (subid-range (name (user-account-name paul-user)))))

(define %common-desktop-system
  (common-desktop-system subuids subgids))
(define %common-desktop-services
  (common-desktop-services subuids subgids))

(define skibidi-system
  (operating-system
    (inherit %common-desktop-system)

    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    (kernel linux)
    (kernel-arguments
     (cons* "resume=/dev/nvme0n1p2"     ;device that holds /swapfile
            "resume_offset=9245919"    ;offset of /swapfile on device
            %default-kernel-arguments))

    (firmware  (list linux-firmware))

    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd
                     file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list amd-microcode)
                     #:keyboard-layout keyboard-layout
                     #:linux-modules %base-initrd-modules
                     rest)))

    (host-name "skibidi")

    (users (cons* paul-user
                  %base-user-accounts))

    (packages (append (list bluez bluez-alsa blueman openssh)
                      (operating-system-packages %common-desktop-system)))

    (services
     (append (list (service guix-home-service-type
                            guix-home-environments)
                   (service bluetooth-service-type
                            (bluetooth-configuration
                             (auto-enable? #t)))
                   (service qemu-binfmt-service-type
                            (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                                   "arm"
                                                                   "aarch64"))))

                   (service fwupd-service-type
                            (fwupd-configuration
                             (fwupd fwupd-nonfree)))

                   (service common-unload-service-type
                            '("cups"
                              "fwupd"
                              "guix-publish"
                              "libvirtd"
                              "nix-daemon"
                              "updatedb"))

                   (simple-service 'blueman-dbus dbus-root-service-type
                                   (list blueman))

                   (deployments-unattended-upgrades host-name
                                                    #:expiration-days 14))

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
    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout keyboard-layout)))
    (mapped-devices (list (mapped-device
                           (source (uuid
                                    "80e77c30-1cdd-4a41-8bff-af97f682b8f5"))
                           (target "cryptroot")
                           (type luks-device-mapping))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "btrfs")
                           (dependencies mapped-devices))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "E567-7C61"
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
