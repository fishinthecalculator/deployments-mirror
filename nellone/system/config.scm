(define-module (nellone system config)
  #:use-module (guix utils)
  #:use-module (gnu)
  #:use-module (nas records mapper)
  #:use-module (nas records system)
  #:use-module (common keys)
  #:use-module (common users))

(define authorized-ssh-keys
  ;; List of authorized SSH keys.
  `((,paul-user ,paul-ssh-key)))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list prematurata-guix-key))

(define-public nellone-system
  (guix-nas-system->operating-system
   (guix-nas-system
    (admin-email "goodoldpaul@autistici.org")
    (public-host "nellone.fishinthecalculator.me")
    (enable-https? #t)
    (host-name "virtual-nellone")
    ;; The list of user accounts ('root' is implicit).
    (users (list (user-account
                  (inherit paul-user)
                  (comment "Tino il Cotechino")
                  (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))))

    (deploy-users (list paul-ssh-key))

    (guix-keys authorized-guix-keys)

    (ssh-keys authorized-ssh-keys)

    ;; Hardware dependent settings.
    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/vda"))
                 (keyboard-layout (keyboard-layout "us"))))

    (mapped-devices (list (mapped-device
                           (source (uuid
                                    "73e13cd8-1f4e-472c-bb8b-ceb94a6ff8d4"))
                           (target "cryptroot")
                           (type luks-device-mapping))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/mapper/cryptroot")
                           (type "ext4")
                           (dependencies mapped-devices)) %base-file-systems)))))
