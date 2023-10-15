(define-module (tarapia system libre))
(use-modules (gnu) (gnu bootloader u-boot)  (gnu system images pinebook-pro) (srfi srfi-1))

(operating-system
  (inherit pinebook-pro-barebones-os)
  (file-systems
   (cons* (file-system
            (device (file-system-label "Guix_image"))
            (mount-point "/")
            (type "btrfs")
            (options "compress=zstd,discard,space_cache=v2"))
          (file-system
            (mount-point "/boot/efi")
            (device (file-system-label "GNU-ESP"))
            (type "vfat"))
          %base-file-systems))
  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-removable-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout (operating-system-keyboard-layout pinebook-pro-barebones-os)))))
