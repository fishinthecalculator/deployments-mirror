;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common home fishinthecalculator home-configuration)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services fontutils)
  #:use-module (gnu home services guix)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services shepherd)
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
  ;; Run 'guix-fork-sync' at a given hour every day.
  (shepherd-service (provision '(guix-fork-sync))
                    (documentation
                     (string-append "Run @command{guix-fork-sync} regularly."))
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event
                         "0 */6 * * *")
                        (command
                         (list
                          (string-append #$bash-minimal "/bin/bash")
                          "-l" #$guix-fork-sync-script))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation
                                     (string-append "Manually trigger a @command{guix-fork-sync} run,
without waiting for the scheduled time."))
                                    (procedure #~trigger-timer))))))

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

          (simple-service 'fishinthecalculator-timers
                          home-shepherd-service-type
                          (list))

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

;; (define here
;;   (current-source-directory))

;; (define-public %scripts-dir
;;   (local-file (string-append here "/bin") "scripts-dir"
;;               #:recursive? #t))

;; (define paul-stow-dir
;;   (string-append here
;;                  "/etc"))

;; (define paul-bash-functions
;;   (local-file
;;    (string-append here
;;                   "/bash_functions")))

;; (define suse-rclone-path
;;  "rclone:suse-google:backup")

;; (define suse-restic-backup-job-name
;;   "suse")

;; (define suse-restic-backup-job
;;   (restic-backup-job
;;    (name suse-restic-backup-job-name)
;;    (restic restic-bin)
;;    (repository (string-append suse-rclone-path "/restic-repo"))
;;    (password-file "/run/user/1000/secrets/suse/restic")
;;    ;; Every day at 15
;;    (schedule "0 15 * * *")
;;    (files (map (lambda (f) (string-append "/home/paul/" f))
;;                '(".kube"
;;                  ".thunderbird"
;;                  ".ssh"
;;                  ".gnupg"
;;                  "code"
;;                  "guix-home"
;;                  ".guix-active-profiles"
;;                  ".config/filezilla"
;;                  ".config/tea/config.yml"
;;                  ".config/gspread/authorized_user.json"
;;                  ".config/gspread/credentials.json"
;;                  ".config/osc"
;;                  ".config/rclone"
;;                  "playground"
;;                  "suse-beta-program"
;;                  "NOTE"
;;                  "Documents"
;;                  "Documenti"
;;                  "Work.kdbx")))
;;    (verbose? #t)))

;; (define sops.yaml
;;   (local-file (string-append here "/.sops.yaml")
;;               ;; This is because paths on the store
;;               ;; can not start with dots.
;;               "sops.yaml"))

;; (define paul.yaml
;;   (local-file (string-append here "/secrets/paul.yaml")))

;; ;; (define-public paul-scripts
;; ;;   (make-scripts-package "paul-scripts"
;; ;;                         %scripts-dir
;; ;;                         (list bash-minimal coreutils python)
;; ;;                         "A set of utility scripts"
;; ;;                         "This package provides some utility scripts."
;; ;;                         "https://gitlab.suse.de/gleidi/guix-home"
;; ;;                         gpl3+
;; ;;                         #:propagated-inputs (list)
;; ;;                         #:commit (read-line (open-input-pipe
;; ;;                                              "git show HEAD | head -1 | cut -d ' ' -f 2"))))

;; (define* (cleanup-job #:key (hours 16) (minutes 30))
;;  ;; Run 'cleanup' at a given hour every day.
;;  #~(job #$(format #f "~a ~a * * *" minutes hours)
;;         (string-append #$fishinthecalculator-scripts "/bin/cleanup")
;;         "cleanup"))

;; (define* (rclone-keepass-job #:key (hours 14) (minutes 55))
;;  #~(job #$(format #f "~a ~a * * *" minutes hours)
;;         (lambda _
;;           (system* "rclone" "copy" "Work.kdbx" #$suse-rclone-path))
;;         "rclone-keepass"))

;; (define* (restic-prune-job #:key (hours 16) (minutes 45))
;;  #~(job #$(format #f "~a ~a * * *" minutes hours)
;;         (lambda _
;;           (system* "restic-guix" "prune" #$suse-restic-backup-job-name))
;;         "prune"))

;; (home-environment
;;  ;; Below is the list of packages that will show up in your
;;  ;; Home profile, under ~/.guix-home/profile.
;;  (packages (append (list anytype
;;                          bitwarden-desktop
;;                          common-glibc-locales
;;                          fishinthecalculator-scripts
;;                          ;paul-scripts
;;                          guix-dev-tools
;;                          abra
;;                          ;suse-certs
;;                          vscodium)
;;                    (specifications->packages (list "guile-readline"
;;                                                    "guile-colorized"
;;                                                    "texinfo"
;;                                                    "man-db"
;;                                                    "guile"
;;                                                    "nss-certs"))))

;;  ;; Below is the list of Home services.  To search for available
;;  ;; services, run 'guix home search KEYWORD' in a terminal.
;;  (services
;;   (list (simple-service 'paul-shell-profile
;;                         home-shell-profile-service-type
;;                         (cons*
;;                          paul-bash-functions
;;                          fishinthecalculator-shell-profile-extensions))

;;         (service home-bash-service-type
;;                  (home-bash-configuration
;;                   (inherit fishinthecalculator-bash-configuration)
;;                   (aliases
;;                    '(("+" . "pushd .")
;;                      ("-- -" . "popd")
;;                      (".." . "cd ..")
;;                      ("..." . "cd ../..")
;;                      ("beep" . "echo -en \"\\007\"")
;;                      ("cd.." . "cd ..")
;;                      ("dir" . "ls -l")
;;                      ("egrep" . "egrep --color=auto")
;;                      ("fgrep" . "fgrep --color=auto")
;;                      ("grep" . "grep --color=auto")
;;                      ("ip" . "ip --color=auto")
;;                      ("l" . "ls -alF")
;;                      ("la" . "ls -la")
;;                      ("ll" . "ls -l")
;;                      ("ls" . "_ls")
;;                      ("ls-l" . "ls -l")
;;                      ("md" . "mkdir -p")
;;                      ("o" . "less")
;;                      ("rd" . "rmdir")
;;                      ("rehash" . "hash -r")
;;                      ("unmount" . "echo \"Error: Try the command: umount\" 1>&2; false")
;;                      ("you" . "if test \"$EUID\" = 0 ; then /sbin/yast2 online_update ; else su - -c \"/sbin/yast2 online_update\" ; fi")))))

;;         (service home-dotfiles-service-type
;;                  (home-dotfiles-configuration
;;                   (layout 'stow)
;;                   (directories
;;                    (list paul-stow-dir))))

;;         ;; (service home-sops-secrets-service-type
;;         ;;          (home-sops-service-configuration
;;         ;;           (config sops.yaml)
;;         ;;           (gnupg "/usr/bin/gpg")
;;         ;;           (gnupg-home "/home/paul/.gnupg")
;;         ;;           (verbose? #t)
;;         ;;           (secrets
;;         ;;            (list
;;         ;;             (sops-secret
;;         ;;              (key '("suse" "restic"))
;;         ;;              (file paul.yaml)
;;         ;;              (permissions #o400))
;;         ;;             (sops-secret
;;         ;;              (key '("personal" "restic"))
;;         ;;              (file paul.yaml)
;;         ;;              (permissions #o400))))))

;;         ;; (service home-restic-backup-service-type
;;         ;;          (restic-backup-configuration
;;         ;;           (jobs
;;         ;;            (list
;;         ;;             suse-restic-backup-job
;;         ;;             (restic-backup-job
;;         ;;              (name "personal")
;;         ;;              (restic restic-bin)
;;         ;;              (repository "rclone:personal-onedrive:backup/restic")
;;         ;;              (password-file "/run/user/1000/secrets/personal/restic")
;;         ;;              ;; Every day at 10
;;         ;;              (schedule "0 10 * * *")
;;         ;;              (files '("/home/paul/code/personal"))
;;         ;;              (verbose? #t))))))

;;         ;; (service home-openssh-service-type
;;         ;;          (home-openssh-configuration
;;         ;;           (hosts
;;         ;;            (list (openssh-host (name "xcdchk")
;;         ;;                                (host-name "xcdchk.suse.de")
;;         ;;                                (user "gleidi")
;;         ;;                                (identity-file "~/.ssh/id_ed25519"))
;;         ;;                  (openssh-host (host-name "bonfire.fishinthecalculator.me")
;;         ;;                                (name "bonfire.fishinthecalculator.me")
;;         ;;                                (user "paul"))
;;         ;;                  (openssh-host (name "euklid")
;;         ;;                                (host-name "euklid.suse.de")
;;         ;;                                (user "gleidi"))
;;         ;;                  (openssh-host (name "thales")
;;         ;;                                (host-name "thales.prg2.suse.org")
;;         ;;                                (user "gleidi")
;;         ;;                                (identity-file "~/.ssh/id_ed25519"))))))

;;         (simple-service 'additional-fonts-service
;;                         home-fontconfig-service-type
;;                         (list "~/.guix-extra-profiles/emacs/share/fonts"))

;;         ;; (simple-service 'paul-mcron
;;         ;;                 home-mcron-service-type
;;         ;;                 (list (cleanup-job)
;;         ;;                       (restic-prune-job)
;;         ;;                       (rclone-keepass-job)))

;;         ;; (service home-ocui-service-type
;;         ;;          (ocui-configuration
;;         ;;           (oci
;;         ;;            (ocui-oci-configuration
;;         ;;             (runtime "podman")))))

;;         (simple-service 'paul-environment-variables
;;                         home-environment-variables-service-type
;;                         (append (filter
;;                                  (lambda (pair)
;;                                    (not (equal? (car pair) "PATH")))
;;                                  fishinthecalculator-environment)
;;                                 '(("SSL_CERT_DIR" . "${HOME}/.guix-home/profile/etc/ssl/certs")
;;                                   ("SSL_CERT_FILE" . "${HOME}/.guix-home/profile/etc/ssl/certs/ca-certificates.crt")
;;                                   ("CURL_CA_BUNDLE" . "${HOME}/.guix-home/profile/etc/ssl/certs/ca-certificates.crt")
;;                                   ("GIT_SSL_CAINFO" . "$SSL_CERT_FILE")
;;                                   ("GUIX_CHECKOUT" . "${HOME}/code/guix/guix")
;;                                   ("GUIX_LOCPATH" . "${HOME}/.guix-home/profile/lib/locale")
;;                                   ("PATH" . "${HOME}/.doom.d/bin:${HOME}/.config/emacs/bin:${HOME}/.emacs.d/bin:${HOME}/.local/bin:${PATH}")))))))
