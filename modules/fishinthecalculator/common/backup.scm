;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2025 Giacomo Leidi <goodoldpaul@autistici.org>

(define-module (fishinthecalculator common backup))

(define-public %restic-repositories
  '("rclone:onedrive:backup/restic"
    "rclone:nasa-ftp:backup/restic"))
