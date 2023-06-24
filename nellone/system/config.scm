(define-module (nellone system config)
  #:use-module (guix packages)
  #:use-module (gnu services spice)
  #:use-module (gnu)
  #:use-module (gnu system) ;for %sudoers-specification
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix locales)
  #:use-module (small-guix services base)
  #:use-module (small-guix services docker)
  #:use-module (small-guix services server)
  #:use-module (common unattended-upgrades)
  #:use-module (srfi srfi-1))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list (local-file "../../keys/guix/frastanato.pub")))

(define-public nellone-system
  (operating-system
    (kernel linux)
    ;; (initrd microcode-initrd)
    ;; (firmware (list linux-firmware))
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "en_US"))

    (host-name "virtual-nellone")

    (users (cons* (user-account
                    (name "myself")
                    (comment "Myself")
                    (group "users")
                    ;; Specify a SHA-512-hashed initial password.
                    (password (crypt "myself" "$6$abc"))
                    (home-directory "/home/myself")
                    (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))
                  %base-user-accounts))

    (packages (append (list small-guix-glibc-locales)
                      (map specification->package
                           '("curl"
                             "fd"
                             "git"
                             "jq"
                             "htop"
                             "ncdu"
                             "nss-certs"
                             "ripgrep"
                             "stow"
                             "tmux"
                             "vim")) %base-packages))

    (services
     (append (list (deployments-unattended-upgrades host-name)
                   (service spice-vdagent-service-type)
                   (simple-service 'nellone-oci-containers
                    oci-container-service-type
                    (list (oci-container-configuration
                           (image "nginx:latest")))))

             %small-guix-server-services))
    
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

nellone-system
