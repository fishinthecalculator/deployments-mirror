;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <therewasa@fishinthecalculator.me>

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image -L `pwd`/modules modules/fishinthecalculator/common/system/image.scm

(define-module (fishinthecalculator common system image)
  #:use-module (gnu)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (fishinthecalculator common system install)
  #:export (installation-os-deployments-image))

(define installation-os-deployments-image
  (image-with-os iso9660-image
                 (operating-system (inherit installation-os-deployments)
                                   (file-systems
                                    (list (file-system
                                            (mount-point "/")
                                            (device (file-system-label "Guix_image"))
                                            (type "ext4"))
                                          (file-system
                                            (mount-point "/tmp")
                                            (device "none")
                                            (type "tmpfs")
                                            (check? #f)))))))

installation-os-deployments-image
