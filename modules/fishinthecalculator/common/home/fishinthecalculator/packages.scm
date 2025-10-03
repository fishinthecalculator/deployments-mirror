(define-module (fishinthecalculator common home fishinthecalculator packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages python)
  #:use-module (nongnu packages chrome)
  #:use-module (nongnu packages compression)
  #:use-module (nongnu packages editors)
  #:use-module (nongnu packages messaging)
  #:use-module (nongnu packages password-utils)
  #:use-module (nongnu packages productivity)
  #:use-module (small-guix packages guile-xyz)
  #:use-module (small-guix packages moar)
  #:use-module (small-guix packages scripts)
  #:use-module (small-guix packages scheme-lsp)
  #:use-module (small-guix utils)
  #:use-module (fishinthecalculator common scripts)
  #:use-module (fishinthecalculator common home fishinthecalculator const))

(define-public fishinthecalculator-scripts
  (make-scripts-package "fishinthecalculator-scripts"
                        %home-scripts-dir
                        (list bash-minimal coreutils python)
                        "A set of utility scripts"
                        "This package provides some utility scripts."
                        "https://codeberg.org/fishinthecalculator/guix-deployments.git"
                        license:gpl3+
                        #:propagated-inputs (list common-deploy-scripts)
                        #:version "0.1.1"))

(define-public fishinthecalculator-packages
  (append (list anytype
                bitwarden-desktop
                moar
                google-chrome-stable
                element-desktop
                signal-desktop
                common-deploy-scripts
                unrar
                guile-lsp-server.git
                zoom
                guile-hall.git
                vscodium
                guile-3.0
                fishinthecalculator-scripts
                guix-dev-tools)
          (map specification->package+output
               (list "aerc"
                     "arc-theme"
                     "bat"
                     "btop"
                     "calibre"
                     "catimg"
                     "clipman"
                     "codeberg-cli"
                     "curl"
                     "dante"
                     "dino"
                     "direnv"
                     "fd"
                     "file"
                     "flatpak"
                     "font-adobe-source-code-pro"
                     "font-awesome"
                     "font-fira-code"
                     "font-fira-mono"
                     "font-fira-sans"
                     "font-gnu-freefont"
                     "font-gnu-unifont"
                     "font-google-roboto"
                     "forgejo-cli"
                     "foot"
                     "git"
                     "git:credential-libsecret"
                     "git:send-email"
                     "gnome-authenticator"
                     "gnome-shell-extension-appindicator"
                     "gnome-shell-extension-dash-to-panel"
                     "gparted"
                     "guile-colorized"
                     "guile-readline"
                     "hexchat"
                     "imagemagick"
                     "libnotify"
                     "lolcat"
                     "nicotine"
                     "nmap"
                     "papirus-icon-theme"
                     "python-wrapper"
                     "qbittorrent"
                     "rhythmbox"
                     "ripgrep"
                     "rsync"
                     "sl"
                     "syncthing"
                     ;"telegram-desktop"
                     "tmux"
                     "unzip"
                     "vim"
                     "vlc"
                     "w3m"
                     "wget"
                     "xlsfonts"
                     "xrandr"
                     "xset"
                     "zip"))))
