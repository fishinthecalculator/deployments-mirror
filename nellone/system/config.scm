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

(define public-host
  "192.248.184.52")

(define-public nellone-system
  (guix-nas-system->operating-system
   (guix-nas-system
     (admin-email "goodoldpaul@autistici.org")
     (public-host public-host)
     (enable-https? #f)
     (host-name "virtual-nellone")
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
                                    "ba1b7761-8b81-4b71-8a1a-ebdcd0fbcdf6")))))

     ;; The list of file systems that get "mounted".  The unique
     ;; file system identifiers there ("UUIDs") can be obtained
     ;; by running 'blkid' in a terminal.
     (file-systems (cons* (file-system
                            (mount-point "/")
                            (device (uuid
                                     "f0890300-9702-428f-93ed-a7058a33b2ab"
                                     'ext4))
                            (type "ext4")) %base-file-systems)))))
