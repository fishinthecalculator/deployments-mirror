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
                        "https://gitlab.com/orang3/guix-home"
                        license:gpl3+
                        #:propagated-inputs (list common-deploy-scripts)
                        #:version "0.1.0"))

(define-public fishinthecalculator-packages
  (append (list anytype
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
               (list "calibre"
                     "dino"
                     "aerc"
                     "w3m"
                     "dante"
                     "lolcat"
                     "bat"
                     "catimg"
                     "libnotify"
                     "vlc"
                     "telegram-desktop"
                     "foot"
                     "imagemagick"
                     "hexchat"
                     "gparted"
                     "git:credential-libsecret"
                     "git"
                     "git:send-email"
                     "font-adobe-source-code-pro"
                     "arc-theme"
                     "gnome-shell-extension-dash-to-panel"
                     "ripgrep"
                     "fd"
                     "rhythmbox"
                     "xset"
                     "rsync"
                     "xlsfonts"
                     "wget"
                     "nmap"
                     "direnv"
                     "htop"
                     "python-wrapper"
                     "xrandr"
                     "vim"
                     "flatpak"
                     "qbittorrent"
                     "papirus-icon-theme"
                     "font-gnu-unifont"
                     "mumi"
                     "curl"
                     "tmux"
                     "font-gnu-freefont"
                     "unzip"
                     "file"
                     "font-awesome"
                     "font-fira-code"
                     "font-fira-mono"
                     "font-fira-sans"
                     "font-google-roboto"
                     "gnome-shell-extension-appindicator"
                     "guile-colorized"
                     "guile-readline"
                     "sl"
                     "zip"))))
