;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2021, 2022, 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common system desktop)
  #:use-module (gnu)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages vpn)
  #:use-module (gnu system)
  #:use-module (gnu system nss)
  #:use-module (small-guix packages gnome)
  #:use-module (common locales)
  #:use-module (common services desktop)
  #:use-module (common system input)
  #:export (common-desktop-system))

(define common-desktop-system
  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout common-kl)

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/boot/efi"))
                  (keyboard-layout common-kl)))

    (file-systems (list (file-system
                          (mount-point "/")
                          (device "/dev/fake")
                          (type "ext4"))))

    (host-name "common-host")

    (users %base-user-accounts)

    (groups (append %base-groups
                    (list
                          ;; This group is required by ddcutil.
                          (user-group
                            (system? #t)
                            (name "i2c"))
                          ;; This group is required by some real time applications,
                          ;; such as SuperCollider.
                          (user-group
                            (system? #t)
                            (name "realtime")))))

    (packages (append (list gnome-browser-connector common-glibc-locales)
                      (map specification->package+output
                           (list "wireguard-tools"
                                 "brillo"

                                 "ncurses" ;for the search path

                                 ;; Backup
                                 "restic"
                                 "rclone"
                                 
                                 ;; Wayland
                                 "pipewire"
                                 "waypipe"
                                 "xdg-desktop-portal"
                                 "xdg-desktop-portal-gtk"

                                 ;; Audio
                                 "alsa-utils"
                                 "alsa-plugins"
                                 "gst-plugins-good"
                                 ;; Standard FreeDesktop directory paths
                                 "xdg-user-dirs"
                                 "xdg-utils"
                                 ;; Nix package manager
                                 "nix"
                                 ;; HTTPS
                                 "nss-certs"
                                 ;; User mounts
                                 "gvfs"
                                 ;; Fonts
                                 "font-awesome" ;For emacs-all-the-icons?
                                 "font-dejavu"
                                 "font-gnu-freefont"
                                 "font-ghostscript"

                                 ;; Filesystems
                                 "ntfs-3g"

                                 ;; External Monitors
                                 "ddcutil"
                                 "ddcui"

                                 ;;OpenGPG
                                 "seahorse"
                                 "gnupg"
                                 "pinentry"
                                 "pinentry-tty"
                                 "pinentry-gtk2"
                                 "pinentry-gnome3"

                                 ;; Misc
                                 "ristretto"
                                 "lsof"
                                 "jq"
                                 "ncdu"
                                 "tree"

                                 ;; Network administration
                                 "bind"
                                 "bind:utils"
                                 "tcpdump"

                                 ;; Dictionaries
                                 "hunspell-dict-it-it"
                                 "hunspell-dict-en"

                                 "gnome-boxes"
                                 ;; Gnome Extensions
                                 "gnome-user-share"
                                 "gnome-shell-extension-clipboard-indicator"
                                 "gnome-shell-extension-gsconnect"
                                 "rygel"

                                 ;; Btrfs
                                 "btrfs-progs"
                                 "compsize"

                                 ;; Hardware
                                 "solaar"

                                 "virt-manager"))
                      %base-packages))

    (services
     %common-desktop-services)

    ;; Allow resolution of '.local' host names with mDNS.
    (name-service-switch %mdns-host-lookup-nss)))
