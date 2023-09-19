(define-module (prematurata system config)
  #:use-module (gnu)
  #:use-module (gnu packages audio)          ;for bluez-alsa
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
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services mcron)
  #:use-module (small-guix services desktop)
  #:use-module (small-guix system desktop)
  #:use-module (small-guix system input)
  #:use-module (common unattended-upgrades)
  #:use-module (common users)
  #:export (prematurata-system))

(define authorized-guix-keys
  (list (local-file "../../keys/guix/pinebook-armbian.key")))

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

                   (deployments-unattended-upgrades host-name)

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

                   (service qemu-binfmt-service-type
                            (qemu-binfmt-configuration (platforms (lookup-qemu-platforms
                                                                   "arm"
                                                                   "aarch64"))))

                   (service wireguard-service-type
                     (wireguard-configuration
                      (private-key (plain-file "private.key"
                                               "wCvDLACjjRtbQzNgj08PvnSwWm56wGfzvBfkRQC0Hkk="))
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

    ;; You can find out this UUIDs with sudo lsblk -o +name,mountpoint,uuid .
    (mapped-devices (list (mapped-device
                            (source (uuid
                                     "808fce73-23ea-4fbf-b7a4-cf584279b276"))
                            (target "cryptroot")
                            (type luks-device-mapping))))

    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "btrfs")
                           (dependencies mapped-devices))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "720D-04C0"
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
