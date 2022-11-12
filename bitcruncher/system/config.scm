(define-module (bitcruncher system config)
  #:use-module (gnu)
  #:use-module (gnu services networking)
  #:use-module (gnu services syncthing)
  #:use-module (gnu system) ;for %sudoers-specification
  #:use-module (small-guix locales)
  #:use-module (small-guix self)
  #:use-module (small-guix services server)
  #:use-module (small-guix services sway))

(use-package-modules bootloaders)

(define-public bitcruncher-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "it"))
    (host-name "bitcruncher")

    (users (cons* (user-account
                    (name "orang3")
                    (comment "Giacomo")
                    (group "users")
                    (home-directory "/home/orang3")
                    (supplementary-groups '("wheel" "netdev" "audio" "video"
                                            "docker"))
                    ;; Specify a SHA-512-hashed initial password.
                    (password (crypt "InitialPassword!" "$6$abc"))
                    (shell %sway-login-shell)) %base-user-accounts))

    (packages (append (list small-guix-glibc-locales)
                      (map specification->package+output
                           '("bind" "bind:utils"
                             "curl"
                             "git"
                             "docker"
                             "docker-compose"
                             "docker-cli"
                             "iptables"
                             "jq"
                             "htop"
                             "ncdu"
                             "net-tools"
                             "nss-certs"
                             "stow"
                             "tcpdump"
                             "tmux"
                             "vim"

                             ;; Sway packages
                             "sway"
                             "swaybg"
                             "swaylock"
                             "swayidle"
                             "wofi"
                             "waybar"
                             "wl-clipboard"
                             "gammastep" ;light Night
                             "mako" ;Notifications
                             "grim" ;Screenshots
                             "slurp" ;Select screen portion
                             "light" ;Screen brightness
                             "qtbase"
                             "qtwayland"
                             "polkit-gnome"
                             ;; Wayland screen sharing
                             "xdg-desktop-portal-wlr"
                             "gtk-engines"
                             "gsettings-desktop-schemas"
                             "qt5ct"
                             ;; Misc
                             "file-roller"
                             "gedit"
                             "evince"
                             "gnome-keyring"
                             "gnome-system-monitor"
                             "nautilus")) ;Qt))
                      
                      %base-packages))

    (services
     (append (modify-services %small-guix-server-services
               (mingetty-service-type config =>
                                      (mingetty-configuration (inherit config)
                                                              ;; Automatically login.
                                                              (auto-login
                                                               "orang3"))))
             (list
                   ;; udev rules
                   %sway-environment-service
                   (simple-service 'server-config etc-service-type
                                   (list `("server-config.scm" ,(file-append
                                                                 %small-guix-config-dir
                                                                 "/bitcruncher/system/config.scm")))))))
    ;; (service syncthing-service-type
    ;; (syncthing-configuration
    ;; (user "orang3")
    ;; (logflags 3)))
    
    (sudoers-file (plain-file "sudoers"
                              (string-append (plain-file-content
                                              %sudoers-specification)
                                             "\norang3 ALL=(ALL) NOPASSWD: ALL\n")))

    ;; Hardware dependent settings
    (bootloader (bootloader-configuration
                  (bootloader grub-bootloader)
                  (targets (list "/dev/sda"))
                  (keyboard-layout keyboard-layout)))

    (initrd-modules (append '("virtio_scsi") %base-initrd-modules))

    (mapped-devices (list (mapped-device
                            (source (uuid
                                     "262fe69a-eae7-45a6-915a-5df6a61b0417"))
                            (target "cryptroot")
                            (type luks-device-mapping))))

    (file-systems (cons* (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "6B76-5791"
                                         'fat32))
                           (type "vfat"))
                         (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "ext4")
                           (dependencies mapped-devices)) %base-file-systems))))

bitcruncher-system
