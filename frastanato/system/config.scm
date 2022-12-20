(define-module (frastanato system config)
  #:use-module (gnu)
  #:use-module (gnu packages linux) ;for light, pipewire
  #:use-module (gnu packages wm) ;for swaylock
  #:use-module (gnu system linux-initrd) ;for %base-initrd-modules
  #:use-module (gnu system shadow) ;for user-group
  #:use-module (gnu services base) ;for mingetty-service-type
  #:use-module (gnu services desktop) ;for gnome-service-type
  #:use-module (gnu services sddm) ;for sddm-service-type
  #:use-module (gnu services xorg) ;for screen-locker-service
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages nvidia) ;for nvidia-module
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services sway)
  #:use-module (small-guix system desktop)
  #:use-module (frastanato system fs)
  #:use-module (frastanato system input)
  #:use-module (frastanato system services)
  #:export (frastanato-gnome-system frastanato-sway-system))

(define orang3-user
  (user-account
    (name "orang3")
    (comment "Giacomo Leidi")
    (group "users")
    (home-directory "/home/orang3")
    (supplementary-groups '("adbusers" ;for adb
                            "docker"
                            "libvirt" ;to use Gnome Boxes
                            "lp" ;for accessing D-Bus for bluetooth
                            "kvm"
                            "realtime"
                            "wheel"
                            "netdev"
                            "audio"
                            "video"))))
;; Maybe one day
;;(shell #~(string-append #$oil "/bin/osh"))

(define frastanato-system
  (operating-system
    (inherit small-guix-desktop-system)
    (keyboard-layout %frastanato-kl)
    (kernel linux)
    (kernel-loadable-modules (list nvidia-module))
    (initrd (lambda (file-systems . rest)
              (apply microcode-initrd
                     file-systems
                     #:initrd base-initrd
                     #:microcode-packages (list intel-microcode)
                     #:keyboard-layout keyboard-layout
                     #:linux-modules %base-initrd-modules
                     rest)))

    (firmware (cons* realtek-firmware atheros-firmware %base-firmware))

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/boot/efi"))
                  (keyboard-layout %frastanato-kl)))

    (mapped-devices %frastanato-mapped-devices)

    (file-systems %frastanato-file-systems)

    (swap-devices %frastanato-swap-devices)

    (host-name "frastanato")

    (users (cons* orang3-user %base-user-accounts))

    (services
     %frastanato-desktop-services)))

(define frastanato-sway-system
  (operating-system
    (inherit frastanato-system)
    (users (cons* (user-account
                    (inherit orang3-user)
                    (shell %sway-login-shell)) %base-user-accounts))
    (packages (append (map specification->package
                           '("wpa-supplicant-gui"

                             ;; Wayland
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
                             "qtwayland" ;Qt
                             
                             ;; Root permissions dialogs
                             "polkit-gnome"

                             ;; Wayland screen sharing
                             "xdg-desktop-portal-wlr"

                             ;; Theming
                             "gtk-engines"
                             "gsettings-desktop-schemas"
                             "qt5ct"

                             ;; Misc
                             "file-roller"
                             "gedit"
                             "evince"
                             "gnome-keyring"
                             "gnome-system-monitor"
                             "nautilus"))
                      (operating-system-packages frastanato-system)))
    (services
     (append (list (service gnome-keyring-service-type)
                   ;; udev rules
                   (udev-rules-service 'light light)
                   (udev-rules-service 'pipewire pipewire-0.3)

                   %sway-environment-service
                   (screen-locker-service swaylock "swaylock"))

             (modify-services %frastanato-desktop-services
               (mingetty-service-type config =>
                                      (mingetty-configuration (inherit config)
                                                              ;; Automatically login.
                                                              (auto-login
                                                               "orang3"))))))))
