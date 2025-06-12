;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common home fishinthecalculator home-configuration)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services backup)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services fontutils)
  #:use-module (gnu home services guix)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services sound)
  #:use-module (gnu home services ssh)
  #:use-module (gnu home services sway)
  #:use-module (gnu packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu services)
  #:use-module (gnu services backup)
  #:use-module (gnu system accounts)
  #:use-module (nongnu packages editors)
  #:use-module (nongnu packages password-utils)
  #:use-module (nongnu packages productivity)
  #:use-module (sops secrets)
  #:use-module (sops home services sops)
  #:use-module (oci services containers)
  #:use-module (oci home services containers)
  #:use-module (small-guix services git)
  #:use-module (small-guix packages compose)
  #:use-module (small-guix packages docker-credentials)
  #:use-module (small-guix packages scripts)  ;for restic-bin
  #:use-module (small-guix home services docker-cli)
  #:use-module (small-guix home services dotfiles)
  #:use-module (small-guix home services gcr)
  #:use-module (small-guix home services git)
  #:use-module (small-guix home services shells)
  #:use-module (fishinthecalculator common backup)
  #:use-module (fishinthecalculator common locales)
  #:use-module (fishinthecalculator common keys)
  #:use-module (fishinthecalculator common secrets)
  #:use-module (fishinthecalculator common users)
  #:use-module (fishinthecalculator common home fishinthecalculator packages)
  #:use-module (fishinthecalculator common home fishinthecalculator services shells)
  #:use-module (fishinthecalculator common home fishinthecalculator services doom-emacs)
  #:use-module (fishinthecalculator common home fishinthecalculator services sway)
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

(define home-paul.yaml
  (secrets-file "home-paul.yaml"))

