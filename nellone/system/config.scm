(define-module (nellone system config)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu services monitoring)
  #:use-module (gnu services spice)
  #:use-module (gnu services ssh)
  #:use-module (gnu)
  #:use-module (gnu system) ;for %sudoers-specification
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix locales)
  #:use-module (small-guix services base)
  #:use-module (small-guix services docker)
  #:use-module (small-guix services server)
  #:use-module (nas system config)
  #:use-module (common unattended-upgrades)
  #:use-module (common users)
  #:use-module (srfi srfi-1))

(define authorized-ssh-keys
  ;; List of authorized SSH keys.
  `((,(user-account-name paul-user) ,(local-file (string-append (current-source-directory)
                                                                "/../../keys/ssh/id_rsa.pub")
                                                 (string-append (user-account-name paul-user)
                                                                ".pub")))))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list (local-file "../../keys/guix/frastanato.pub")
        (local-file "../../keys/guix/prematurata.pub")))

(define-public nellone-system
  (operating-system
    (inherit guix-nas-system)
    (kernel linux)
    ;; (initrd microcode-initrd)
    ;; (firmware (list linux-firmware))

    (host-name "virtual-nellone")

    ;; The list of user accounts ('root' is implicit).
    (users (cons* (user-account
                   (inherit paul-user)
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "docker"))
                   ;; Specify a SHA-512-hashed initial password.
                   (password (crypt "test" "$6$abc")))
                  %base-user-accounts))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                "\n" (user-account-name paul-user)
                                " ALL=(ALL) NOPASSWD: ALL\n")))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list (deployments-unattended-upgrades "nellone")
                   (service spice-vdagent-service-type))
             (modify-services (operating-system-services guix-nas-system)
              (openssh-service-type config =>
                                    (openssh-configuration (inherit config)
                                                           (authorized-keys
                                                            authorized-ssh-keys)))
              (guix-service-type config =>
                                 (guix-configuration (inherit config)
                                                     (authorized-keys
                                                      authorized-guix-keys))))))
    
    (bootloader (bootloader-configuration
                  (bootloader grub-bootloader)
                  (targets (list "/dev/vda"))
                  (keyboard-layout (operating-system-keyboard-layout guix-nas-system))))
    (swap-devices (list (swap-space
                          (target (uuid
                                   "c8499bec-6c46-412c-a555-150c3a97b0ee")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "b3535693-c9fa-4f00-93fe-3ff83c3f8598"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
