;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023 Giacomo Leidi <goodoldpaul@autistici.org>

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image nellone/system/install.scm

(define-module (nellone system install)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages zile)
  #:use-module (gnu system)
  #:use-module (gnu system install)
  #:use-module (nongnu packages linux)
  #:export (nellone-installation-os))

(define nellone-installation-os
  (operating-system
    (inherit installation-os)
    (kernel linux)
    (firmware (list linux-firmware))
    (packages
      (append
        (list curl
              git
              neovim
              zile)
        (operating-system-packages installation-os)))))

nellone-installation-os