(define-public backup-home-jobs
  (map (lambda (repo)
         (restic-backup-job
          (name (string-append "home-" (list-ref (string-split repo #\:) 1)))
          (restic restic-bin)
          (repository repo)
          (password-file "/run/secrets/restic")
          ;; Every day at 21.
          (schedule "0 21 * * *")
          (files (map (lambda (p) (string-append (user-account-home-directory paul-user) "/" p))
                      '(".cert"
                        ".config/aerc/accounts.conf"
                        ".config/libvirt/qemu"
                        ".config/rclone"
                        ".config/guix/channels.scm"
                        ".config/sops/age/keys.txt"
                        ".electrum/wallets"
                        ".guix-manifests"
                        ".gnupg"
                        ".icedove"
                        ".local/bin"
                        ".local/share/gnome-boxes/images"
                        ".local/share/JetBrains/Toolbox/.storage.json"
                        ".local/share/JetBrains/Toolbox/.securestorage"
                        ".local/share/keyrings"
                        ".mozilla"
                        ".thunderbird"
                        ".ssh"
                        "Biblioteca di calibre"
                        "Calibre Library"
                        "code"
                        "Android"
                        "AndroidStudioProjects"
                        "Documents"
                        "Downloads"
                        "Games"
                        "IdeaProjects"
                        "Music"
                        "Monero/wallets"
                        "nix-manifest.txt"
                        "Pictures"
                        "PycharmProjects"
                        "Sync"
                        "Uni")))
          (verbose? #t)))
       %restic-repositories))

(define nix-update-job
  ;; Run 'nix-update' at 23:10 every day.
  (shepherd-service (provision '(nix-update))
                    (documentation
                     (string-append "Run @command{cleanup} regularly."))
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event
                         #$(format #f "~a ~a * * *" 10 23))
                        (command
                         (list
                          (string-append #$bash-minimal "/bin/bash")
                          "-l" "-c" "nix-update"))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation
                                     (string-append "Manually trigger a @command{nix-update} run,
without waiting for the scheduled time."))
                                    (procedure #~trigger-timer))))))

(define* (cleanup-job #:key (hours 20) (minutes 30))
  ;; Run 'cleanup' at a given hour every day.
  (shepherd-service (provision '(cleanup))
                    (documentation
                     (string-append "Run @command{cleanup} regularly."))
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event
                         #$(format #f "~a ~a * * *" minutes hours))
                        (command
                         (list
                          (string-append #$fishinthecalculator-scripts "/bin/cleanup")))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation
                                     (string-append "Manually trigger a @command{cleanup} run,
without waiting for the scheduled time."))
                                    (procedure #~trigger-timer))))))

(define-public fishinthecalculator-home-environment
  (home-environment
   (packages fishinthecalculator-packages)

   (services
    (append
     (list (service home-bash-service-type fishinthecalculator-bash-configuration)
           (service home-osh-service-type fishinthecalculator-osh-configuration)
           (service home-dotfiles-service-type
                    (home-dotfiles-environment
                     (directories (list fishinthecalculator-stow-dir))))

           (service home-git-sync-service-type
                    (for-home
                     (git-sync-configuration
                      (ssh-auth-sock
                       "/run/user/${UID}/gcr/ssh"))))
           (simple-service 'sync-jobs
                           home-git-sync-service-type
                           (git-sync-extension
                            (jobs
                             (list
                              (git-sync-job
                               (name "gocix")
                               (schedule "0,15,30,45 * * * *")
                               (branch "main")
                               (source
                                (git-sync-remote
                                 (name "github")
                                 (url "git@github.com:fishinthecalculator/gocix.git")))
                               (destination
                                (git-sync-remote
                                 (name "codeberg")
                                 (url "ssh://git@codeberg.org/fishinthecalculator/gocix.git"))))
                              (git-sync-job
                               (name "guix")
                               (schedule "0 0,6,12,18 * * *")
                               (branch "master")
                               (source
                                (git-sync-remote
                                 (name "upstream")
                                 (default-branch "master")
                                 (url "https://git.guix.gnu.org/guix.git")))
                               (destination
                                (git-sync-remote
                                 (name "codeberg")
                                 (default-branch "master")
                                 (url "ssh://git@codeberg.org/fishinthecalculator/guix-mirror.git"))))))))

           (service home-dbus-service-type)
           (service home-pipewire-service-type)

           (service home-gcr-ssh-agent-service-type)

           (service home-restic-backup-service-type
                    (restic-backup-configuration
                     (jobs backup-home-jobs)))

           (service home-sway-service-type
                    fishinthecalculator-sway-configuration)

           (service home-sops-secrets-service-type
                    (home-sops-service-configuration
                     (config sops.yaml)
                     (verbose? #t)
                     (secrets
                      (list
                       (sops-secret
                        (key '("codeberg"))
                        (file home-paul.yaml)
                        (permissions #o400))))))

           (service home-oci-service-type
                    (for-home
                     (oci-configuration
                      (runtime 'podman)
                      (verbose? #t))))

           (service home-doom-emacs-service-type)

           (simple-service 'fishinthecalculator-timers
                           home-shepherd-service-type
                           (list (cleanup-job)
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
                                          (host-name "tandoor.fishinthecalculator.me")
                                          (user "paul"))
                            (openssh-host (name "frastanato")
                                          (host-name "192.168.1.80")
                                          (user "paul"))
                            (openssh-host (host-name "bonfire.municipiozero.it")
                                          (name "bonfire.municipiozero.it")
                                          (user "paul"))
                            (openssh-host (host-name "municipiozero.it")
                                          (name "municipiozero.it")
                                          (user "paul")
                                          (extra-content
                                           " LocalForward 3000 localhost:3000
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
                     (authorized-keys (list termux-ssh-key)))))
     %base-home-services))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; openSUSE Tumbleweed Thinkpad environment ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define personal-restic-backup-job
  (restic-backup-job
   (name "personal-job")
   (restic restic-bin)
   (requirement '(home-sops-secrets))
   (repository "rclone:personal-onedrive:backup/restic")
   (password-file "/run/user/1001/secrets/restic")
   ;; Every day at 10
   (schedule "0 10 * * *")
   (files '("/home/paul/code/personal"
            "/home/paul/.config/guix/channels.scm"
            "/home/paul/.guix-manifests"))
   (verbose? #t)))

(define thinkpad-paul.yaml
  (secrets-file "thinkpad-paul.yaml"))

(define* (restic-prune-job #:key (hours 16) (minutes 45))
  (shepherd-service (provision '(restic-prune-personal-job))
                    (requirement '(home-sops-secrets))
                    (documentation
                     (string-append "Run @command{restic prune} on personal-job repo."))
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event #$(format #f "~a ~a * * *" minutes hours))
                        (command
                         (list
                          (string-append #+bash-minimal "/bin/bash")
                          "-l" "-c"
                          (string-append
                           "restic-guix prune " #$(restic-backup-job-name personal-restic-backup-job))))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation
                                     (string-append "Manually trigger a @command{restic prune} on personal-job repo,
without waiting for the scheduled time."))
                                    (procedure #~trigger-timer))))))

(define-public thinkpad-paul-home-environment
  (home-environment
   ;; Below is the list of packages that will show up in your
   ;; Home profile, under ~/.guix-home/profile.
   (packages (append (list anytype
                           bitwarden-desktop
                           common-glibc-locales
                           fishinthecalculator-scripts
                           guix-dev-tools
                           vscodium)
                     (specifications->packages (list "guile-readline"
                                                     "guile-colorized"
                                                     "texinfo"
                                                     "man-db"
                                                     "guile"
                                                     "nss-certs"))))

   ;; Below is the list of Home services.  To search for available
   ;; services, run 'guix home search KEYWORD' in a terminal.
   (services
    (list (simple-service 'paul-shell-profile
                          home-shell-profile-service-type
                          fishinthecalculator-shell-profile-extensions)

          (service home-bash-service-type
                   (home-bash-configuration
                    (inherit fishinthecalculator-bash-configuration)
                    (aliases
                     '(("+" . "pushd .")
                       ("-- -" . "popd")
                       (".." . "cd ..")
                       ("..." . "cd ../..")
                       ("beep" . "echo -en \"\\007\"")
                       ("cd.." . "cd ..")
                       ("dir" . "ls -l")
                       ("egrep" . "egrep --color=auto")
                       ("fgrep" . "fgrep --color=auto")
                       ("grep" . "grep --color=auto")
                       ("ip" . "ip --color=auto")
                       ("l" . "ls -alF")
                       ("la" . "ls -la")
                       ("ll" . "ls -l")
                       ("ls" . "_ls")
                       ("ls-l" . "ls -l")
                       ("md" . "mkdir -p")
                       ("o" . "less")
                       ("rd" . "rmdir")
                       ("rehash" . "hash -r")
                       ("unmount" . "echo \"Error: Try the command: umount\" 1>&2; false")
                       ("you" . "if test \"$EUID\" = 0 ; then /sbin/yast2 online_update ; else su - -c \"/sbin/yast2 online_update\" ; fi")))))

          (service home-dotfiles-service-type
                   (home-dotfiles-environment
                    (directories (list fishinthecalculator-stow-dir))))

          (service home-sops-secrets-service-type
                   (home-sops-service-configuration
                    (config sops.yaml)
                    (gnupg "/usr/bin/gpg")
                    (gnupg-home "/home/paul/.gnupg")
                    (verbose? #t)
                    (secrets
                     (list
                      (sops-secret
                       (key '("restic"))
                       (file thinkpad-paul.yaml)
                       (permissions #o400))))))

          (service home-restic-backup-service-type
                   (restic-backup-configuration
                    (jobs
                     (list
                      personal-restic-backup-job))))

          (simple-service 'additional-fonts-service
                          home-fontconfig-service-type
                          (list "~/.guix-extra-profiles/emacs/share/fonts"))

          (simple-service 'paul-timers
                          home-shepherd-service-type
                          (list (cleanup-job)
                                (restic-prune-job)))

          (simple-service 'paul-environment-variables
                          home-environment-variables-service-type
                          (append (filter
                                   (lambda (pair)
                                     (not (equal? (car pair) "PATH")))
                                   fishinthecalculator-environment)
                                  '(("SSL_CERT_DIR" . "${HOME}/.guix-home/profile/etc/ssl/certs")
                                    ("SSL_CERT_FILE" . "${HOME}/.guix-home/profile/etc/ssl/certs/ca-certificates.crt")
                                    ("CURL_CA_BUNDLE" . "${HOME}/.guix-home/profile/etc/ssl/certs/ca-certificates.crt")
                                    ("GIT_SSL_CAINFO" . "$SSL_CERT_FILE")
                                    ("GUIX_CHECKOUT" . "${HOME}/code/guix/guix")
                                    ("GUIX_LOCPATH" . "${HOME}/.guix-home/profile/lib/locale")
                                    ("HOME_RECONFIGURE_EXPRESSION" . "(@ (fishinthecalculator common home fishinthecalculator home-configuration) thinkpad-paul-home-environment)")
                                    ("PATH" . "${HOME}/.doom.d/bin:${HOME}/.config/emacs/bin:${HOME}/.emacs.d/bin:${HOME}/.local/bin:${PATH}"))))))))
