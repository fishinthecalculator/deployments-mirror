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
  "2001:19f0:6c01:578:5400:4ff:fe7f:ec7f")

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
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "docker"))
                   ;; Specify a SHA-512-hashed initial password.
                   (password (crypt "test" "$6$abc")))))

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
                                    "043f842a-2b1f-45a2-91ff-4b1104788622")))))

     ;; The list of file systems that get "mounted".  The unique
     ;; file system identifiers there ("UUIDs") can be obtained
     ;; by running 'blkid' in a terminal.
     (file-systems (cons* (file-system
                            (mount-point "/")
                            (device (uuid
                                     "d338670c-1a48-46fa-bf36-36bb6fa6d3f7"
                                     'ext4))
                            (type "ext4")) %base-file-systems)))))
