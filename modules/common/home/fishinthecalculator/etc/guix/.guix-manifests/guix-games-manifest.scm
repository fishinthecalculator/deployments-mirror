(define-module (guix-games-manifest)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (gnu packages)
  #:use-module (gnu packages emulators))

(define-public retroarch-clean
  (package
    (inherit retroarch)
    (name "retroarch-clean")
    (version (package-version retroarch))
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/libretro/RetroArch")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1mf511wh7kpj29vv7rgngamvmfs151n8j4dls7jbqasdj5hik3zi"))))))

(packages->manifest (append (map specification->package
                                 '("gog-a-short-hike"
                                   "glfw"
                                   "prismlauncher"

                                   "playonlinux"
                                   "icoutils"
                                   "p7zip"
                                   "xterm"
                                   "gettext"
                                   "dxvk"
                                   "steam"
                                   ;; "wine"
                                   "wine64"
                                   "winetricks"
                                   "python-protontricks"

                                   "dwarf-fortress"))
                            (list retroarch-clean)))
