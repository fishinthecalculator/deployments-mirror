(define-module (nellone system config)
  #:use-module (guix utils)
  #:use-module (gnu)
  #:use-module (nas records mapper)
  #:use-module (nas records system)
  #:use-module (common users))

(define authorized-ssh-keys
  ;; List of authorized SSH keys.
  `((,paul-user ,(string-append (current-source-directory)
                                "/../../keys/ssh/id_rsa.pub"))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list (local-file "../../keys/guix/frastanato.pub")
        (local-file "../../keys/guix/prematurata.pub")))

(define-public nellone-system
  (guix-nas-system->operating-system
   (guix-nas-system
    (admin-email "goodoldpaul@autistici.org")
    (public-host "nellone.fishinthecalculator.me")
    (enable-https? #t)
    (host-name "nellone")
    ;; The list of user accounts ('root' is implicit).
    (users (list (user-account
                  (inherit paul-user)
                  (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))))

    (admin-users (list (user-account-name paul-user)))

    (guix-keys authorized-guix-keys)

    (ssh-keys authorized-ssh-keys)

    ;; Hardware dependent settings.
    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/vda"))
                 (keyboard-layout (keyboard-layout "us"))))

    (swap-devices (list (swap-space
                         (target (uuid
                                  "86021678-3700-4717-b29e-744477d0ea0c")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "c2b4a64f-8654-461b-aebd-6752eabfe7cb"
                                    'ext4))
                           (type "ext4")) %base-file-systems)))))
