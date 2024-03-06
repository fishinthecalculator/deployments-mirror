(define-module (common home fishinthecalculator packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages python)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 popen)
  #:use-module (small-guix packages scripts)
  #:use-module (small-guix utils)
  #:use-module (common scripts)
  #:use-module (common home fishinthecalculator const))

(define-public fishinthecalculator-scripts
  (make-scripts-package "fishinthecalculator-scripts"
                        %home-scripts-dir
                        (list bash-minimal coreutils python)
                        "A set of utility scripts"
                        "This package provides some utility scripts."
                        "https://gitlab.com/orang3/guix-home"
                        license:gpl3+
                        #:propagated-inputs (list common-deploy-scripts)
                        #:commit (read-line (open-input-pipe
                                             "git show HEAD | head -1 | cut -d ' ' -f 2"))))

(define-public fishinthecalculator-packages
  (append (list guile-3.0 fishinthecalculator-scripts guix-dev-tools)
          (map specification->package+output
               (list "anytype"
                     "common-deploy-scripts"
                     "calibre"
                     "dino"
                     "aerc"
                     "w3m"
                     "dante"
                     "moar"
                     "lolcat"
                     "bat"
                     "catimg"
                     "libnotify"
                     "vlc"
                     "telegram-desktop"
                     "element-desktop"
                     "foot"
                     "imagemagick"
                     "hexchat"
                     "google-chrome-stable"
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
                     "curl"
                     "guile-hall.git"
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
                     "unrar"
                     "vscodium"
                     "guile-lsp-server.git"
                     "zip"
                     "zoom"))))
