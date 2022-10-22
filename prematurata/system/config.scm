(define-module (prematurata system config)
  #:use-module (gnu)
  #:use-module (gnu packages audio)          ;for bluez-alsa
  #:use-module (gnu packages linux)          ;for bluez
  #:use-module (gnu packages networking)     ;for blueman
  #:use-module (gnu services dbus)           ;for dbus-root-service-type
  #:use-module (gnu services desktop)        ;for gnome-service-type
  #:use-module (gnu services ssh)            ;for ssh-service-type
  #:use-module (gnu services virtualization) ;for qemu-binfmt-service-type
  #:use-module (gnu services xorg)           ;for set-xorg-configuration
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services desktop)
  #:use-module (small-guix system desktop)
  #:use-module (small-guix system input)
  #:export (prematurata-system))

(define orang3-user
  (user-account
   (name "orang3")
   (comment "Giacomo Leidi")
   (group "users")
   (home-directory "/home/orang3")
   (supplementary-groups
    '("adbusers"                        ;for adb
      "docker"
      "lp"                              ;for accessing D-Bus for bluetooth
      "libvirt"
      "kvm"
      "realtime"
      "plugdev"                         ;for solaar
      "wheel" "netdev" "audio" "video"))))
   ;; Maybe one day
   ;;(shell #~(string-append #$oil "/bin/osh"))

(define prematurata-system
  (operating-system
    (inherit small-guix-desktop-system)

    (kernel linux)
    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list amd-microcode)
                     #:keyboard-layout small-guix-kl
                     #:linux-modules %base-initrd-modules
                     rest)))

    (firmware (cons* realtek-firmware
                     atheros-firmware
                     amdgpu-firmware
                     %base-firmware))

    (host-name "prematurata")

    (users (cons* orang3-user
                  %base-user-accounts))

    (bootloader
      (bootloader-configuration
        (bootloader grub-efi-bootloader)
        (targets (list "/boot/efi"))
        (keyboard-layout small-guix-kl)))

    (packages
     (append
      (list bluez
            bluez-alsa
            blueman)
      (operating-system-packages small-guix-desktop-system)))

    (services
     (append
      (list (service openssh-service-type
             (openssh-configuration
               (x11-forwarding? #f)))

            ;; Realtime features. Needed for supercollider.
            ;; See https://guix.gnu.org/manual/devel/en/guix.html#index-realtime
            (pam-limits-service
             (list
              (pam-limits-entry "@realtime" 'both 'rtprio 99)
              (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)))

            (service tor-service-type)

            (service qemu-binfmt-service-type
                     (qemu-binfmt-configuration
                      (platforms (lookup-qemu-platforms "arm" "aarch64"))))

            (bluetooth-service #:auto-enable? #t)

            (simple-service 'blueman dbus-root-service-type (list blueman)))
      %small-guix-desktop-services))

    (swap-devices
      (list (swap-space
              (target
                (uuid "053b3b77-3e05-4c22-9d6d-2a57343fa00a")))))

    (mapped-devices
      (list (mapped-device
              (source
                (uuid "bdb12e1c-92e4-4a6f-9dd9-4592192342d3"))
              (target "cryptroot")
              (type luks-device-mapping))))

    (file-systems
      (cons* (file-system
               (mount-point "/")
               (device "/dev/mapper/cryptroot")
               (type "btrfs")
               (dependencies mapped-devices))
             (file-system
               (mount-point "/boot/efi")
               (device (uuid "720D-04C0" 'fat32))
               (type "vfat"))
             %base-file-systems))))
