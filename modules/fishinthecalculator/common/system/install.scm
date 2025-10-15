;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image -L `pwd`/modules --image-type=iso9660 modules/fishinthecalculator/common/system/install.scm

(define-module (fishinthecalculator common system install)
  #:use-module (gnu packages package-management) ;for guix-for-channels
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu system)
  #:use-module (nongnu system install)
  #:use-module (fishinthecalculator common channels)
  #:use-module (fishinthecalculator common services substitute)
  #:export (installation-os-deployments))

(define installation-os-deployments
  (operating-system
    (inherit installation-os-nonfree)
    (services
     (modify-services (operating-system-user-services installation-os-nonfree)
       (guix-service-type
        config => (guix-configuration (inherit config)
                                      (guix (guix-for-channels %deployments-channels))
                                      (channels %deployments-channels)
                                      (substitute-urls
                                       %common-substitute-urls)
                                      (authorized-keys
                                       %common-authorized-keys)))))))

installation-os-deployments
