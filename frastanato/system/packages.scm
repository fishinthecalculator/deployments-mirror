(define-module (frastanato system packages)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (small-guix locales)
  #:export (%frastanato-packages))

(define %frastanato-packages
  (append
   (list small-guix-glibc-locales)
   (map specification->package+output
        (list
         ;; Pulseaudio
         "pulseaudio"
         "pavucontrol"

         "ncurses"            ;; for the search path

         ;; Wayland
         "pipewire"
         "xdg-desktop-portal"

         ;; JACK
         "alsa-utils"
         "alsa-plugins"
         "alsa-plugins:jack"
         "jack"
         "qjackctl"
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
         "font-awesome" ;; For emacs-all-the-icons?
         "font-dejavu"
         "font-gnu-freefont"
         "font-ghostscript"

         ;; External Monitors
         "ddcutil"

         ;; Misc
         "ristretto"
         "lsof"
         "jq"
         "ncdu"

         ;; Network administration
         "bind"
         "bind:utils"
         "tcpdump"

         ;;Dictionaries
         "hunspell-dict-it-it"
         "hunspell-dict-en"

         ;; Btrfs
         "btrfs-progs"
         "compsize"

         ;; Network Manager OpenVPN plugin
         "network-manager-openvpn"))
   %base-packages))
