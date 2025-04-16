;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2022-2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common services desktop)
  #:use-module (gnu)
  #:use-module (gnu packages admin) ;for solaar-udev-rules
  #:use-module (gnu packages android) ;for android-udev-rules
  #:use-module (gnu packages cups) ;for cups-filters
  #:use-module (gnu packages gnome) ;for network-manager-openvpn
  #:use-module (gnu packages hardware) ;for ddcutil, brillo
  #:use-module (gnu packages libusb) ;for libmtp
  #:use-module (gnu packages printers) ;for brlaser
  #:use-module (gnu packages vpn) ;for wireguard
  #:use-module (gnu system)
  #:use-module (gnu system accounts)
  #:use-module (gnu services admin)
  #:use-module (gnu services containers)
  #:use-module (gnu services cups)
  #:use-module (gnu services desktop)
  #:use-module (gnu services linux)
  #:use-module (gnu services nix)
  #:use-module (gnu services networking)
  #:use-module (gnu services security-token) ;for pcsd-service-type
  #:use-module (gnu services sddm)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services spice) ;for spice-vdagent-service
  #:use-module (gnu services virtualization)
  #:use-module (small-guix packages moolticute) ;for mooltipass-udev-rules
  #:use-module (small-guix packages solo) ;for solo2
  #:use-module (fishinthecalculator common channels)
  #:use-module (fishinthecalculator common services substitute)
  #:use-module (fishinthecalculator common services timers)
  #:use-module (fishinthecalculator common system input)
  #:use-module (srfi srfi-1)
  #:export (common-desktop-services))

(define (common-desktop-services subuids subgids)
  (append (list (service gnome-desktop-service-type)
                (service gnome-keyring-service-type)

                (simple-service 'common-timers
                                shepherd-root-service-type
                                (list updatedb-job))

                (service nix-service-type)

                ;; rootless podman
                (service iptables-service-type
                         (iptables-configuration))
                (service rootless-podman-service-type
                         (rootless-podman-configuration
                          (subgids subgids)
                          (subuids subuids)))

                ;; Apple keyboards
                (simple-service 'hid-apple-config etc-service-type
                                (list `("modprobe.d/hid_apple.conf"
                                        ,common-hid-apple-config)))

                ;; CUPS
                (service cups-service-type
                         (cups-configuration (web-interface? #t)
                                             (extensions (list cups-filters
                                                               brlaser))))

                ;; Smart Card daemon
                (service pcscd-service-type)

                ;; HDMI displays brightness control rules
                (udev-rules-service 'ddcutil ddcutil)
                (udev-rules-service 'brillo brillo)

                ;; Solo keys rules
                ;; (udev-rules-service 'solo-keys solo2)

                ;; Mooltipass devices rules
                (udev-rules-service 'mooltipass mooltipass-udev-rules)

                ;; MTP service rules
                (udev-rules-service 'mtp libmtp)

                ;; Solaar rules (Logitech Mouse)
                (udev-rules-service 'solaar solaar
                                    #:groups '("plugdev"))

                ;; ADB udev rules
                (udev-rules-service 'android android-udev-rules
                                    #:groups '("adbusers"))

                (service libvirt-service-type
                         (libvirt-configuration (unix-sock-group "libvirt")
                                                (listen-tls? #f)))

                ;; Slight FHS compatibility
                (extra-special-file "/usr/bin/env"
                                    (file-append coreutils "/bin/env")))

          (modify-services %desktop-services
            ;; Enable additional substitute servers.
            (guix-service-type config =>
                               (guix-configuration (inherit config)
                                                   (channels %deployments-channels)
                                                   (substitute-urls
                                                    %common-substitute-urls)
                                                   (authorized-keys
                                                    %common-authorized-keys))))))
