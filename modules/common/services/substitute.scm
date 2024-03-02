;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (common services substitute)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (common keys)
  #:export (%common-substitute-urls
            %common-authorized-keys))

(define %common-substitute-urls
  (append %default-substitute-urls
          (list "https://substitutes.nonguix.org"
                "https://guix.bordeaux.inria.fr")))

(define %common-authorized-keys
  (append %default-authorized-guix-keys
          (list substitutes.nonguix.org.pub
                guix.bordeaux.inria.fr.pub)))
