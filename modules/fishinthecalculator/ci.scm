;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator ci)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (guix gexp)
  #:use-module (guix profiles)
  #:use-module (fishinthecalculator frastanato system config)
  #:use-module (fishinthecalculator prematurata system config)
  #:use-module (ice-9 match)
  #:export (fishinthecalculator-oses))

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

(define fishinthecalculator-oses
  (manifest (map os->manifest-entry
                 `(("frastanato-system" ,frastanato-system)
                   ("prematurata-system" ,prematurata-system)))))

fishinthecalculator-oses
