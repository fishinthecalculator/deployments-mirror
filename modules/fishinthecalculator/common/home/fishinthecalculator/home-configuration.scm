(define-module (fishinthecalculator common home fishinthecalculator home-configuration)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services fontutils)
  #:use-module (gnu home services guix)
  #:use-module (gnu home services mcron)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services ssh)
  #:use-module (gnu packages bash)
  #:use-module (gnu services)
  #:use-module (small-guix packages compose)
  #:use-module (small-guix packages docker-credentials)
  #:use-module (small-guix home services docker-cli)
  #:use-module (small-guix home services dotfiles)
  #:use-module (small-guix home services shells)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common home fishinthecalculator packages)
  #:use-module (fishinthecalculator common home fishinthecalculator services shells)
  #:use-module (fishinthecalculator common home fishinthecalculator services doom-emacs)
  #:use-module (ocui-service)
  #:use-module (ice-9 format))

(define %home
  "/")

(define %here
  (current-source-directory))

(define fishinthecalculator-stow-dir
  (stow-dotfiles-directory
   (name
    (string-append %here
                   "/etc"))))

(define nix-update-job
  ;; Run 'upall' at 23:10 every day.
  #~(job "10 23 * * *"
         (string-append #$bash-minimal "/bin/bash -l -c 'nix-update'")
         "nix-update"))

(define* (cleanup-job #:key (hours 20) (minutes 30))
 ;; Run 'cleanup' at a given hour every day.
 #~(job #$(format #f "~a ~a * * *" minutes hours)
        (string-append #$fishinthecalculator-scripts "/bin/cleanup")
        "cleanup"))

(define guix-fork-sync-script
  (plain-file
   "guix-fork-sync-script"
   "set -e

if [ -z \"${XDG_CACHE_HOME}\" ]; then
   CACHE=\"${HOME}/.cache\"
else
   CACHE=\"${XDG_CACHE_HOME}\"
fi

REPO_HOME=\"${CACHE}/guix-mirror-sync\"

set -u

export SSH_AUTH_SOCK=\"/run/user/${UID}/keyring/ssh\"

if ! [ -d \"${REPO_HOME}/.git\" ]; then
    rm -rfv \"${REPO_HOME}\"
    git clone https://git.savannah.gnu.org/git/guix.git --branch master --single-branch \"${REPO_HOME}\"
    cd \"${REPO_HOME}\"
    git remote add github git@github.com:fishinthecalculator/guix-fork.git
fi

cd \"${REPO_HOME}\"
git checkout -- .
git checkout master
git pull
git push github master"))

(define guix-fork-sync-job
  ;; Run 'cleanup' at a given hour every day.
  #~(job "0 */6 * * *"
         (string-append #$bash-minimal "/bin/bash -l "
                        #$guix-fork-sync-script)))

(define-public fishinthecalculator-home-environment
  (home-environment
   (packages fishinthecalculator-packages)

   (services
    (list (service home-bash-service-type fishinthecalculator-bash-configuration)
          (service home-osh-service-type fishinthecalculator-osh-configuration)
          (service home-dotfiles-service-type
                   (home-dotfiles-environment
                    (directories (list fishinthecalculator-stow-dir))))

          (service home-dbus-service-type)
          (service home-pipewire-service-type)
          (service home-ocui-service-type
                   (ocui-configuration
                    (oci
                     (ocui-oci-configuration
                      (runtime "podman")))))

          (service home-doom-emacs-service-type)

          (simple-service 'fishinthecalculator-mcron
                          home-mcron-service-type
                          (list (cleanup-job)
                                guix-fork-sync-job
                                nix-update-job))

          (simple-service 'fishinthecalculator-fonts
                          home-fontconfig-service-type
                          (list (string-append %home "/.nix-profile/share/fonts")))

          (simple-service 'fishinthecalculator-shell-profile
                          home-shell-profile-service-type
                          fishinthecalculator-shell-profile-extensions)

          (simple-service 'fishinthecalculator-env-vars
                          home-environment-variables-service-type
                          (append (filter
                                   (lambda (pair)
                                     (not (equal? (car pair) "PATH")))
                                   fishinthecalculator-environment)
                                  '(("GUIX_CHECKOUT" . "${HOME}/code/guix/guix")
                                    ("HOME_RECONFIGURE_EXPRESSION" . "(@ (fishinthecalculator common home fishinthecalculator home-configuration) fishinthecalculator-home-environment)")
                                    ("BONFIRE_DEV_GUIX" . "true")
                                    ("COLORTERM" . "truecolor")
                                    ("MOAR" . "--statusbar=bold --no-linenumbers"))))

          (service home-openssh-service-type
                   (home-openssh-configuration
                    (hosts
                     (list (openssh-host (name "nasa")
                                         (user "root")
                                         (identity-file
                                          "~/.ssh/id_rsa.pub")
                                         (host-name "192.168.1.51")
                                         (host-key-algorithms
                                          '("+ssh-rsa"))
                                         (extra-content
                                          "  KexAlgorithms +diffie-hellman-group1-sha1"))
                           (openssh-host (name "virtual-nellone")
                                         (host-name "2001:19f0:6c00:1e5b:5400:04ff:fee6:4e4e")
                                         (user "paul")
                                         (extra-content
                                          "  LocalForward 5432 localhost:5432"))
                           (openssh-host (name "ug")
                                         (host-name "y.ultima-generazione.com")
                                         (user "amministrataru"))
                           (openssh-host (name "frastanato")
                                         (host-name "192.168.1.80")
                                         (user "paul"))
                           (openssh-host (host-name "municipiozero.it")
                                         (name "municipiozero.it")
                                         (user "paul")
                                         (extra-content
                                          "  LocalForward 3000 localhost:3000
  LocalForward 9090 localhost:9090"))
                           (openssh-host (name "remarkable")
                                         (user "root")
                                         (identity-file
                                          "~/.ssh/id_rsa_remarkable.pub")
                                         (host-name "192.168.1.60")
                                         (host-key-algorithms
                                          '("+ssh-rsa"))
                                         (accepted-key-types
                                          '("+ssh-rsa")))))
                    (authorized-keys (list termux-ssh-key))))))))
