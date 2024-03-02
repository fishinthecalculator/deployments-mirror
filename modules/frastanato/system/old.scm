(define-module (frastanato system old)
  #:use-module (gnu)
  #:use-module (gnu packages linux) ;for light, pipewire
  #:use-module (gnu packages wm) ;for swaylock
  #:use-module (gnu system linux-initrd) ;for %base-initrd-modules
  #:use-module (gnu system shadow) ;for user-group
  #:use-module (gnu services base) ;for mingetty-service-type
  #:use-module (gnu services desktop) ;for gnome-service-type
  #:use-module (gnu services xorg) ;for screen-locker-service
  #:use-module (nongnu packages linux)
  #:use-module (nongnu packages nvidia) ;for nvidia-module
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix services sway)
  #:use-module (common system desktop)
  #:use-module (common users)
  #:use-module (frastanato system config)
  #:export (frastanato-sway-system))

(define frastanato-sway-system
  (operating-system
    (inherit frastanato-system)
    (users (cons* (user-account
                    (inherit paul-user)
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
                                                               (user-name paul-user)))))))))
