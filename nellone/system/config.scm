(define-module (nellone system config)
  #:use-module (guix packages)
  #:use-module (gnu)
  #:use-module (gnu system) ;for %sudoers-specification
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix locales)
  #:use-module (small-guix services base)
  #:use-module (small-guix services server)
  #:use-module (srfi srfi-1))

(use-service-modules avahi dbus networking ssh syncthing)

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list (local-file "../../keys/guix/frastanato.pub")))

(define-public nellone-system
  (operating-system
    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware))
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "en_US"))

    (host-name "nellone")

    (users (cons* (user-account
                    (name "orang3")
                    (comment "Giacomo Leidi")
                    (group "users")
                    (home-directory "/home/orang3")
                    (supplementary-groups '("wheel" "netdev" "audio" "video")))
                  %base-user-accounts))

    (packages (append (list small-guix-glibc-locales)
                      (map specification->package
                           '("curl" "git"
                             "docker"
                             "docker-cli"
                             "iptables"
                             "jq"
                             "htop"
                             "ncdu"
                             "nss-certs"
                             "stow"
                             "tmux"
                             "vim")) %base-packages))

    (services
     (append (modify-services %small-guix-server-services
               (guix-service-type config =>
                                  (guix-configuration (inherit config)
                                                      (authorized-keys (append
                                                                        %default-authorized-guix-keys
                                                                        authorized-guix-keys)))))
             (list (service syncthing-service-type
                            (syncthing-configuration (user "orang3")
                                                     (logflags 3)))

                   (service avahi-service-type)
                   (dbus-service) ;Needed by Avahi
                   
                   (service network-manager-service-type)
                   (service wpa-supplicant-service-type)))) ;Needed by NetworkManager
    
    (sudoers-file (plain-file "sudoers"
                              (string-append (plain-file-content
                                              %sudoers-specification)
                                             "\norang3 ALL=(ALL) NOPASSWD: ALL\n")))

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets (list "/boot/efi"))
                  (keyboard-layout keyboard-layout)))
    (swap-devices (list (uuid "3fc8688e-9a4b-4713-a4d5-796d87c28fd5")))
    (file-systems (cons* (file-system
                           (mount-point "/home")
                           (device (uuid
                                    "5f6383fc-1e53-4baa-b2ef-75c2c22eff75"
                                    'ext4))
                           (type "ext4"))
                         (file-system
                           (mount-point "/")
                           (device (uuid
                                    "3836b21b-9c07-42ba-a79f-cb320a24e096"
                                    'ext4))
                           (type "ext4"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "D0F8-E8D1"
                                         'fat32))
                           (type "vfat")) %base-file-systems))))
