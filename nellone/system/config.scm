(define-module (nellone system config)
  #:use-module (guix packages)
  #:use-module (gnu services monitoring)
  #:use-module (gnu services spice)
  #:use-module (gnu)
  #:use-module (gnu system) ;for %sudoers-specification
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (small-guix locales)
  #:use-module (small-guix services base)
  #:use-module (small-guix services docker)
  #:use-module (small-guix services server)
  #:use-module (nas services grafana)
  #:use-module (nas services prometheus)
  #:use-module (common unattended-upgrades)
  #:use-module (common users)
  #:use-module (srfi srfi-1))

(define authorized-guix-keys
  ;; List of authorized 'guix archive' keys.
  (list (local-file "../../keys/guix/frastanato.pub")
        (local-file "../../keys/guix/prematurata.pub")))

(define-public nellone-system
  (operating-system
    (kernel linux)
    ;; (initrd microcode-initrd)
    ;; (firmware (list linux-firmware))
    (locale "en_US.utf8")
    (timezone "Europe/Rome")
    (keyboard-layout (keyboard-layout "en_US"))

    (host-name "virtual-nellone")

    ;; The list of user accounts ('root' is implicit).
    (users (cons* (user-account
                   (inherit paul-user)
                   (supplementary-groups '("wheel" "netdev" "audio" "video" "docker"))
                   ;; Specify a SHA-512-hashed initial password.
                   (password (crypt "test" "$6$abc")))
                  %base-user-accounts))

    (packages (append (list small-guix-glibc-locales)
                      (map specification->package
                           '("curl"
                             "fd"
                             "git"
                             "jq"
                             "htop"
                             "ncdu"
                             "nss-certs"
                             "ripgrep"
                             "stow"
                             "tmux"
                             "vim")) %base-packages))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                "\n" (user-account-name paul-user)
                                " ALL=(ALL) NOPASSWD: ALL\n")))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list (deployments-unattended-upgrades host-name)
                   (service spice-vdagent-service-type)

                   (service nas-grafana-service-type)
                   (service nas-prometheus-service-type)
                   (service prometheus-node-exporter-service-type))
             (modify-services %small-guix-server-services
              (guix-service-type config =>
                                 (guix-configuration (inherit config)
                                                     (authorized-keys
                                                      authorized-guix-keys))))))
    
    (bootloader (bootloader-configuration
                  (bootloader grub-bootloader)
                  (targets (list "/dev/vda"))
                  (keyboard-layout keyboard-layout)))
    (swap-devices (list (swap-space
                          (target (uuid
                                   "c2917e2f-a138-4fc7-9d8f-a6bb9936218c")))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "0c6e6cce-840f-400d-800a-bbc1ee8fbf5d"
                                    'ext4))
                           (type "ext4")) %base-file-systems))))
