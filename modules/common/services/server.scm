;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common services server)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu services admin)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop) ;for elogind-service
  #:use-module (gnu services docker)
  #:use-module (gnu services mcron)
  #:use-module (gnu services networking)
  #:use-module (gnu services security)
  #:use-module (gnu services ssh)
  #:use-module (guix gexp)
  #:use-module (common services base)
  #:use-module (common services firewall)
  #:use-module (common services mcron)
  #:export (%common-server-services))

(define gc-job
  ;; Run 'guix gc' at 1AM every day.
  #~(job '(next-hour '(1)) "guix gc"))

(define %common-server-services
  (append %common-base-services
          (list (service dhcp-client-service-type)
                (service ntp-service-type)
                (service openssh-service-type
                         (openssh-configuration
                          (password-authentication? #f)
                          (x11-forwarding? #f)))

                ;; (service iptables-service-type
                ;;          %common-iptables-configuration)

                (service fail2ban-service-type
                         (fail2ban-configuration
                          (extra-jails
                           (list
                            (fail2ban-jail-configuration
                             (name "sshd")
                             (enabled? #t))))))

                ;; Dockerd
                (service docker-service-type)

                ;; The D-Bus clique.
                (service elogind-service-type)
                (service dbus-root-service-type)

                (simple-service 'server-cron-job
                                mcron-service-type
                                (list gc-job
                                      updatedb-job)))))
