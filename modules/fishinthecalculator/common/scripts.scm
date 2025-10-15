;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2023-2024 Giacomo Leidi <therewasa@fishinthecalculator.me>

(define-module (fishinthecalculator common scripts)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (small-guix utils)
  #:use-module (fishinthecalculator common self))

(define-public common-deploy-scripts
  (make-scripts-package "common-deploy-scripts"
                        %common-scripts-dir
                        (list bash-minimal coreutils)
                        "A set of deploy scripts"
                        "This package provides some utility scripts mostly for deploying Guix systems."
                        "https://codeberg.org/fishinthecalculator/guix-deployments"
                        license:gpl3+
                        #:version "0.1.2"))
