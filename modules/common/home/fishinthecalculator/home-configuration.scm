(define-module (common home fishinthecalculator home-configuration)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services fontutils)
  #:use-module (gnu home services guix)
  #:use-module (gnu home services mcron)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services ssh)
  #:use-module (gnu services)
  #:use-module (small-guix packages compose)
  #:use-module (small-guix packages docker-credentials)
  #:use-module (small-guix home services docker-cli)
  #:use-module (gnu home services dotfiles)
  #:use-module (common keys)
  #:use-module (common home fishinthecalculator packages)
  #:use-module (common home fishinthecalculator services bash)
  #:use-module (common home fishinthecalculator services doom-emacs)
  #:use-module (common home fishinthecalculator services seedvault-serve)
  #:use-module (pot-service)
  #:use-module (ice-9 format))

(define %home
  (getenv "HOME"))

(define %here
  (current-source-directory))

(define fishinthecalculator-stow-dir
  (string-append %here
                 "/etc"))

(define upall-job
  ;; Run 'upall' at 23:10 every day.
  #~(job "10 23 * * *"
         (string-append #$fishinthecalculator-scripts "/bin/upall")
         "upall"))

(define* (cleanup-job #:key (hours 23) (minutes 0))
 ;; Run 'cleanup' at a given hour every day.
 #~(job #$(format #f "~a ~a * * *" minutes hours)
        (string-append #$fishinthecalculator-scripts "/bin/cleanup")
        "cleanup"))

(define-public fishinthecalculator-home-environment
  (home-environment
   (packages fishinthecalculator-packages)

   (services
    (list (service home-bash-service-type fishinthecalculator-bash-configuration)
          (service home-seedvault-serve-service-type)
          (service home-dotfiles-service-type
                   (home-dotfiles-configuration
                    (layout 'stow)
                    (directories (list fishinthecalculator-stow-dir))))

          (service home-dbus-service-type)
          (service home-pipewire-service-type)
          (service home-pot-service-type
                   (pot-configuration
                    (oci
                     (pot-oci-configuration
                      (runtime "docker")))))

          (service home-doom-emacs-service-type)

          (service home-docker-cli-service-type
                   (docker-cli-configuration
                    (creds-store "secretservice")
                    (cli-plugins
                     (list docker-compose-plugin
                           docker-credential-secretservice))
                    (extra-content ", \"auths\": {\"https://index.docker.io/v1/\": {}}")))

          (simple-service 'fishinthecalculator-mcron
                          home-mcron-service-type
                          (list (cleanup-job)
                                upall-job))

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
                                    ("BONFIRE_DEV_GUIX" . "true")
                                    ("COLORTERM" . "truecolor")
                                    ("MOAR" . "--statusbar=bold --no-linenumbers"))))

          (service home-openssh-service-type
                   (home-openssh-configuration
                    (hosts
                     (list (openssh-host (name "nasa")
                                         (user "root")
                                         (identity-file
                                          (string-append %home "/.ssh/id_rsa.pub"))
                                         (host-name "192.168.1.51")
                                         (host-key-algorithms
                                          '("+ssh-rsa"))
                                         (extra-content
                                          "  KexAlgorithms +diffie-hellman-group1-sha1"))
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
                                          (string-append %home "/.ssh/id_remarkable.pub"))
                                         (host-name "192.168.1.60")
                                         (host-key-algorithms
                                          '("+ssh-rsa"))
                                         (accepted-key-types
                                          '("+ssh-rsa")))))
                    (authorized-keys (list termux-ssh-key))))))))
