;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common services server)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu services admin)
  #:use-module (gnu services avahi)
  #:use-module (gnu services containers)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop) ;for elogind-service
  #:use-module (gnu services networking)
  #:use-module (gnu services security)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services ssh)
  #:use-module (guix gexp)
  #:use-module (small-guix packages btdu) ;for btdu
  #:use-module (fishinthecalculator common scripts)
  #:use-module (fishinthecalculator common services base)
  #:use-module (fishinthecalculator common services firewall)
  #:use-module (fishinthecalculator common services timers)
  #:export (common-server-services))

(define gc-job
  ;; Run 'guix gc' at 4AM on Monday.
  (shepherd-service (provision '(guix-gc-timer))
                    (requirement '(user-processes file-systems guix-daemon))
                    (documentation
                     "Run @command{guix gc} on a regular basis.")
                    (modules '((shepherd service timer)))
                    (start
                     #~(make-timer-constructor
                        (cron-string->calendar-event "0 4 * * 1")
                        (command
                         (list
                          "/run/current-system/profile/bin/guix" "gc"))))
                    (stop
                     #~(make-timer-destructor))
                    (actions (list (shepherd-action
                                    (name 'trigger)
                                    (documentation "Manually trigger a guix gc run,
without waiting for the scheduled time.")
                                    (procedure #~trigger-timer))))))

(define (common-server-services subuids subgids)
  (append %common-base-services
          (list (service dhcpd-service-type)
                (service ntp-service-type)
                (service openssh-service-type
                         (openssh-configuration
                          (permit-root-login #f)
                          (password-authentication? #f)
                          (x11-forwarding? #f)))

                (service iptables-service-type
                         %common-iptables-configuration)

                (service fail2ban-service-type
                         (fail2ban-configuration
                          (extra-jails
                           (list
                            (fail2ban-jail-configuration
                             (name "sshd")
                             (enabled? #t))))))

                ;; Preinstalled packages
                (simple-service 'preinstalled-server-packages
                                profile-service-type
                                (append (map specification->package+output
                                             '("ncurses" ;for the search path

                                               ;; Standard FreeDesktop directory paths
                                               "xdg-user-dirs"
                                               "xdg-utils"
                                               ;; User mounts
                                               "gvfs"

                                               "rsync"

                                               ;;OpenGPG
                                               "gnupg"
                                               ;; Misc
                                               "lsof"
                                               "jq"
                                               "tree"
                                               "curl"
                                               "fd"
                                               "git"
                                               "htop"
                                               "ripgrep"
                                               "tmux"
                                               "vim"

                                               ;; Network administration
                                               "bind"
                                               "bind:utils"
                                               "tcpdump"

                                               "efibootmgr"

                                               "emacs"))
                                        (list common-deploy-scripts btdu)))

                (service avahi-service-type)

                (service rootless-podman-service-type
                         (rootless-podman-configuration
                          (subgids subgids)
                          (subuids subuids)))

                ;; The D-Bus clique.
                (service elogind-service-type)
                (service dbus-root-service-type)

                (simple-service 'server-timers
                                shepherd-root-service-type
                                (list gc-job
                                      updatedb-job)))))
