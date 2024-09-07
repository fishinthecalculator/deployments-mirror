;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (frastanato system image)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (guix gexp)
;  #:use-module (guix monads)
;  #:use-module (guix store)
  #:use-module (guix profiles)
  #:use-module (common system install)
  #:use-module (frastanato system config)
  #:use-module (prematurata system config)
  #:use-module (ice-9 match)
  #:export (frastanato-tarball))


;; (define* (lower-operating-system os
;;                                  #:key (image-type
;;                                         iso9660-image-type)
;;                                        (target
;;                                         (%current-target-system))
;;                                        (system
;;                                         (%current-system)))
;;   (with-store store
;;     (run-with-store store
;;       (mlet* %store-monad
;;           ((image
;;             (lower-object
;;              (system-image (os->image os #:type image-type))
;;              system
;;              #:target image)))
;;         (return tarball))
;;       #:target target
;;       #:system system)))

;; (define frastanato-tarball
;;   (lower-operating-system
;;    frastanato-system
;;    #:key docker-image-type))

(define (operating-system-directory name os)
  (computed-file name
                 (with-imported-modules '((guix build utils))
                   #~(begin
                       (use-modules (guix build utils))
                       (symlink #$os #$output)))))

(define os->manifest-entry
  (match-lambda
    ((name os)
     (manifest-entry
       (name name)
       (version "0")
       (item (operating-system-directory name os))))))

(manifest (map os->manifest-entry
               `(("frastanato-system" ,frastanato-system)
                 ("prematurata-system" ,prematurata-system))))
